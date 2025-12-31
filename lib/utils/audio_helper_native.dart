import 'dart:typed_data';
import 'audio_helper_stub.dart';

class NativeAudioHelper implements AudioHelper {
  @override
  Future<void> playAudio(Uint8List bytes) async {
    // Native platforms handle audio via flutter_sound directly in the screen
    // so we don't need special blob handling here.
  }

  @override
  Future<Uint8List?> blobToBytes(String url) async {
    // Native platforms don't use blobs for recording
    return null;
  }
}

AudioHelper getAudioHelper() => NativeAudioHelper();
