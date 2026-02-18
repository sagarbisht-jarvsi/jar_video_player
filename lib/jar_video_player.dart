/// A modern, customizable network video player for Flutter.
///
/// Supports:
/// - Network video playback
/// - Reels mode (auto play/pause on visibility)
/// - Manual playback controls
/// - Looping
///
/// Example:
/// ```dart
/// final controller = JarVideoPlayerController();
///
/// JarVideoPlayer(
///   url: "https://example.com/video.mp4",
///   controller: controller,
/// )
/// ```


library;

export 'src/jar_video_player_widget.dart';
export 'helper/jar_video_player_controller.dart';
export 'src/jar_overlay_video_widget.dart';
export 'helper/overlay_animation_type.dart';
