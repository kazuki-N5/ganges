import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../domain/product_model.dart';
import '../repository/product_repository.dart';
import 'product_detail_screen.dart';

class ProductSearchScreen extends HookConsumerWidget {
  final String keyword;

  const ProductSearchScreen({super.key, required this.keyword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController(text: keyword);
    final searchKeyword = useState(keyword);
    final productsAsync = ref.watch(productSearchProvider(searchKeyword.value));
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDE4C3), Color(0xFFF9C68E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Amazon.co.jp を検索',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textDark, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.textDark),
                            onPressed: () {},
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            searchKeyword.value = val.trim();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('検索結果がありません'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildSearchResultTile(context, ref, product, currencyFormat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amazonOrange)),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildSearchResultTile(BuildContext context, WidgetRef ref, Product product, NumberFormat currencyFormat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側: 画像 ＆ 下部ハートアイコン
            SizedBox(
              width: 130,
              child: Column(
                children: [
                  SizedBox(
                    height: 130,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.textDark),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border, size: 18, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 右側: 詳細 ＆ 黄色「カートに入れる」ボタン
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(product.reviewAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text('(${currencyFormat.format(product.reviewCount)})', style: const TextStyle(fontSize: 11, color: AppColors.amazonLinkBlue)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '¥${currencyFormat.format(product.price)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  const Text('無料配送 本日中にお届け', style: TextStyle(fontSize: 11, color: AppColors.textSubtle)),
                  const SizedBox(height: 10),

                  // 黄色の「カートに入れる」ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amazonYellow,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('カートに追加しました'), backgroundColor: AppColors.textDark),
                        );
                      },
                      child: const Text('カートに入れる', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
