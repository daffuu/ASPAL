import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReportPhotos {
  const ReportPhotos({this.supportDirectory = getApplicationSupportDirectory});
  final Future<Directory> Function() supportDirectory;
  static const limit = 2 * 1024 * 1024;

  /// The picker limits input dimensions on Android. Decode at a bounded size
  /// and progressively resize oversized photos using the Flutter engine.
  Future<Uint8List> prepare(Uint8List input) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(input);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final longest = math.max(descriptor.width, descriptor.height);
        var side = math.min(longest, 1600);
        while (side >= 1) {
          final scale = side / longest;
          final codec = await descriptor.instantiateCodec(
            targetWidth: math.max(1, (descriptor.width * scale).round()),
            targetHeight: math.max(1, (descriptor.height * scale).round()),
          );
          try {
            final frame = await codec.getNextFrame();
            try {
              if (input.length <= limit) return input;
              final encoded = await frame.image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (encoded != null && encoded.lengthInBytes <= limit) {
                return encoded.buffer.asUint8List(
                  encoded.offsetInBytes,
                  encoded.lengthInBytes,
                );
              }
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
          side ~/= 2;
        }
        throw const FormatException(
          'Foto masih lebih dari 2 MB. Pilih foto lain.',
        );
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  Future<Directory> _directory() async {
    final root = await supportDirectory();
    final directory = Directory(path.join(root.path, 'report_photos'));
    if (await FileSystemEntity.type(directory.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException('Direktori foto tidak valid.');
    }
    return directory;
  }

  Future<File> persist(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > limit) {
      throw const FormatException('Ukuran foto harus antara 1 byte dan 2 MB.');
    }
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, '${const Uuid().v4()}.photo'));
    try {
      await file.writeAsBytes(bytes, flush: true);
      if (await file.length() != bytes.length) {
        throw const FileSystemException('Foto belum tersimpan lengkap.');
      }
      return file;
    } catch (_) {
      await discard(file.path);
      rethrow;
    }
  }

  Future<void> discard(String? name) async {
    if (name == null || !name.endsWith('.photo')) return;
    final directory = await _directory();
    final file = File(name);
    if (!path.equals(path.dirname(path.normalize(name)), directory.path) ||
        await FileSystemEntity.type(name, followLinks: false) !=
            FileSystemEntityType.file) {
      return;
    }
    if (path.equals(
      path.dirname(await file.resolveSymbolicLinks()),
      await directory.resolveSymbolicLinks(),
    )) {
      await file.delete();
    }
  }
}
