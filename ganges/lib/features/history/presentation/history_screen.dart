import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _launchUrl(String urlStr, BuildContext context) async {
    final Uri url = Uri.parse(urlStr.isEmpty ? 'https://hb.afl.rakuten.co.jp/' : urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ページを開くことができませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final statsAsync = ref.watch(statsProvider);
    final currencyFormat = NumberFormat("#,###");
    final dateFormat = DateFormat("yyyy/MM/dd HH:mm");

    return Scaffold(
      backgroundColor: AppColors.amazonBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        title: const Text('購入履歴 ＆ 節約カウンター', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 節約額ダッシュボードカード
              statsAsync.when(
                data: (stats) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF131921), Color(0xFF232F3E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium, color: AppColors.amazonOrange, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '通算節約パフォーマンス',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'アプリで節約できた合計金額',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${currencyFormat.format(stats.totalSavedAmount)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amazonOrange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('通算疑似注文数', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.totalOrderCount} 回',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white24),
                          Column(
                            children: [
                              const Text('無駄遣い防止スコア', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 4),
                              const Text(
                                'MAX (100pt)',
                                style: TextStyle(color: AppColors.amazonGreen, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (e, s) => const SizedBox(),
              ),
              const SizedBox(height: 18),

              // 注文履歴一覧タイトル
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'これまでの疑似注文履歴',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),

              // 注文履歴一覧
              historyAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      color: Colors.white,
                      child: Column(
                        children: const [
                          Icon(Icons.history_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('まだ購入履歴がありません'),
                          SizedBox(height: 4),
                          Text('「今すぐ買う」ボタンを押して買い物気分を体験しましょう！', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ヘッダー情報
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('注文日: ${dateFormat.format(order.orderedAt)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('注文番号: ${order.orderId}', style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                                    ],
                                  ),
                                  Text(
                                    '合計 ¥${currencyFormat.format(order.totalAmount)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.priceRed),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.borderGrey),

                            // 明細商品リスト
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[100],
                                    child: item.imageUrl.isNotEmpty
                                        ? Image.network(item.imageUrl, fit: BoxFit.contain)
                                        : const Icon(Icons.shopping_bag, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 2),
                                        Text('数量: ${item.quantity}  /  単価: ¥${currencyFormat.format(item.price)}', style: const TextStyle(fontSize: 11, color: AppColors.textSubtle)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),

                            // アフィリエイトリンクボタン
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[800],
                                    side: BorderSide(color: Colors.red[300]!),
                                  ),
                                  onPressed: () => _launchUrl('', context),
                                  icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                  label: const Text('本物の楽天で再検索', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amazonOrange)),
                error: (e, s) => Text('エラー: $e'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
