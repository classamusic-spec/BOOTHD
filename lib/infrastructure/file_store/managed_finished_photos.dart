import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/services/finished_photos.dart';

/// [FinishedPhotos] under managed storage's `outputs/`: only relative
/// paths inside it are read, and the bytes must match their checksum.
final class ManagedFinishedPhotos implements FinishedPhotos {
  ManagedFinishedPhotos({required this._root});

  final Future<Directory> Function() _root;

  static final _validPath = RegExp(r'^outputs/[0-9a-f-]{36}\.(jpg|png)$');

  @override
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  }) async {
    if (!_validPath.hasMatch(relativePath)) {
      throw const FinishedPhotoUnreadable('missing');
    }
    final Uint8List bytes;
    try {
      bytes = await File('${(await _root()).path}/$relativePath').readAsBytes();
    } on FileSystemException {
      throw const FinishedPhotoUnreadable('missing');
    }
    if (crypto.sha256.convert(bytes).toString() != sha256) {
      throw const FinishedPhotoUnreadable('checksum');
    }
    return bytes;
  }
}
