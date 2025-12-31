import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'audio_helper_stub.dart';

class WebAudioHelper implements AudioHelper {
  @override
  Future<void> playAudio(Uint8List bytes) async {
    final blob = html.Blob([bytes], 'audio/wav');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    
    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(url);
    });
    
    audio.onError.listen((e) {
      html.Url.revokeObjectUrl(url);
    });
    
    await audio.play();
  }

  @override
  Future<Uint8List?> blobToBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Blob conversion error: $e');
    }
    return null;
  }
}

AudioHelper getAudioHelper() => WebAudioHelper();
