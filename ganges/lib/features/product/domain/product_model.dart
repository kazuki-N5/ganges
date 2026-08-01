class Product {
  final String itemCode;
  final String title;
  final int price;
  final String imageUrl;
  final String itemUrl;
  final double reviewAverage;
  final int reviewCount;
  final String shopName;

  Product({
    required this.itemCode,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.itemUrl,
    required this.reviewAverage,
    required this.reviewCount,
    required this.shopName,
  });

  factory Product.fromRakutenJson(Map<String, dynamic> json) {
    final item = json['Item'] ?? json;
    
    // 画像URLの取得（ mediumImageUrls または smallImageUrls ）
    String imgUrl = '';
    if (item['mediumImageUrls'] != null && (item['mediumImageUrls'] as List).isNotEmpty) {
      imgUrl = item['mediumImageUrls'][0]['imageUrl'] ?? '';
    } else if (item['smallImageUrls'] != null && (item['smallImageUrls'] as List).isNotEmpty) {
      imgUrl = item['smallImageUrls'][0]['imageUrl'] ?? '';
    }

    // HTTPをHTTPSに置換 (楽天API画像プロトコル対応)
    if (imgUrl.startsWith('http://')) {
      imgUrl = imgUrl.replaceFirst('http://', 'https://');
    }

    return Product(
      itemCode: item['itemCode'] ?? '',
      title: item['itemName'] ?? '',
      price: (item['itemPrice'] is int)
          ? item['itemPrice']
          : int.tryParse(item['itemPrice']?.toString() ?? '0') ?? 0,
      imageUrl: imgUrl,
      itemUrl: item['affiliateUrl'] ?? item['itemUrl'] ?? '',
      reviewAverage: (item['reviewAverage'] is num)
          ? (item['reviewAverage'] as num).toDouble()
          : double.tryParse(item['reviewAverage']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: (item['reviewCount'] is int)
          ? item['reviewCount']
          : int.tryParse(item['reviewCount']?.toString() ?? '0') ?? 0,
      shopName: item['shopName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_code': itemCode,
      'title': title,
      'price': price,
      'image_url': imageUrl,
      'item_url': itemUrl,
      'review_average': reviewAverage,
      'review_count': reviewCount,
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      itemCode: map['item_code'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] ?? 0,
      imageUrl: map['image_url'] ?? '',
      itemUrl: map['item_url'] ?? '',
      reviewAverage: (map['review_average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['review_count'] ?? 0,
      shopName: map['shop_name'] ?? '',
    );
  }
}
