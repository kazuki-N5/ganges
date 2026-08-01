// 発送拠点の定義モデル
class DeliveryHub {
  final String name;       // 拠点名 (例: Amazon市川FC)
  final double latitude;   // 緯度
  final double longitude;  // 経度

  const DeliveryHub({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// 拠点決定ユーティリティ
class DeliveryHubResolver {
  // 全国の主要物流センターリスト (全国11拠点)
  static const List<DeliveryHub> _hubs = [
    DeliveryHub(name: '札幌FC (北海道)', latitude: 43.0618, longitude: 141.3545),
    DeliveryHub(name: '仙台FC (宮城)', latitude: 38.2682, longitude: 140.8694),
    DeliveryHub(name: '新潟FC (新潟)', latitude: 37.9161, longitude: 139.0364),
    DeliveryHub(name: 'Amazon市川FC (千葉)', latitude: 35.6882, longitude: 139.9238),
    DeliveryHub(name: '金沢FC (石川)', latitude: 36.5613, longitude: 136.6562),
    DeliveryHub(name: '名古屋FC (愛知)', latitude: 35.1814, longitude: 136.9064),
    DeliveryHub(name: 'Amazon大阪茨木FC (大阪)', latitude: 34.8164, longitude: 135.5684),
    DeliveryHub(name: '広島FC (広島)', latitude: 34.3853, longitude: 132.4553),
    DeliveryHub(name: '高知FC (高知)', latitude: 33.5597, longitude: 133.5311),
    DeliveryHub(name: 'Amazon鳥栖FC (佐賀)', latitude: 33.3762, longitude: 130.5098),
    DeliveryHub(name: '鹿児島FC (鹿児島)', latitude: 31.5966, longitude: 130.5571),
  ];

  /// アイテムごとに全国の多様な拠点から分散して選出する
  static DeliveryHub resolveFromItemCode(String itemCode) {
    if (itemCode.isEmpty) {
      return _hubs[3]; // デフォルト: 市川FC
    }
    // 文字列の各文字のコードを掛け合わせてより分散したインデックスを算出
    int hash = 0;
    for (int i = 0; i < itemCode.length; i++) {
      hash = (hash * 31 + itemCode.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final int index = hash % _hubs.length;
    return _hubs[index];
  }

  /// 指定インデックスから拠点を得る
  static DeliveryHub getHubByIndex(int index) {
    return _hubs[index % _hubs.length];
  }

  static const DeliveryHub homeHub = DeliveryHub(
    name: 'ご自宅 (配送先)',
    latitude: 35.6812,
    longitude: 139.7671, // 東京自宅座標
  );
}
