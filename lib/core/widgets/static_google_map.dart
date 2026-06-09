import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class MapsConfigService {
  MapsConfigService._();

  static final MapsConfigService instance = MapsConfigService._();

  static const MethodChannel _channel =
      MethodChannel('com.zdelivery.zdelivery/config');

  Future<String> get googleMapsApiKey async {
    const dartDefineKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;

    try {
      final key = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      return key?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}

class StaticMapMarker {
  final double latitude;
  final double longitude;
  final String color;
  final String? label;

  const StaticMapMarker({
    required this.latitude,
    required this.longitude,
    this.color = 'red',
    this.label,
  });

  String get encodedValue {
    final labelPart =
        label == null || label!.isEmpty ? '' : '|label:${label![0]}';
    return 'color:$color$labelPart|$latitude,$longitude';
  }
}

class StaticMapPath {
  final List<({double latitude, double longitude})> points;
  final String color;
  final int weight;

  const StaticMapPath({
    required this.points,
    this.color = '0x2563EBff',
    this.weight = 5,
  });

  String get encodedValue {
    final coordinates =
        points.map((point) => '${point.latitude},${point.longitude}').join('|');
    return 'color:$color|weight:$weight|$coordinates';
  }
}

class StaticGoogleMap extends StatelessWidget {
  final List<StaticMapMarker> markers;
  final List<StaticMapPath> paths;
  final double? centerLatitude;
  final double? centerLongitude;
  final int zoom;
  final String size;
  final VoidCallback? onTap;
  final Widget? overlay;

  const StaticGoogleMap({
    super.key,
    required this.markers,
    this.paths = const [],
    this.centerLatitude,
    this.centerLongitude,
    this.zoom = 15,
    this.size = '640x640',
    this.onTap,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: MapsConfigService.instance.googleMapsApiKey,
      builder: (context, snapshot) {
        final apiKey = snapshot.data ?? '';
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StaticMapLoading();
        }

        if (apiKey.isEmpty || (markers.isEmpty && centerLatitude == null)) {
          return const _StaticMapUnavailable();
        }

        final url = _buildUrl(apiKey);
        final map = Image.network(
          url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const _StaticMapLoading();
          },
          errorBuilder: (_, __, ___) => const _StaticMapUnavailable(),
        );

        return Material(
          color: AppColors.surfaceVariant,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                map,
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
                if (overlay != null) overlay!,
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildUrl(String apiKey) {
    final params = <String, String>{
      'size': size,
      'scale': '2',
      'format': 'png',
      'maptype': 'roadmap',
      'key': apiKey,
    };

    if (markers.length <= 1 &&
        centerLatitude != null &&
        centerLongitude != null) {
      params['center'] = '$centerLatitude,$centerLongitude';
      params['zoom'] = zoom.toString();
    }

    var url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      params,
    ).toString();

    const styles = [
      'feature:poi|visibility:off',
      'feature:transit|visibility:off',
      'feature:administrative|element:labels.text.fill|color:0x475569',
      'feature:road|element:geometry|color:0xffffff',
      'feature:landscape|element:geometry|color:0xf7f8fb',
      'feature:water|element:geometry|color:0xdbeafe',
    ];

    for (final style in styles) {
      url += '&style=${Uri.encodeQueryComponent(style)}';
    }

    for (final path in paths) {
      if (path.points.length > 1) {
        url += '&path=${Uri.encodeQueryComponent(path.encodedValue)}';
      }
    }

    for (final marker in markers) {
      url += '&markers=${Uri.encodeQueryComponent(marker.encodedValue)}';
    }

    return url;
  }
}

class _StaticMapLoading extends StatelessWidget {
  const _StaticMapLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _StaticMapUnavailable extends StatelessWidget {
  const _StaticMapUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: AppColors.textTertiary,
              size: 34,
            ),
            SizedBox(height: 8),
            Text(
              'Map preview unavailable',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
