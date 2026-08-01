class UserStats {
  final int totalSavedAmount;
  final int totalOrderCount;
  final DateTime updatedAt;

  UserStats({
    required this.totalSavedAmount,
    required this.totalOrderCount,
    required this.updatedAt,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalSavedAmount: map['total_saved_amount'] ?? 0,
      totalOrderCount: map['total_order_count'] ?? 0,
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
