import 'dart:async';
import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../cart/providers/cart_provider.dart';
import '../../checkout/domain/order_model.dart';
import '../domain/delivery_hub_model.dart';
import '../domain/delivery_item_model.dart';

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, List<DeliveryItemProgress>>((ref) {
  final historyState = ref.watch(historyProvider);
  return DeliveryNotifier(historyState);
});

class DeliveryNotifier extends StateNotifier<List<DeliveryItemProgress>> {
  Timer? _timer;
  static final _random = Random();

  DeliveryNotifier(AsyncValue<List<OrderModel>> historyState) : super([]) {
    _initDeliveryItems(historyState);
    _startAnimationTimer();
  }

  void _initDeliveryItems(AsyncValue<List<OrderModel>> historyState) {
    historyState.whenData((orders) {
      if (orders.isNotEmpty) {
        // 最新の注文、または直近の注文を取得
        final latestOrder = orders.first;
        final items = <DeliveryItemProgress>[];

        final now = DateTime.now();
        final elapsedSec = now.difference(latestOrder.orderedAt).inSeconds;

        for (int i = 0; i < latestOrder.items.length; i++) {
          final item = latestOrder.items[i];
          final hub = DeliveryHubResolver.resolveFromItemCode(item.itemCode);

          // 発送準備時間: 1〜8時間の乱数
          final dispatchDelayHours = 1 + _random.nextInt(8);
          // 発送後所要時間: 24〜48時間 (1〜2日)
          final shippingDurationHours = 24 + _random.nextInt(25);

          // シミュレーション用の発送準備時間（秒）: 1時間＝約2.5秒の短縮スケール
          final totalDispatchWaitSec = dispatchDelayHours * 2.5;
          final remainingWaitSec = max(0.0, totalDispatchWaitSec - elapsedSec);

          double initialProgress = 0.0;
          DateTime? dispatchedAt;
          if (remainingWaitSec <= 0) {
            final driveSec = elapsedSec - totalDispatchWaitSec;
            initialProgress = (driveSec / 90.0).clamp(0.0, 1.0);
            dispatchedAt = now.subtract(Duration(seconds: driveSec.round()));
          }

          items.add(DeliveryItemProgress(
            orderId: latestOrder.orderId,
            itemCode: item.itemCode,
            title: item.title,
            imageUrl: item.imageUrl,
            price: item.price,
            quantity: item.quantity,
            hub: hub,
            progress: initialProgress,
            orderTime: latestOrder.orderedAt,
            dispatchDelayHours: dispatchDelayHours,
            shippingDurationHours: shippingDurationHours,
            dispatchRemainingSec: remainingWaitSec,
            dispatchedAt: dispatchedAt,
          ));
        }
        state = items;
      } else {
        // 注文履歴がない場合のデモ用疑似配送商品データ
        state = _generateDemoItems();
      }
    });
  }

  static List<DeliveryItemProgress> _generateDemoItems() {
    final now = DateTime.now();

    // デモ用: 1〜8時間の乱数を生成して割り当て
    final delay1 = 1 + _random.nextInt(8); // 例: 3時間
    final delay2 = 1 + _random.nextInt(8); // 例: 6時間
    final delay3 = 1 + _random.nextInt(8); // 例: 1時間

    return [
      DeliveryItemProgress(
        orderId: 'DEMO-001',
        itemCode: 'demo_mic_01',
        title: 'ダイナミックマイク USBコンデンサー',
        imageUrl: '',
        price: 8980,
        quantity: 1,
        hub: DeliveryHubResolver.resolveFromItemCode('demo_mic_01'),
        progress: 0.65,
        orderTime: now.subtract(const Duration(seconds: 40)),
        dispatchDelayHours: delay1,
        shippingDurationHours: 36, // 1.5日
        dispatchRemainingSec: 0.0, // すでに発送済み
        dispatchedAt: now.subtract(const Duration(seconds: 58)), // 90秒で1.0到達なので0.65進捗は58.5秒前発送
      ),
      DeliveryItemProgress(
        orderId: 'DEMO-001',
        itemCode: 'demo_earphone_02',
        title: 'ノイズキャンセリング ワイヤレスイヤホン',
        imageUrl: '',
        price: 14800,
        quantity: 1,
        hub: DeliveryHubResolver.resolveFromItemCode('demo_earphone_02'),
        progress: 0.0,
        orderTime: now.subtract(const Duration(seconds: 20)),
        dispatchDelayHours: delay2,
        shippingDurationHours: 42, // 1.75日
        dispatchRemainingSec: delay2 * 2.5, // 発送準備中カウントダウン中
      ),
      DeliveryItemProgress(
        orderId: 'DEMO-001',
        itemCode: 'demo_cat_sand_03',
        title: '天然シリカ 猫砂 5L 3袋セット',
        imageUrl: '',
        price: 2980,
        quantity: 1,
        hub: DeliveryHubResolver.resolveFromItemCode('demo_cat_sand_03'),
        progress: 0.0,
        orderTime: now.subtract(const Duration(seconds: 10)),
        dispatchDelayHours: delay3,
        shippingDurationHours: 24, // 1日
        dispatchRemainingSec: delay3 * 2.5, // 発送準備中カウントダウン中
      ),
    ];
  }

  void _startAnimationTimer() {
    _timer?.cancel();
    // 1秒 (1000ms) 周期で状態（カウントダウン・大まかな進捗）を更新
    // UI側でAnimationControllerを用いて60FPS超滑らか補間描画を行います
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isEmpty) return;

      bool anyUpdated = false;
      final now = DateTime.now();
      final updatedList = state.map((item) {
        // 発送準備中タイマーカウントダウン (1秒減算)
        if (item.dispatchRemainingSec > 0) {
          anyUpdated = true;
          final newWaitSec = max(0.0, item.dispatchRemainingSec - 1.0);
          final newlyDispatched = newWaitSec <= 0;
          return item.copyWith(
            dispatchRemainingSec: newWaitSec,
            dispatchedAt: newlyDispatched ? now : item.dispatchedAt,
          );
        }
        // 発送後の移動進捗 (90秒で1.0到達 -> 1秒あたり 1/90 ≒ 0.01111 加算)
        else if (item.progress < 1.0) {
          anyUpdated = true;
          final newProgress = (item.progress + (1.0 / 90.0)).clamp(0.0, 1.0);
          return item.copyWith(progress: newProgress);
        }
        return item;
      }).toList();

      if (anyUpdated) {
        state = updatedList;
      }
    });
  }

  /// デモ配達をリセット/再始動する
  void restartDemo() {
    state = _generateDemoItems();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
