import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/product/domain/product_model.dart';

class RakutenApiClient {
  static String get _appId => dotenv.env['RAKUTEN_APP_ID'] ?? '';
  static String get _accessKey => dotenv.env['RAKUTEN_ACCESS_KEY'] ?? '';
  static String get _affiliateId => dotenv.env['RAKUTEN_AFFILIATE_ID'] ?? '';

  static const String _searchBaseUrl = 'https://openapi.rakuten.co.jp/ichibams/api/IchibaItem/Search/20260701';
  static const String _fallbackSearchUrl = 'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601';
  static const String _rankingBaseUrl = 'https://app.rakuten.co.jp/services/api/IchibaItem/Ranking/20220601';

  // 開発中モックモードフラグ（リアル通信に切り替え）
  static const bool useMockOnly = false;

  final Dio _dio;

  RakutenApiClient({Dio? dio}) : _dio = dio ?? Dio();

  /// 楽天市場商品ランキングAPI（おすすめ・総合ランキング商品を取得）
  Future<List<Product>> getRankingProducts({int hits = 30}) async {
    if (useMockOnly) {
      return _getMockProducts('ランキング');
    }

    try {
      final response = await _dio.get(
        _rankingBaseUrl,
        queryParameters: {
          'applicationId': _appId,
          if (_affiliateId.isNotEmpty) 'affiliateId': _affiliateId,
          'format': 'json',
          'hits': hits,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List items = response.data['Items'] ?? [];
        return items.map((item) => Product.fromRakutenJson(item)).toList();
      }
    } catch (e) {
      // エラー発生時は商品検索API（おすすめ）へフォールバック
    }

    return searchProducts(keyword: 'おすすめ', hits: hits);
  }

  /// ジャンルIDを指定して楽天おすすめ順で商品を取得
  Future<List<Product>> getProductsByGenre({
    required String genreId,
    int hits = 10,
  }) async {
    if (useMockOnly || genreId.isEmpty) {
      return getRankingProducts(hits: hits);
    }

    try {
      final response = await _dio.get(
        _searchBaseUrl,
        options: Options(headers: {'Origin': 'https://example.com'}),
        queryParameters: {
          'applicationId': _appId,
          if (_accessKey.isNotEmpty) 'accessKey': _accessKey,
          if (_affiliateId.isNotEmpty) 'affiliateId': _affiliateId,
          'format': 'json',
          'genreId': genreId,
          'sort': 'standard',
          'hits': hits,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List items = response.data['Items'] ?? [];
        return items.map((item) => Product.fromRakutenJson(item)).toList();
      }
    } catch (e) {
      // 通信エラー時はランキングAPIへフォールバック
    }

    return getRankingProducts(hits: hits);
  }

  Future<List<Product>> searchProducts({
    String keyword = 'ガジェット',
    int hits = 30,
    int page = 1,
    String? sort,
  }) async {
    if (useMockOnly) {
      return _getMockProducts(keyword);
    }

    // 1. openapi 新仕様通信
    try {
      final response = await _dio.get(
        _searchBaseUrl,
        options: Options(
          headers: {
            'Origin': 'https://example.com',
          },
        ),
        queryParameters: {
          'applicationId': _appId,
          if (_accessKey.isNotEmpty) 'accessKey': _accessKey,
          if (_affiliateId.isNotEmpty) 'affiliateId': _affiliateId,
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
      // 2. 旧APIエンドポイントへフォールバック
      try {
        final response = await _dio.get(
          _fallbackSearchUrl,
          queryParameters: {
            'applicationId': _appId,
            if (_affiliateId.isNotEmpty) 'affiliateId': _affiliateId,
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
      } catch (fallbackErr) {
        return _getMockProducts(keyword);
      }
    }
    return _getMockProducts(keyword);
  }

  // 開発用モック商品群（通信失敗時・緊急フォールバック用）
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
