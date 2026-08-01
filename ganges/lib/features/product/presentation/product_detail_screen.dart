import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../checkout/presentation/checkout_success_screen.dart';
import '../domain/product_model.dart';

class ProductDetailScreen extends HookConsumerWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  Future<void> _launchAffiliateUrl(BuildContext context) async {
    final Uri url = Uri.parse(product.itemUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ページを開くことができませんでした')),
        );
      }
    }
  }

  // 添付画像通りの「カートに追加されました」＋「一緒によく購入されている商品(10個)」ボトムシートモーダル
  void _showAddToCartModal(BuildContext context, WidgetRef ref, int selectedQuantity) {
    final currencyFormat = NumberFormat("#,###");

    // 10個の「この商品とよく一緒に購入されている商品」サンプルデータ
    final recommendedProducts = [
      Product(
        itemCode: 'rec-1',
        title: '【Amazon.co.jp限定】ロジクール ワイヤレスキーボード 無線 MX KEYS mini KX700GRd 日本語配列 国内正規品',
        price: 12980,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Keyboard',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.6,
        reviewCount: 1294,
        shopName: 'Logicool公式ストア',
      ),
      Product(
        itemCode: 'rec-2',
        title: 'Aenllosi収納ケース 互換品 Logicool ロジクール M575SPd / M575S / M575GR 硬質EVAシェル 衝撃吸収',
        price: 1899,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Case',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.4,
        reviewCount: 912,
        shopName: 'Aenllosi直営店',
      ),
      Product(
        itemCode: 'rec-3',
        title: 'ロジクール対応 トラックボール マウス ERGO M575 シリーズ専用 15度 傾斜 角度 スタンド チルト補助パッド',
        price: 1480,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Stand',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.3,
        reviewCount: 430,
        shopName: 'トラックボールアクセサリー工房',
      ),
      Product(
        itemCode: 'rec-4',
        title: 'エレコム パソコン受信用 USB 超小型アダプタ Bluetooth 5.0 Class2 2.4GHz',
        price: 1280,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Adapter',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.2,
        reviewCount: 2150,
        shopName: 'エレコムダイレクトショップ',
      ),
      Product(
        itemCode: 'rec-5',
        title: 'Anker PowerLine III USB-C & USB-C 2.0 ケーブル 60W 1.8m ブラック 超高耐久',
        price: 1190,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Cable',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.7,
        reviewCount: 8900,
        shopName: 'Anker Direct',
      ),
      Product(
        itemCode: 'rec-6',
        title: 'エレコム リストレスト 疲労軽減 低反発 COMFY ブラック MOH-013BK',
        price: 980,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Wristrest',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.1,
        reviewCount: 3410,
        shopName: 'エレコムダイレクトショップ',
      ),
      Product(
        itemCode: 'rec-7',
        title: 'サンワサプライ 大型マウスパッド スムースクロス仕様 300×240mm ブラック',
        price: 850,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Mousepad',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.3,
        reviewCount: 1520,
        shopName: 'サンワダイレクト',
      ),
      Product(
        itemCode: 'rec-8',
        title: 'エアダスター 超強力 逆さ使用OK 350ml 3本セット ノンフロン ECO',
        price: 1580,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Airduster',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.5,
        reviewCount: 5100,
        shopName: 'PCサプライWEB店',
      ),
      Product(
        itemCode: 'rec-9',
        title: 'クリーニングクロス 超極細繊維 マイクロファイバー 液晶画面 クリーナー 5枚入',
        price: 790,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Cloth',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.6,
        reviewCount: 1890,
        shopName: 'クリーンパートナー',
      ),
      Product(
        itemCode: 'rec-10',
        title: 'モニターアーム シングル 17~32インチ対応 昇降デスク適応 耐荷重9kg 360度回転',
        price: 4980,
        imageUrl: 'https://dummyimage.com/200x200/e5e5e5/333333.png&text=Arm',
        itemUrl: 'https://hb.afl.rakuten.co.jp/',
        reviewAverage: 4.5,
        reviewCount: 6700,
        shopName: 'デスク環境Lab',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 1. 右上の「完了」ボタン ＆ ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '完了',
                        style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 添付画像そのままの「✔ カートに追加されました」表示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.amazonGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'カートに追加されました',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.amazonGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1, color: AppColors.borderGrey),

              // 3. 「この商品とよく一緒に購入されている商品」見出し ＆ 10個の縦リスト
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'この商品とよく一緒に購入されている商品',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 14),

                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recommendedProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final recItem = recommendedProducts[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CachedNetworkImage(imageUrl: recItem.imageUrl, fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recItem.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: AppColors.amazonLinkBlue, height: 1.3),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const Icon(Icons.star_half, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${recItem.reviewCount}件のレビュー', style: const TextStyle(fontSize: 11, color: AppColors.amazonLinkBlue)),
                                        const SizedBox(width: 4),
                                        const Text('✓prime', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'タイムセール価格: ¥${currencyFormat.format(recItem.price)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 8),

                                    // 黄色の「カートに追加」ボタン
                                    SizedBox(
                                      height: 34,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.amazonYellow,
                                          foregroundColor: AppColors.textDark,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        onPressed: () {
                                          ref.read(cartProvider.notifier).addToCart(recItem);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('カートに追加しました'), duration: Duration(seconds: 1)),
                                          );
                                        },
                                        child: const Text('カートに追加', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 参考画像「今すぐ買うを押した時」のAmazonボトムシート（モーダル）表示
  void _showBuyNowModal(BuildContext context, WidgetRef ref, int selectedQuantity) {
    final currencyFormat = NumberFormat("#,###");
    final totalPrice = product.price * selectedQuantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('8月21日金曜日', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            '数量: $selectedQuantity  /  発送元および販売元: ${product.shopName.isNotEmpty ? product.shopName : "Amazonストア"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.amazonLinkBlue),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.amazonLinkBlue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue[50],
                        ),
                        child: Column(
                          children: const [
                            Text('8月21日金曜日', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('無料 通常配送', style: TextStyle(fontSize: 11, color: AppColors.textSubtle)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: const [
                            Text('8月24日月曜日 8:00~12:00', style: TextStyle(fontSize: 11), maxLines: 1),
                            Text('無料 お届け日時指定便', style: TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),

                const SizedBox(height: 12),
                Row(
                  children: const [
                    Text('お届け先', style: TextStyle(color: AppColors.textSubtle, fontSize: 13)),
                    SizedBox(width: 16),
                    Expanded(child: Text('西村太郎、 261-0013, 千葉県...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Text('お支払い', style: TextStyle(color: AppColors.textSubtle, fontSize: 13)),
                    SizedBox(width: 16),
                    Expanded(child: Text('Amazon Prime Mastercard 4058', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('合計 (数量: $selectedQuantity)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('¥${currencyFormat.format(totalPrice)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const Text('(税込み)', style: TextStyle(fontSize: 11, color: AppColors.textSubtle)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amazonOrange,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 1,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final singleCartItem = CartItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        product: product,
                        quantity: selectedQuantity,
                        addedAt: DateTime.now(),
                      );
                      final order = await ref.read(historyProvider.notifier).placeOrder(cartItems: [singleCartItem]);
                      if (order != null && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutSuccessScreen(order: order)));
                      }
                    },
                    child: const Text('注文を確定する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '「注文する」ボタンをクリックすると、Amazon.co.jpの規約に同意したものとみなされます（疑似体験）。',
                  style: TextStyle(fontSize: 10, color: AppColors.textSubtle),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat("#,###");
    final selectedQuantity = useState(1);

    return Scaffold(
      backgroundColor: Colors.white,
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
                      child: Row(
                        children: const [
                          SizedBox(width: 10),
                          Icon(Icons.search, color: AppColors.textDark, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('検索または質問する', style: TextStyle(color: AppColors.textSubtle, fontSize: 13)),
                          ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ブランド: ${product.shopName.isNotEmpty ? product.shopName : "Amazonストア"}',
                    style: const TextStyle(color: AppColors.amazonLinkBlue, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(product.reviewAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text('(${currencyFormat.format(product.reviewCount)})', style: const TextStyle(fontSize: 11, color: AppColors.amazonLinkBlue)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                product.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark, height: 1.3),
              ),
            ),

            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.contain)
                      : const Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.favorite_border, color: AppColors.textDark), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.share_outlined, color: AppColors.textDark), onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('¥', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 6),
                      const Text('税込', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('在庫あり。', style: TextStyle(color: AppColors.amazonGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),

                  Container(
                    height: 44,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      border: Border.all(color: AppColors.borderGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedQuantity.value,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            selectedQuantity.value = newValue;
                          }
                        },
                        items: List.generate(10, (index) => index + 1)
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('数量: $value'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // カートに入れるボタン（押した時にシュッと添付画像のボトムシートを表示！）
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
                        // カートに追加後、添付画像通りのボトムシートモーダルを表示！
                        ref.read(cartProvider.notifier).addToCart(product, quantity: selectedQuantity.value);
                        _showAddToCartModal(context, ref, selectedQuantity.value);
                      },
                      child: Text('カートに入れる (${selectedQuantity.value}個)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 今すぐ買うボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amazonOrange,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: () => _showBuyNowModal(context, ref, selectedQuantity.value),
                      child: const Text('今すぐ買う', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text('本物を購入したい場合（アフィリエイト連携）', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red[900], side: const BorderSide(color: Colors.redAccent)),
                          onPressed: () => _launchAffiliateUrl(context),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('本物の楽天市場で見る', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
