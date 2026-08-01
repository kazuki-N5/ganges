class OrderItem {
  final String id;
  final String orderId;
  final String itemCode;
  final String title;
  final int price;
  final int quantity;
  final String imageUrl;
  final String itemUrl;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemCode,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.itemUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'item_code': itemCode,
      'title': title,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'item_url': itemUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? '',
      itemCode: map['item_code'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] ?? 0,
      quantity: map['quantity'] ?? 1,
      imageUrl: map['image_url'] ?? '',
      itemUrl: map['item_url'] ?? '',
    );
  }
}

class OrderModel {
  final String orderId;
  final DateTime orderedAt;
  final int totalAmount;
  final int totalSavings;
  final String status;
  final List<OrderItem> items;

  OrderModel({
    required this.orderId,
    required this.orderedAt,
    required this.totalAmount,
    required this.totalSavings,
    this.status = 'completed',
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'ordered_at': orderedAt.toIso8601String(),
      'total_amount': totalAmount,
      'total_savings': totalSavings,
      'status': status,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return OrderModel(
      orderId: map['order_id'] ?? '',
      orderedAt: DateTime.tryParse(map['ordered_at'] ?? '') ?? DateTime.now(),
      totalAmount: map['total_amount'] ?? 0,
      totalSavings: map['total_savings'] ?? 0,
      status: map['status'] ?? 'completed',
      items: items,
    );
  }
}
