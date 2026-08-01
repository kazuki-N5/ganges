import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/api/rakuten_api_client.dart';
import '../domain/product_model.dart';

final rakutenApiClientProvider = Provider<RakutenApiClient>((ref) {
  return RakutenApiClient();
});

// ホーム画面用おすすめ商品プロバイダー
final homeProductsProvider = FutureProvider<List<Product>>((ref) async {
  final client = ref.watch(rakutenApiClientProvider);
  return await client.searchProducts(keyword: 'ランキング ガジェット おすすめ', hits: 30);
});

// キーワード検索用プロバイダー (family)
final productSearchProvider = FutureProvider.family<List<Product>, String>((ref, keyword) async {
  if (keyword.trim().isEmpty) {
    return await ref.watch(homeProductsProvider.future);
  }
  final client = ref.watch(rakutenApiClientProvider);
  return await client.searchProducts(keyword: keyword, hits: 30);
});
