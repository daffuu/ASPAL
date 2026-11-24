import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReportLocationMap extends StatelessWidget {
  const ReportLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.tileProvider,
  });
  final double? latitude;
  final double? longitude;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final lat = latitude;
    final lon = longitude;
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      return const Text('Lokasi belum ditentukan');
    }
    final point = LatLng(lat, lon);
    return SizedBox(
      height: 180,
      child: _MarkerMap(
        key: ValueKey(point),
        point: point,
        provider: tileProvider,
      ),
    );
  }
}

class _MarkerMap extends StatefulWidget {
  const _MarkerMap({super.key, required this.point, this.provider});
  final LatLng point;
  final TileProvider? provider;
  @override
  State<_MarkerMap> createState() => _MarkerMapState();
}

class _MarkerMapState extends State<_MarkerMap> {
  late final _tiles = widget.provider ?? NetworkTileProvider();
  bool _unavailable = false;

  @override
  Widget build(BuildContext context) {
    if (_unavailable) {
      return const Center(child: Text('Peta dasar tidak tersedia.'));
    }
    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.aspal',
          panBuffer: 0,
          tileProvider: _tiles,
          errorTileCallback: (_, error, stack) {
            scheduleMicrotask(() {
              if (mounted && !_unavailable) setState(() => _unavailable = true);
            });
          },
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.point,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30,
                semanticLabel: 'Lokasi laporan',
              ),
            ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
