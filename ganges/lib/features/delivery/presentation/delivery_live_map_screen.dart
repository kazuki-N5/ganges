import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/delivery_provider.dart';
import 'widgets/delivery_map_canvas.dart';
import 'widgets/delivery_status_card.dart';

class DeliveryLiveMapScreen extends ConsumerWidget {
  const DeliveryLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryItems = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E2836),
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.amazonOrange, size: 22),
            SizedBox(width: 8),
            Text(
              'リアルタイム配達ライブマップ',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.directions_run, color: AppColors.amazonOrange),
                      SizedBox(width: 8),
                      Text('疑似配達ライブマップとは？', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  content: const Text(
                    '注文された商品（またはデモ商品）が各拠点から発送され、'
                    '点線ルートに沿ってリアルタイムに自宅へ近づくワクワク配送体験機能です！\n'
                    'トラックが自宅に到達すると、置き配通知が届きます。',
                    style: TextStyle(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
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
              child: DeliveryMapCanvas(items: deliveryItems),
            ),
          ),

          // 下部：ステータス & 到着カウントダウンカード
          DeliveryStatusCard(items: deliveryItems),
        ],
      ),
    );
  }
}
