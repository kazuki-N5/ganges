import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../checkout/domain/order_model.dart';
import '../../history/domain/user_stats_model.dart';
import '../../product/domain/product_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // カートに商品追加
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.product.itemCode == product.itemCode);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      final updatedList = [...state];
      updatedList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = updatedList;
    } else {
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      state = [...state, newItem];
    }
  }

  // 数量変更
  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == cartItemId) item.copyWith(quantity: quantity) else item
    ];
  }

  // カートから削除
  void removeFromCart(String cartItemId) {
    state = state.where((item) => item.id != cartItemId).toList();
  }

  // カートクリア
  void clearCart() {
    state = [];
  }

  // カート合計金額
  int get totalAmount {
    return state.fold(0, (sum, item) => sum + item.totalPrice);
  }
}

// 疑似購入処理と注文履歴の管理用プロバイダー
final historyProvider = StateNotifierProvider<HistoryNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  HistoryNotifier() : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final db = await AppDatabase.instance.database;
      final orderMaps = await db.query('orders', orderBy: 'ordered_at DESC');

      List<OrderModel> orders = [];
      for (var map in orderMaps) {
        final orderId = map['order_id'] as String;
        final itemMaps = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
        final items = itemMaps.map((i) => OrderItem.fromMap(i)).toList();
        orders.add(OrderModel.fromMap(map, items));
      }

      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 疑似注文の確定処理（単品購入またはカート購入）
  Future<OrderModel?> placeOrder({
    required List<CartItem> cartItems,
  }) async {
    if (cartItems.isEmpty) return null;

    final db = await AppDatabase.instance.database;
    final String orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final int total = cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    final DateTime now = DateTime.now();

    final order = OrderModel(
      orderId: orderId,
      orderedAt: now,
      totalAmount: total,
      totalSavings: total, // 疑似購入なので全額節約！
      status: 'completed',
      items: cartItems.map((c) => OrderItem(
        id: '${orderId}-${c.product.itemCode}',
        orderId: orderId,
        itemCode: c.product.itemCode,
        title: c.product.title,
        price: c.product.price,
        quantity: c.quantity,
        imageUrl: c.product.imageUrl,
      )).toList(),
    );

    await db.transaction((txn) async {
      // 1. orders に追加
      await txn.insert('orders', order.toMap());

      // 2. order_items に追加
      for (var item in order.items) {
        await txn.insert('order_items', item.toMap());
      }

      // 3. user_stats 更新
      final statsList = await txn.query('user_stats', where: 'id = ?', whereArgs: ['main_stats']);
      if (statsList.isNotEmpty) {
        final currentSaved = (statsList.first['total_saved_amount'] as int? ?? 0) + total;
        final currentCount = (statsList.first['total_order_count'] as int? ?? 0) + 1;

        await txn.update(
          'user_stats',
          {
            'total_saved_amount': currentSaved,
            'total_order_count': currentCount,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: ['main_stats'],
        );
      }
    });

    await loadHistory();
    return order;
  }
}

// 節約統計情報用プロバイダー
final statsProvider = FutureProvider<UserStats>((ref) async {
  // 履歴が更新されたら統計も自動リフレッシュ
  ref.watch(historyProvider);
  final db = await AppDatabase.instance.database;
  final maps = await db.query('user_stats', where: 'id = ?', whereArgs: ['main_stats']);
  if (maps.isNotEmpty) {
    return UserStats.fromMap(maps.first);
  }
  return UserStats(totalSavedAmount: 0, totalOrderCount: 0, updatedAt: DateTime.now());
});
