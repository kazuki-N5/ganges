import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/delivery_item_model.dart';
import '../../providers/delivery_provider.dart';

class DeliveryStatusCard extends HookConsumerWidget {
  final List<DeliveryItemProgress> items;

  const DeliveryStatusCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 配送完了ダイアログの重複表示防止用状態
    final shownDialogIds = useState<Set<String>>({});

    // 配送完了した荷物の検出とモーダル表示
    useEffect(() {
      for (final item in items) {
        if (item.progress >= 1.0 && !shownDialogIds.value.contains(item.itemCode)) {
          shownDialogIds.value = {...shownDialogIds.value, item.itemCode};
          
          Future.microtask(() {
            if (context.mounted) {
              _showDeliveryCompletedDialog(context, item);
            }
          });
        }
      }
      return null;
    }, [items]);

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: const Text('配送中の商品はありません'),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping, color: AppColors.amazonOrange, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'リアルタイムお届けステータス',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(deliveryProvider.notifier).restartDemo();
                  },
                  icon: const Icon(Icons.refresh, size: 14, color: AppColors.amazonOrange),
                  label: const Text('デモ再始動', style: TextStyle(fontSize: 12, color: AppColors.amazonOrange)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 各商品ごとのアプローチ状況リスト
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildDeliveryItemRow(context, item, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItemRow(BuildContext context, DeliveryItemProgress item, int index) {
    final isCompleted = item.progress >= 1.0;
    final isDispatched = item.isDispatched;

    final Color badgeColor = isCompleted
        ? AppColors.amazonGreen
        : isDispatched
            ? AppColors.amazonOrange
            : Colors.blueGrey;

    final String badgeStatusText = isCompleted
        ? '完了'
        : isDispatched
            ? '走行中'
            : '準備中';

    return Row(
      children: [
        // 商品/荷物バッジ
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📦$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                badgeStatusText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // 商品詳細 & ステータス
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                item.statusDetailText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: !isDispatched ? Colors.blueGrey[700] : AppColors.textSubtle,
                  fontWeight: !isDispatched ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              // 進捗プログレスバー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: !isDispatched ? 0.05 : item.progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // 残りカウントダウン / 距離情報
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isCompleted) ...[
              const Icon(Icons.check_circle, color: AppColors.amazonGreen, size: 22),
              const SizedBox(height: 2),
              const Text('置き配完了', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amazonGreen)),
            ] else if (!isDispatched) ...[
              Text(
                '準備中 (${item.dispatchDelayHours}h後発)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
              Text(
                '残り ${item.dispatchRemainingSec.ceil()}秒',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amazonOrange),
              ),
            ] else ...[
              Text(
                'あと ${item.remainingSeconds} 秒',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.priceRed),
              ),
              Text(
                '距離: ${item.remainingDistanceMeters}m',
                style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // 到着時の置き配完了モーダル
  static void _showDeliveryCompletedDialog(BuildContext context, DeliveryItemProgress item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.amazonGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.doorbell, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'ピンポーン♪ 配達完了！',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
              ),
              const SizedBox(height: 8),
              Text(
                '『${item.title}』が玄関前へ無事に置き配されました！📦📸',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '【置き配写真確認】\n玄関扉の横に綺麗に配置完了いたしました。',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amazonOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('確認しました', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
