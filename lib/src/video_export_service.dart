import 'package:flutter/material.dart';
import 'package:jar_video_player/src/utils.dart';

Future<String?> exportVideoWithOverlay({
  bool downloadWithOverlay = false,
  required String videoUrl,
  required GlobalKey bottomOverlayKey,
  GlobalKey? topOverlayKey,
}) async {
  try {
    /// 1️⃣ Download original video
    final videoPath = await downloadVideo(videoUrl);

    if (!downloadWithOverlay) {
      return videoPath;
    }

    /// 2️⃣ Capture overlay as image
    final overlayPath = await captureOverlay(bottomOverlayKey, "bottomOverlay");
    if (topOverlayKey != null) {
      final topOverPath = await captureOverlay(topOverlayKey, "topOverlay");

      /// 3️⃣ Merge with FFmpeg both top and bottom overlay
      if (videoPath != null) {
        final finalVideo = await mergeVideoWithOverlay(
          videoPath,
          overlayPath!,
          topOverlayPath: topOverPath,
        );
        return finalVideo;
      }
    } else {
      /// 3️⃣ Merge with FFmpeg
      if (videoPath != null) {
        final finalVideo = await mergeVideoWithOverlay(videoPath, overlayPath!);
        return finalVideo;
      }
    }
  } catch (e) {
    return null;
  }
  return null;
}
