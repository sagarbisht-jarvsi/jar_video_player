import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'jar_video_player_controller.dart';

class JarVideoPlayer extends StatefulWidget {
  final JarVideoPlayerController controller;
  final String url;
  final bool autoPlay;
  final bool loop;
  final RouteObserver<ModalRoute>? routeObserver;
  final bool reelsMode;

  const JarVideoPlayer({
    super.key,
    required this.controller,
    required this.url,
    this.autoPlay = false,
    this.loop = false,
    this.routeObserver,
    this.reelsMode = false,
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

    _controller = widget.controller;
    _init();
  }

  Future<void> _init() async {
    final currentToken = ++_initToken;
    log("here");
    await _controller.initialize(
      widget.url,
      loop: widget.reelsMode ? true : widget.loop,
    );

    log("here 1");
    // If widget was disposed or another init started, ignore
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

  // ---------------------------
  // Route Handling
  // ---------------------------

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

    _controller.pause(); // 🔥 stop audio immediately
    _controller.disposeVideo(); // free decoder

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

  // ---------------------------
  // App Lifecycle
  // ---------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _safePause();
    }
  }

  // ---------------------------
  // Visibility (Reels Mode)
  // ---------------------------

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
      await _controller.pause(); // 🔥 pause immediately
    }
  }

  // ---------------------------
  // Safe Play / Pause
  // ---------------------------

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

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading || !_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final vc = _controller.videoController;

    final video = AspectRatio(
      aspectRatio: vc?.value.aspectRatio ?? 9 / 16,
      child: vc != null ? VideoPlayer(vc) : const SizedBox.shrink(),
    );

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
