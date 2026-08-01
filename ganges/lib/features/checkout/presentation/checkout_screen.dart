import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import 'checkout_success_screen.dart';

class CheckoutScreen extends ConsumerWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 到着予定ヘッダー 1
            const Text(
              '到着予定 2026年8月21日',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            // 配送ラジオ選択肢
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: 1,
                        onChanged: (v) {},
                        activeColor: Colors.blue[700],
                      ),
                      const Expanded(
                        child: Text('最短で配送 8月21日金曜日', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const Text('無料', style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 2,
                        groupValue: 1,
                        onChanged: (v) {},
                        activeColor: Colors.blue[700],
                      ),
                      const Expanded(
                        child: Text('日付指定 8月24日月曜日 8:00〜12:00', style: TextStyle(fontSize: 14)),
                      ),
                      const Text('無料', style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 注文対象商品リストカード（参考画像004905そのまま）
            ...cartItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CachedNetworkImage(imageUrl: item.product.imageUrl, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¥${currencyFormat.format(item.product.price)}(¥${currencyFormat.format(item.product.price)}/個) ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(item.product.price * 0.01).floor()}ポイント(1%)',
                              style: const TextStyle(fontSize: 12, color: AppColors.priceRed),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '販売元 ${item.product.shopName.isNotEmpty ? item.product.shopName : "Amazonストア"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.amazonLinkBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.amazonYellow, width: 2),
                          borderRadius: BorderRadius.circular(17),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.delete_outline, size: 18),
                            const SizedBox(width: 12),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('ギフトオプションはありません', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                    ],
                  ),
                ],
              ),
            )),

            const Divider(height: 32),

            // 参考画像004910そのままの黄色の「注文を確定する」ボタン
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
                onPressed: () async {
                  // レジ画面の「注文を確定する」を押したタイミングで初めて購入確定処理を実行！
                  final order = await ref.read(historyProvider.notifier).placeOrder(cartItems: cartItems);
                  if (order != null && context.mounted) {
                    ref.read(cartProvider.notifier).clearCart();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutSuccessScreen(order: order),
                      ),
                    );
                  }
                },
                child: const Text('注文を確定する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '「注文を確定する」ボタンを押してご注文いただくことで、お客様は当サイトの各種規約、プライバシー規約および当サイト上の販売条件に同意のうえ、商品を注文されたことになります（疑似ショッピング）。',
              style: TextStyle(fontSize: 11, color: AppColors.textSubtle, height: 1.3),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
