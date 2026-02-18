import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../helper/jar_video_player_controller.dart';

/// A customizable video player widget for playing network videos.
///
/// Supports reels-style auto play/pause, looping, and manual control.
///
/// Requires a [JarVideoPlayerController] to control playback.

class JarVideoPlayer extends StatefulWidget {
  /// This is for pausing and playing the video if routes changes!!!
  final RouteObserver<ModalRoute>? routeObserver;

  /// Network video URL to play.
  final String url;

  /// Controller used to control playback (play, pause, etc).
  final JarVideoPlayerController? controller;

  /// Whether video should auto play when initialized.
  ///
  /// Defaults to false.
  final bool autoPlay;

  /// custom aspect ratio.
  /// default value is 9/16
  final double? aspectRatio;

  /// Whether the video should loop after completion.
  ///
  /// Defaults to false.
  final bool loop;

  /// Enables reels-style behavior.
  ///
  /// When true, video auto plays and pauses based on visibility.
  final bool reelsMode;

  /// Creates a [JarVideoPlayer].
  ///
  /// The [url] parameter is required and must be a valid network video URL.
  ///
  /// The [controller] is optional to control playback.
  ///
  /// If [reelsMode] is true, the video automatically plays
  /// when visible and pauses when not visible.
  ///

  const JarVideoPlayer({
    super.key,
    this.controller,
    required this.url,
    this.autoPlay = false,
    this.loop = false,
    this.routeObserver,
    this.reelsMode = false,
    this.aspectRatio,
  });
  @override
  State<JarVideoPlayer> createState() => _JarVideoPlayerState();
}

class _JarVideoPlayerState extends State<JarVideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  late final JarVideoPlayerController _controller;
  bool _disposed = false;
  int _initToken = 0;
  bool _loading = true;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = widget.controller ?? JarVideoPlayerController();
    _init();
  }

  Future<void> _init() async {
    final currentToken = ++_initToken;
    await _controller.initialize(
      widget.url,
      loop: widget.reelsMode ? true : widget.loop,
    );

    /// If widget was disposed or another init started, ignore
    if (!mounted || _disposed || currentToken != _initToken) {
      await _controller.disposeVideo();
      return;
    }

    if (widget.reelsMode) {
      // Only play if visible
      if (_isVisible) {
        _controller.play();
      }
    } else if (widget.autoPlay) {
      _controller.play();
    }

    setState(() {
      _loading = false;
    });
  }

  /// ---------------------------
  /// Route Handling
  /// ---------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.routeObserver != null) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        widget.routeObserver!.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;

    _controller.pause();

    /// 🔥 stop audio immediately
    _controller.disposeVideo();

    /// free decoder

    if (widget.routeObserver != null) {
      widget.routeObserver!.unsubscribe(this);
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _safePause();
  }

  @override
  void didPopNext() {
    if (widget.autoPlay || widget.reelsMode) {
      _safePlay();
    }
  }

  /// ---------------------------
  ///App Lifecycle
  ///---------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.isInitialized) return;

    ///automatically pause when the screen is not in focus or is not visible
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _safePause();
    }

    ///automatically play the video if it comes back to focus or is visible.

    else if (state == AppLifecycleState.resumed) {
      if (widget.autoPlay || widget.reelsMode) {
        _safePlay();
      }
    }
  }

  ///---------------------------
  ///Visibility (Reels Mode)
  ///---------------------------

  Future<void> _handleVisibility(double visibleFraction) async {
    if (!widget.reelsMode || _disposed) return;

    final isNowVisible = visibleFraction > 0.6;

    if (isNowVisible == _isVisible) return;

    _isVisible = isNowVisible;

    if (_isVisible) {
      if (!_controller.isInitialized) {
        await _init();
      } else {
        _controller.play();
      }
    } else {
      await _controller.pause();

      ///🔥 pause immediately
    }
  }

  ///---------------------------
  ///Safe Play / Pause
  ///---------------------------

  void _safePlay() {
    if (!_controller.isInitialized) return;
    if (_controller.isPlaying) return;

    _controller.play();
  }

  void _safePause() {
    if (!_controller.isInitialized) return;
    if (!_controller.isPlaying) return;

    _controller.pause();
  }

  void _togglePlayPause() {
    if (!_controller.isInitialized) return;

    if (_controller.isPlaying) {
      _safePause();
    } else {
      _safePlay();
    }

    setState(() {});
  }

  ///---------------------------
  ///UI
  ///---------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading || !_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // final vc = _controller.videoController;
    //
    // final video = AspectRatio(
    //   aspectRatio: widget.aspectRatio ?? vc?.value.aspectRatio ?? 9 / 16,
    //   child: vc != null ? VideoPlayer(vc) : const SizedBox.shrink(),
    // );
    final vc = _controller.videoController;

    Widget video;

    if (widget.reelsMode) {
      video = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: vc!.value.size.width,
            height: vc.value.size.height,
            child: VideoPlayer(vc),
          ),
        ),
      );
    } else {
      // 🎥 Normal Aspect Ratio Mode
      video = AspectRatio(
        aspectRatio: widget.aspectRatio ?? vc!.value.aspectRatio,
        child: VideoPlayer(vc!),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        widget.reelsMode
            ? VisibilityDetector(
                key: ValueKey(widget.url),
                onVisibilityChanged: (info) {
                  _handleVisibility(info.visibleFraction);
                },
                child: video,
              )
            : video,
        if (!widget.reelsMode)
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _controller.isPlaying ? 0 : 1,
              child: const Icon(
                Icons.play_circle_fill,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
