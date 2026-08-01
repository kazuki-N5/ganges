import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../../checkout/presentation/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currencyFormat = NumberFormat("#,###");
    final totalAmount = cartNotifier.totalAmount;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: AppColors.textDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(width: 10),
                          Icon(Icons.search, color: AppColors.textDark, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('検索または質問する', style: TextStyle(color: AppColors.textSubtle, fontSize: 13))),
                          Icon(Icons.camera_alt_outlined, color: AppColors.textDark, size: 20),
                          SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Amazonカートは空です', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 参考画像「カート」の上部小計 ＆ 黄色レジ進むボタンエリア
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('小計 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '¥${currencyFormat.format(totalAmount)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Text('獲得ポイント: 273ポイント ', style: TextStyle(fontSize: 12, color: AppColors.textDark)),
                            Text('> 内訳', style: TextStyle(fontSize: 12, color: AppColors.amazonLinkBlue)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('ご利用可能ポイント: 140ポイント', style: TextStyle(fontSize: 12, color: AppColors.textDark)),
                        const SizedBox(height: 14),

                        // 黄色の「レジに進む」ボタン
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amazonYellow,
                              foregroundColor: AppColors.textDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(cartItems: cartItems),
                                ),
                              );
                            },
                            child: Text(
                              'レジに進む (${cartItems.length}個の商品) (税込)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // カート内商品一覧
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CachedNetworkImage(imageUrl: item.product.imageUrl, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('¥${currencyFormat.format(item.product.price)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      const Text('無料配送 8月21日 金曜日にお届け', style: TextStyle(fontSize: 11, color: AppColors.textSubtle)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 数量ボタン ＆ 削除カプセルボタン
                            Row(
                              children: [
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.amazonYellow, width: 2),
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textDark),
                                        onPressed: () => cartNotifier.updateQuantity(item.id, item.quantity - 1),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18, color: AppColors.textDark),
                                        onPressed: () => cartNotifier.updateQuantity(item.id, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textDark,
                                    side: const BorderSide(color: AppColors.borderGrey),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  onPressed: () => cartNotifier.removeFromCart(item.id),
                                  child: const Text('削除', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textDark,
                                    side: const BorderSide(color: AppColors.borderGrey),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  onPressed: () {},
                                  child: const Text('あとで買う', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
