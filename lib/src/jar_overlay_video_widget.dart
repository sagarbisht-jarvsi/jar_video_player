import 'package:flutter/material.dart';
import 'package:jar_video_player/src/utils.dart';
import 'package:jar_video_player/src/video_export_service.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../jar_video_player.dart';

class JarVideoPlayerOverlay extends StatefulWidget {
  final String url;
  final JarVideoPlayerController? controller;
  final Widget? bottomStripe;
  final Widget? topStripe;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final double right;
  final bool reelsMode;
  final bool autoPlay;
  final bool loop;
  final double aspectRatio;

  const JarVideoPlayerOverlay({
    super.key,
    required this.url,
    this.controller,
    this.bottomStripe,
    this.onDownload,
    this.onShare,
    this.reelsMode = false,
    this.autoPlay = false,
    this.loop = false,
    this.right = 12,
    this.topStripe,
    this.aspectRatio = 9 / 16,
  });

  @override
  State<JarVideoPlayerOverlay> createState() => _JarVideoPlayerOverlayState();
}

class _JarVideoPlayerOverlayState extends State<JarVideoPlayerOverlay> {
  final GlobalKey _bottomOverlayKey = GlobalKey();
  final GlobalKey _topOverlayKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _handleDownload() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
          videoUrl: widget.url,
          bottomOverlayKey: _bottomOverlayKey,
          downloadWithOverlay: widget.bottomStripe != null,
          topOverlayKey: widget.topStripe == null ? null : _topOverlayKey);

      if (path != null) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = "Overlay Video";

        await MediaStore().saveFile(
          tempFilePath: path,
          dirType: DirType.video,
          dirName: DirName.movies,
        );
      }
    } catch (e) {
      throw e.toString();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await exportVideoWithOverlay(
          videoUrl: widget.url,
          bottomOverlayKey: _bottomOverlayKey,
          downloadWithOverlay: widget.bottomStripe != null,
          topOverlayKey: widget.topStripe == null ? null : _topOverlayKey);

      if (path != null) {
        await shareVideo(path);
        widget.onShare?.call(); // optional external callback
      }
    } catch (e) {
      throw e.toString();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// top overlay Overlay

        if (widget.topStripe != null)
          RepaintBoundary(
            key: _topOverlayKey,
            child: widget.topStripe!,
          ),

        Expanded(
          child: Stack(
            children: [
              /// Video / Image (Full Screen Cover)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                  ),
                  child: JarVideoPlayer(
                    url: widget.url,
                    controller: widget.controller,
                    reelsMode: widget.reelsMode,
                    autoPlay: widget.autoPlay,
                    loop: widget.loop,
                    // aspectRatio: ,
                  ),
                ),
              ),

              /// Bottom Overlay
              if (widget.bottomStripe != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RepaintBoundary(
                    key: _bottomOverlayKey,
                    child: widget.bottomStripe!,
                  ),
                ),

              /// Buttons (center right)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.download,
                        onTap: _handleDownload,
                        disabled: _isProcessing,
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        icon: Icons.share,
                        onTap: _handleShare,
                        disabled: _isProcessing,
                      ),
                    ],
                  ),
                ),
              ),

              /// Loader
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black54,
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
