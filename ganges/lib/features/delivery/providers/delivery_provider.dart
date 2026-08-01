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
        final existingMap = {
          for (final item in state) '${item.orderId}_${item.itemCode}': item
        };

        final items = <DeliveryItemProgress>[];
        final now = DateTime.now();

        // すべての注文履歴を処理（複数の注文の荷物を同時に配達・追跡可能に）
        for (final order in orders) {
          final elapsedSec = now.difference(order.orderedAt).inSeconds;

          for (int i = 0; i < order.items.length; i++) {
            final item = order.items[i];
            final key = '${order.orderId}_${item.itemCode}';

            // すでに配信進行中の荷物は進行状況（progressやカウントダウン）を維持
            if (existingMap.containsKey(key)) {
              items.add(existingMap[key]!);
            } else {
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
                orderId: order.orderId,
                itemCode: item.itemCode,
                title: item.title,
                imageUrl: item.imageUrl,
                price: item.price,
                quantity: item.quantity,
                hub: hub,
                progress: initialProgress,
                orderTime: order.orderedAt,
                dispatchDelayHours: dispatchDelayHours,
                shippingDurationHours: shippingDurationHours,
                dispatchRemainingSec: remainingWaitSec,
                dispatchedAt: dispatchedAt,
              ));
            }
          }
        }
        state = items;
      } else {
        // 注文履歴がない場合
        state = [];
      }
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
