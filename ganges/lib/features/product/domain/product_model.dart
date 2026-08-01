class Product {
  final String itemCode;
  final String title;
  final int price;
  final String imageUrl;
  final List<String> imageUrls;
  final String itemUrl;
  final double reviewAverage;
  final int reviewCount;
  final String shopName;
  final String genreId;

  Product({
    required this.itemCode,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.itemUrl,
    required this.reviewAverage,
    required this.reviewCount,
    required this.shopName,
    this.genreId = '',
  });

  static String _upgradeImageQuality(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;
    var url = rawUrl;
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    // 低解像度パラメータ (?_ex=128x128 など) を 600x600 の高画質パラメータへ拡大置換
    if (url.contains('?_ex=')) {
      url = url.replaceAll(RegExp(r'\?_ex=\d+x\d+'), '?_ex=600x600');
    } else if (url.contains('thumbnail.image.rakuten.co.jp')) {
      url = '$url?_ex=600x600';
    }
    return url;
  }

  factory Product.fromRakutenJson(Map<String, dynamic> json) {
    final item = json['Item'] ?? json;
    
    // 画像URLのリスト取得
    List<String> urls = [];
    if (item['mediumImageUrls'] != null && (item['mediumImageUrls'] as List).isNotEmpty) {
      for (final img in item['mediumImageUrls']) {
        final u = img['imageUrl']?.toString() ?? '';
        if (u.isNotEmpty) {
          urls.add(_upgradeImageQuality(u));
        }
      }
    } else if (item['smallImageUrls'] != null && (item['smallImageUrls'] as List).isNotEmpty) {
      for (final img in item['smallImageUrls']) {
        final u = img['imageUrl']?.toString() ?? '';
        if (u.isNotEmpty) {
          urls.add(_upgradeImageQuality(u));
        }
      }
    }

    String mainImgUrl = urls.isNotEmpty
        ? urls.first
        : _upgradeImageQuality(item['imageUrl']?.toString() ?? '');

    return Product(
      itemCode: item['itemCode'] ?? '',
      title: item['itemName'] ?? '',
      price: (item['itemPrice'] is int)
          ? item['itemPrice']
          : int.tryParse(item['itemPrice']?.toString() ?? '0') ?? 0,
      imageUrl: mainImgUrl,
      imageUrls: urls.isNotEmpty ? urls : (mainImgUrl.isNotEmpty ? [mainImgUrl] : []),
      itemUrl: item['affiliateUrl'] ?? item['itemUrl'] ?? '',
      reviewAverage: (item['reviewAverage'] is num)
          ? (item['reviewAverage'] as num).toDouble()
          : double.tryParse(item['reviewAverage']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: (item['reviewCount'] is int)
          ? item['reviewCount']
          : int.tryParse(item['reviewCount']?.toString() ?? '0') ?? 0,
      shopName: item['shopName'] ?? '',
      genreId: item['genreId']?.toString() ?? '',
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
      'genre_id': genreId,
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
      genreId: map['genre_id'] ?? '',
    );
  }
}
