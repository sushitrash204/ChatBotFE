import 'dart:typed_data';

abstract class AudioHelper {
  Future<void> playAudio(Uint8List bytes);
  Future<Uint8List?> blobToBytes(String url);
}

AudioHelper getAudioHelper() => throw UnsupportedError('Cannot create an audio helper');
