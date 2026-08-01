import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../domain/delivery_hub_model.dart';
import '../../domain/delivery_item_model.dart';

class DeliveryMapCanvas extends HookConsumerWidget {
  final List<DeliveryItemProgress> items;

  const DeliveryMapCanvas({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1秒周期で連続リピートするAnimationController (Ticker)
    final animController = useAnimationController(
      duration: const Duration(seconds: 1),
    )..repeat();

    // ご自宅の座標 (東京)
    final homeHub = DeliveryHubResolver.homeHub;
    final homeLatLng = LatLng(homeHub.latitude, homeHub.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(36.5, 137.8),
        initialZoom: 5.4,
        minZoom: 4.0,
        maxZoom: 18.0,
      ),
      children: [
        // 高精細Retina(@2x)対応マップタイル (一度だけ生成・固定され再描画コストを削減)
        TileLayer(
          urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.example.ganges',
          retinaMode: true,
        ),
        // マーカーと配送曲線のレイヤーのみを AnimationController で局所的に60FPS描画
        AnimatedBuilder(
          animation: animController,
          builder: (context, child) {
            final animationFraction = animController.value;
            final markers = _buildMarkers(homeLatLng, animationFraction);

            return Stack(
              children: [
                DeliveryCurveLayer(
                  items: items,
                  homeLatLng: homeLatLng,
                ),
                MarkerLayer(markers: markers),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 補間計算を行ったマーカーリストの構築
  List<Marker> _buildMarkers(LatLng homeLatLng, double animationFraction) {
    final markers = <Marker>[];

    // 1. ご自宅ピンマーカー（📍）
    markers.add(
      Marker(
        point: homeLatLng,
        width: 60,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00A843),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Text('📍', style: TextStyle(fontSize: 12)),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF00A843), size: 20),
          ],
        ),
      ),
    );

    // 2. 各商品の発送拠点・トラックマーカー
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final hubLatLng = LatLng(item.hub.latitude, item.hub.longitude);
      final isDispatched = item.isDispatched;

      // 制御点 (controlLatLng)
      final double controlLat = (hubLatLng.latitude + homeLatLng.latitude) / 2 + 0.8;
      final double controlLng = (hubLatLng.longitude + homeLatLng.longitude) / 2 - 0.8;
      final controlLatLng = LatLng(controlLat, controlLng);

      // 発送拠点マーカー (🏢)
      markers.add(
        Marker(
          point: hubLatLng,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: isDispatched ? const Color(0xFF2C3B4E) : Colors.blueGrey[800],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 3),
              ],
            ),
            child: const Center(
              child: Text('🏢', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );

      // 絶対時間(dispatchedAtからのリアルタイムミリ秒経過)に基づく巻き戻りゼロの滑らか進捗計算
      final now = DateTime.now();
      double smoothProgress = item.progress;
      if (isDispatched && item.progress < 1.0) {
        if (item.dispatchedAt != null) {
          final elapsedMs = now.difference(item.dispatchedAt!).inMilliseconds;
          // 90秒(90,000ms)で自宅に到着するシミュレーションペース
          smoothProgress = (elapsedMs / 90000.0).clamp(0.0, 1.0);
        } else {
          smoothProgress = (item.progress + (animationFraction * (1.0 / 90.0))).clamp(0.0, 1.0);
        }
      }
      final double progress = smoothProgress.clamp(0.0, 1.0);

      final currentLatLng = !isDispatched
          ? hubLatLng
          : _getQuadraticBezierPoint(hubLatLng, controlLatLng, homeLatLng, progress);
      final isCompleted = progress >= 1.0;

      markers.add(
        Marker(
          point: currentLatLng,
          width: 60,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF008A00)
                      : isDispatched
                          ? const Color(0xFFFFA41C)
                          : Colors.blueGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
                child: Text(
                  isCompleted
                      ? '📦'
                      : isDispatched
                          ? '🚚'
                          : '🏭',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xB3000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  !isDispatched ? '📦$i (${item.dispatchDelayHours}h後発)' : '📦${i + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  /// 2次ベジェ曲線上の座標を計算するヘルパーメソッド (トラック位置計算用)
  static LatLng _getQuadraticBezierPoint(LatLng p0, LatLng p1, LatLng p2, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double lat = uu * p0.latitude + 2 * u * t * p1.latitude + tt * p2.latitude;
    final double lng = uu * p0.longitude + 2 * u * t * p1.longitude + tt * p2.longitude;

    return LatLng(lat, lng);
  }
}

/// CustomPainterで直接CanvasにPath.quadraticBezierToを描画するレイヤー
class DeliveryCurveLayer extends StatelessWidget {
  final List<DeliveryItemProgress> items;
  final LatLng homeLatLng;

  const DeliveryCurveLayer({
    super.key,
    required this.items,
    required this.homeLatLng,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return CustomPaint(
      size: Size.infinite,
      painter: DeliveryCurvePainter(
        camera: camera,
        items: items,
        homeLatLng: homeLatLng,
      ),
    );
  }
}

/// CustomPainter本体
class DeliveryCurvePainter extends CustomPainter {
  final MapCamera camera;
  final List<DeliveryItemProgress> items;
  final LatLng homeLatLng;

  DeliveryCurvePainter({
    required this.camera,
    required this.items,
    required this.homeLatLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final homePoint = camera.latLngToScreenPoint(homeLatLng);
    final homeOffset = Offset(homePoint.x, homePoint.y);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final hubLatLng = LatLng(item.hub.latitude, item.hub.longitude);
      final hubPoint = camera.latLngToScreenPoint(hubLatLng);
      final hubOffset = Offset(hubPoint.x, hubPoint.y);

      // 制御点（地図上の制御点をスクリーン座標 Offset に変換）
      final double controlLat = (hubLatLng.latitude + homeLatLng.latitude) / 2 + 0.8;
      final double controlLng = (hubLatLng.longitude + homeLatLng.longitude) / 2 - 0.8;
      final controlPoint = camera.latLngToScreenPoint(LatLng(controlLat, controlLng));
      final controlOffset = Offset(controlPoint.x, controlPoint.y);

      final isDispatched = item.isDispatched;
      final paint = Paint()
        ..color = item.progress >= 1.0
            ? const Color(0xFF00A843).withOpacity(0.6)
            : isDispatched
                ? const Color(0xFFFFA41C).withOpacity(0.85)
                : Colors.blueGrey.withOpacity(0.35)
        ..strokeWidth = isDispatched ? 3.5 : 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // わざわざ分割せず、CanvasのPathとquadraticBezierToで一発描画！
      final path = Path();
      path.moveTo(hubOffset.dx, hubOffset.dy);
      path.quadraticBezierTo(
        controlOffset.dx,
        controlOffset.dy,
        homeOffset.dx,
        homeOffset.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DeliveryCurvePainter oldDelegate) => true;
}
