import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'report_photos.dart';

typedef CaptureLocation = ({
  double latitude,
  double longitude,
  double accuracy,
});

class CapturedPhoto {
  const CapturedPhoto(this.bytes, this.source, this.location, this.warning);
  final Uint8List bytes;
  final String source;
  final CaptureLocation? location;
  final String? warning;
}

class ReportCapture {
  ReportCapture({
    this.photos = const ReportPhotos(),
    this.pick = _pick,
    this.locate = _locate,
  });
  final ReportPhotos photos;
  final Future<XFile?> Function(ImageSource) pick;
  final Future<CaptureLocation> Function() locate;

  static Future<XFile?> _pick(ImageSource source) => ImagePicker().pickImage(
    source: source,
    maxWidth: 2400,
    maxHeight: 2400,
    imageQuality: 88,
  );

  static Future<CaptureLocation> _locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const FormatException('Aktifkan layanan lokasi untuk merekam GPS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const FormatException(
        'Izin lokasi diblokir. Aktifkan di pengaturan aplikasi.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const FormatException('Izin lokasi ditolak.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
    );
  }

  Future<CapturedPhoto?> capture(ImageSource source) async {
    final picked = await pick(source);
    if (picked == null) return null;
    CaptureLocation? location;
    String? warning;
    if (source == ImageSource.camera) {
      try {
        location = await locate();
      } on FormatException catch (e) {
        warning = e.message;
      } catch (_) {
        warning = 'Lokasi belum diperoleh.';
      }
    }
    final bytes = await photos.prepare(await picked.readAsBytes());
    return CapturedPhoto(
      bytes,
      source == ImageSource.camera ? 'camera' : 'manual',
      location,
      warning,
    );
  }
}
