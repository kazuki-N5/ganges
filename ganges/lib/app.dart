import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/delivery/presentation/delivery_live_map_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';

class GangesApp extends ConsumerWidget {
  const GangesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Amazon Shopping',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends HookConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);
    final cartItems = ref.watch(cartProvider);

    final screens = const [
      HomeScreen(),
      CartScreen(),
      DeliveryLiveMapScreen(),
      HistoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex.value,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.8)),
        ),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              selectedIndex: selectedIndex.value,
              label: 'ホーム',
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              onTap: (idx) => selectedIndex.value = idx,
            ),
            _buildNavItem(
              index: 1,
              selectedIndex: selectedIndex.value,
              label: 'カート',
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart,
              badgeCount: cartItems.length,
              onTap: (idx) => selectedIndex.value = idx,
            ),
            _buildNavItem(
              index: 2,
              selectedIndex: selectedIndex.value,
              label: '配達 🚚',
              icon: Icons.local_shipping_outlined,
              activeIcon: Icons.local_shipping,
              onTap: (idx) => selectedIndex.value = idx,
            ),
            _buildNavItem(
              index: 3,
              selectedIndex: selectedIndex.value,
              label: 'マイページ',
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              onTap: (idx) => selectedIndex.value = idx,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
    required Function(int) onTap,
  }) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 75,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.amazonOrange : AppColors.textDark,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.amazonOrange : AppColors.textDark,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 4,
                right: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.priceRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.amazonOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
