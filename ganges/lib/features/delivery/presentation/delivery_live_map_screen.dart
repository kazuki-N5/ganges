import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/delivery_provider.dart';
import 'widgets/delivery_map_canvas.dart';
import 'widgets/delivery_status_card.dart';

class DeliveryLiveMapScreen extends HookConsumerWidget {
  const DeliveryLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryItems = ref.watch(deliveryProvider);
    // トグル状態：false = 配送中のみ表示（デフォルト）、true = 全履歴表示
    final showAllHistory = useState(false);
    // 配達完了ダイアログ表示済み（確認済み）のIDセット
    final shownDialogIds = useState<Set<String>>({});
    final isInitialized = useRef(false);

    // 初回ロード時に既に配達完了している過去のアイテムは確認済みとして初期セット
    useEffect(() {
      if (!isInitialized.value && deliveryItems.isNotEmpty) {
        isInitialized.value = true;
        final initialCompletedKeys = deliveryItems
            .where((item) => item.progress >= 1.0)
            .map((item) => '${item.orderId}_${item.itemCode}')
            .toSet();
        shownDialogIds.value = initialCompletedKeys;
      }
      return null;
    }, [deliveryItems]);

    // フィルタリング処理：
    // 全表示がONの時は全アイテム。
    // 配送中のみ表示の時は「進行中(progress < 1.0)」または「完了したがまだダイアログ未確認(!shownDialogIds)」を表示。
    final displayedItems = showAllHistory.value
        ? deliveryItems
        : deliveryItems.where((item) {
            final key = '${item.orderId}_${item.itemCode}';
            return item.progress < 1.0 || !shownDialogIds.value.contains(key);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E2836),
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.amazonOrange, size: 20),
            SizedBox(width: 6),
            Text(
              '配達ライブマップ',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                showAllHistory.value ? '全表示' : '配送中のみ',
                style: TextStyle(
                  color: showAllHistory.value ? AppColors.amazonOrange : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: showAllHistory.value,
                  activeColor: AppColors.amazonOrange,
                  activeTrackColor: AppColors.amazonOrange.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[700],
                  onChanged: (val) {
                    showAllHistory.value = val;
                  },
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部：リアルタイム配送キャンバス
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1E2836),
              child: DeliveryMapCanvas(items: displayedItems),
            ),
          ),

          // 下部：ステータス & 到着カウントダウンカード
          DeliveryStatusCard(
            items: displayedItems,
            shownDialogIds: shownDialogIds,
          ),
        ],
      ),
    );
  }
}
