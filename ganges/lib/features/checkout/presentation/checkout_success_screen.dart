import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/order_model.dart';

class CheckoutSuccessScreen extends ConsumerWidget {
  final OrderModel order;

  const CheckoutSuccessScreen({super.key, required this.order});

  // 本物の楽天購入アフィリエイトURL（注文アイテム先頭を開く）
  Future<void> _launchMainProductAffiliate(BuildContext context) async {
    if (order.items.isNotEmpty) {
      final itemCode = order.items.first.itemCode;
      final Uri url = Uri.parse('https://hb.afl.rakuten.co.jp/hgc/g00q0431.25b80b2a.g00q0431.25b81cf7/?pc=https%3A%2F%2Fitem.rakuten.co.jp%2Fmock%2F$itemCode');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ページを開くことができませんでした')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        automaticallyImplyLeading: false,
        title: const Text('注文完了（疑似）', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Amazonグリーン緑チェックマーク
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.amazonGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 55,
              ),
            ),
            const SizedBox(height: 16),

            // 「ご注文ありがとうございました」
            const Text(
              'ご注文ありがとうございました',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '注文番号: ${order.orderId}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
            const SizedBox(height: 20),

            // 節約達成ハイライトカード
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                border: Border.all(color: AppColors.amazonGreen, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings, color: AppColors.amazonGreen, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '疑似買い物成功！',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.amazonGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '実質 ¥${currencyFormat.format(order.totalSavings)} の節約達成！',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.priceRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '実際のお金は1円も引かれていません。ストレス発散完了です！',
                    style: TextStyle(fontSize: 12, color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 注文明細概要
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('お届け予定日（疑似）:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('明日お届け予定（実際には届きません）', style: TextStyle(color: AppColors.amazonGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 24),
                  const Text('購入商品:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.title} (x${item.quantity})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text('¥${currencyFormat.format(item.price * item.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 本物の楽天アフィリエイト案内
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    '本当に本物が欲しくなった場合はこちら',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _launchMainProductAffiliate(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('本物の楽天市場で購入手続きに進む', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ホームへ戻るボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amazonYellow,
                  foregroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('ホームに戻ってさらに買い物する', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
