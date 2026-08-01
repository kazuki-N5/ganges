import 'delivery_hub_model.dart';

enum DeliveryStepStatus {
  ordered('1. 注文受付完了 (発送準備中)', '拠点にて商品の梱包・出荷準備中'),
  shipped('2. 出荷・発送済み', '拠点を出発し高速ルートを移動中'),
  passingDepot('3. 配送デポ通過', '地域デポ通過・配達員へバトンタッチ'),
  delivering('4. 配達中 (接近中！)', 'ご自宅周辺の道路を走行中'),
  completed('5. 配達完了！', '玄関前への置き配が完了しました');

  final String label;
  final String description;
  const DeliveryStepStatus(this.label, this.description);
}

class DeliveryItemProgress {
  final String orderId;
  final String itemCode;
  final String title;
  final String imageUrl;
  final int price;
  final int quantity;
  final DeliveryHub hub;
  final double progress; // 0.0 ~ 1.0 (発送後の進捗)
  final DateTime orderTime;
  final int dispatchDelayHours; // 発送準備にかかる時間 (1〜8時間の乱数)
  final int shippingDurationHours; // 発送から到着までにかかる想定時間 (例: 24〜48時間)
  final double dispatchRemainingSec; // 発送開始までのシミュレーション残り秒数
  final DateTime? dispatchedAt; // 発送開始された日時 (絶対時間補間アニメーション用)

  DeliveryItemProgress({
    required this.orderId,
    required this.itemCode,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.hub,
    required this.progress,
    required this.orderTime,
    required this.dispatchDelayHours,
    required this.shippingDurationHours,
    required this.dispatchRemainingSec,
    this.dispatchedAt,
  });

  /// 発送準備が完了して発送済みかどうか
  bool get isDispatched => dispatchRemainingSec <= 0;

  DeliveryStepStatus get currentStep {
    if (!isDispatched) return DeliveryStepStatus.ordered;
    if (progress >= 1.0) return DeliveryStepStatus.completed;
    if (progress >= 0.75) return DeliveryStepStatus.delivering;
    if (progress >= 0.40) return DeliveryStepStatus.passingDepot;
    return DeliveryStepStatus.shipped;
  }

  /// 残り発送開始時間テキスト (または発送後の到着予定時間テキスト)
  String get statusDetailText {
    if (!isDispatched) {
      final prepSec = dispatchRemainingSec.ceil();
      return '発送準備中（約 $dispatchDelayHours 時間後に $hub.name より発送予定 / 残り $prepSec秒）';
    }
    if (progress >= 1.0) {
      return '置き配完了（${hub.name} より発送済み）';
    }
    final remainingHours = (shippingDurationHours * (1.0 - progress)).round();
    final remainingDays = (remainingHours / 24).toStringAsFixed(1);
    return '発送済み・移動中（到着まで約 $remainingHours 時間 / 約 $remainingDays 日）';
  }

  /// 残り時間(秒) の動的計算（発送後の移動アニメーション）
  int get remainingSeconds {
    if (!isDispatched) return (dispatchRemainingSec + 90).round();
    if (progress >= 1.0) return 0;
    final remainingRatio = 1.0 - progress;
    return (remainingRatio * 90).round();
  }

  /// 残り距離(m) の動的計算
  int get remainingDistanceMeters {
    if (!isDispatched) return 250000; // 発送前は概算大距離
    if (progress >= 1.0) return 0;
    final remainingRatio = 1.0 - progress;
    return (remainingRatio * 1500).round(); // 1.5km〜0m
  }

  DeliveryItemProgress copyWith({
    double? progress,
    double? dispatchRemainingSec,
    DateTime? dispatchedAt,
  }) {
    return DeliveryItemProgress(
      orderId: orderId,
      itemCode: itemCode,
      title: title,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      hub: hub,
      progress: progress ?? this.progress,
      orderTime: orderTime,
      dispatchDelayHours: dispatchDelayHours,
      shippingDurationHours: shippingDurationHours,
      dispatchRemainingSec: dispatchRemainingSec ?? this.dispatchRemainingSec,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
    );
  }
}
