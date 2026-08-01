import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/product/domain/product_model.dart';

class RakutenApiClient {
  static String get _appId => dotenv.env['RAKUTEN_APP_ID'] ?? '';
  static String get _affiliateId => dotenv.env['RAKUTEN_AFFILIATE_ID'] ?? '';
  static const String _baseUrl = 'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601';


  // 開発中モックモードフラグ（本番化時は false に変更）
  static const bool useMockOnly = true;

  final Dio _dio;

  RakutenApiClient({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Product>> searchProducts({
    String keyword = 'ガジェット',
    int hits = 30,
    int page = 1,
    String? sort,
  }) async {
    // 開発期間中は常にモックデータを返却（通信エラー防止＆高速化）
    if (useMockOnly) {
      return _getMockProducts(keyword);
    }

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'applicationId': _appId,
          'affiliateId': _affiliateId,
          'format': 'json',
          'keyword': keyword.isEmpty ? 'おすすめ' : keyword,
          'hits': hits,
          'page': page,
          if (sort != null) 'sort': sort,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List items = response.data['Items'] ?? [];
        return items.map((item) => Product.fromRakutenJson(item)).toList();
      }
    } catch (e) {
      return _getMockProducts(keyword);
    }
    return [];
  }

  // 開発用モック商品群（通信不要）
  List<Product> _getMockProducts(String keyword) {
    final mockTitles = [
      'TONOR ダイナミックマイク カラオケマイク 単一指向性 ハンドヘルド',
      'JBL QUANTUM STREAM USBスタンドアロン デュアルコンデンサーマイク',
      'ゼンハイザー ダイナミックマイクロホン 高音質ボーカルモデル',
      '[MIR] マスク 3dマスク 立体マスク 50枚入り 高密度フィルター',
      'ニュールオーダー 猫砂 天然シリカ素材使用 ニオイを抑える超吸収',
      'ピュリナワン 敏感なスキンケア キャットフード 4.4kg',
      'レノア 超消臭1WEEK 柔軟剤 SPORTS フレッシュシトラステキスト',
      '完全ワイヤレスイヤホン Bluetooth5.3 ハイノイズキャンセリング',
      '高速充電対応 USB-C ケーブル 1.8m 耐久ナイロン編み',
      'スマートウォッチ 1.85インチ大画面 防水 心拍歩数計',
    ];

    final mockPrices = [2999, 7900, 13200, 6600, 2598, 4499, 1045, 3980, 1280, 4980];
    final mockShops = ['TONOR公式ショップ', 'JBL Official', '音響機器専門店', 'ヘルスケア生活館', 'ペット用品本舗', 'ライフスタイルPRO'];

    return List.generate(
      10,
      (index) {
        final title = mockTitles[index % mockTitles.length];
        final price = mockPrices[index % mockPrices.length];
        final shop = mockShops[index % mockShops.length];

        return Product(
          itemCode: 'mock-$keyword-$index',
          title: '【疑似】$title',
          price: price,
          imageUrl: 'https://dummyimage.com/300x300/e5e5e5/333333.png&text=Product+${index + 1}',
          itemUrl: 'https://hb.afl.rakuten.co.jp/',
          reviewAverage: 4.3 + (index % 4) * 0.2,
          reviewCount: 150 + index * 85,
          shopName: shop,
        );
      },
    );
  }
}
