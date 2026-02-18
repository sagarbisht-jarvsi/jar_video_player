import 'package:video_player/video_player.dart';

class JarVideoPlayerController {
  ///this is the Video Controller.
  VideoPlayerController? _videoController;

  VideoPlayerController? get videoController => _videoController;

  bool get isInitialized => _videoController?.value.isInitialized ?? false;

  bool get isPlaying => _videoController?.value.isPlaying ?? false;

  Duration get position => _videoController?.value.position ?? Duration.zero;

  Duration get duration => _videoController?.value.duration ?? Duration.zero;

  Future<void> initialize(
    String url, {
    bool autoPlay = false,
    bool loop = false,
  }) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    await _videoController!.initialize();
    await _videoController!.setLooping(loop);

    if (autoPlay) {
      await _videoController!.play();
    }
  }

  ///for playing the video
  Future<void> play() async {
    if (_videoController == null) return;
    await _videoController!.play();
  }

  ///for pausing the video

  Future<void> pause() async {
    if (_videoController == null) return;
    await _videoController!.pause();
  }

  ///for seeking to custom duration or position in the video

  Future<void> seekTo(Duration position) async {
    if (_videoController == null) return;
    await _videoController!.seekTo(position);
  }

  Future<void> disposeVideo() async {
    await _videoController?.dispose();
    _videoController = null;
  }

  Future<void> dispose() async {
    await disposeVideo();
  }
}
