import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// ===============================
/// CAPTURE OVERLAY (High Quality)
/// ===============================
Future<String?> captureOverlay(GlobalKey key, String fileName) async {
  try {
    if (key.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (key.currentContext == null) return null;
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null || boundary.size.isEmpty) return null;

    final pixelRatio = MediaQuery.of(key.currentContext!).devicePixelRatio * 2;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final Directory tempDir = await getTemporaryDirectory();
    final File imageFile = File('${tempDir.path}/${fileName}_overlay.png');

    await imageFile.writeAsBytes(pngBytes);

    return imageFile.path;
  } catch (e) {
    log("Overlay capture error: $e");
    return null;
  }
}

/// ===============================
/// DOWNLOAD VIDEO
/// ===============================
Future<String?> downloadVideo(String videoUrl) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final videoFileName = videoUrl.split('/').last.split('?').first;

    final videoFile = File('${tempDir.path}/$videoFileName');

    final response = await http.get(Uri.parse(videoUrl));

    if (response.statusCode == 200) {
      await videoFile.writeAsBytes(response.bodyBytes);
      return videoFile.path;
    } else {
      return null;
    }
  } catch (e) {
    log("Download error: $e");
    return null;
  }
}

/// ===============================
/// GET VIDEO RESOLUTION (FFprobe)
/// ===============================

Future<Map<String, int>?> getVideoResolution(String videoPath) async {
  final session = await FFprobeKit.execute(
    '-v quiet -print_format json -show_streams "$videoPath"',
  );

  final output = await session.getOutput();
  if (output == null) return null;

  final Map<String, dynamic> jsonData = jsonDecode(output);

  final videoStream = jsonData['streams']
      .firstWhere((stream) => stream['codec_type'] == 'video');

  return {
    'width': videoStream['width'],
    'height': videoStream['height'],
  };
}

/// ===============================
/// MERGE VIDEO + OVERLAY (Optimal)
/// ===============================

Future<String?> mergeVideoWithOverlay(
  String videoPath,
  String bottomOverlayPath, {
  String? topOverlayPath,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final outputPath =
        "${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4";

    final resolution = await getVideoResolution(videoPath);

    if (resolution == null) {
      log("Could not detect video resolution");
      return null;
    }

    final int videoWidth = resolution['width']!;
    final int videoHeight = resolution['height']!;
    String? command;
    String? filterComplex;
    if (topOverlayPath != null) {
      filterComplex =
          // Scale top overlay
          "[1:v]scale=$videoWidth:-1[top];"

          // Scale bottom overlay
          "[2:v]scale=$videoWidth:-1[bottom];"

          // Stack top + video vertically
          "[top][0:v]vstack=inputs=2[v1];"

          // Overlay bottom at bottom of stacked result
          "[v1][bottom]overlay=0:H-h[v]";

      command = "-y "
          "-i \"$videoPath\" "
          "-i \"$topOverlayPath\" "
          "-i \"$bottomOverlayPath\" "
          "-filter_complex \"$filterComplex\" "
          "-map \"[v]\" "
          "-map 0:a? "
          "-c:v libx264 "
          "-preset veryfast "
          "-crf 18 "
          "-pix_fmt yuv420p "
          "-movflags +faststart "
          "-c:a copy "
          "-shortest "
          "\"$outputPath\"";
    } else {
      /// Scale overlay to video width (maintain aspect ratio)

      filterComplex = "[1:v]scale=$videoWidth:-1[bottom];"
          "[0:v][bottom]overlay=0:H-h[v]";

      command = "-y "
          "-i \"$videoPath\" "
          "-i \"$bottomOverlayPath\" "
          "-filter_complex \"$filterComplex\" "
          "-map \"[v]\" "
          "-map 0:a? "
          "-c:v libx264 "
          "-preset veryfast "
          "-crf 18 "
          "-pix_fmt yuv420p "
          "-movflags +faststart "
          "-c:a copy "
          "-shortest "
          "\"$outputPath\"";

      // filterComplex = "[1:v]scale=$videoWidth:-1:flags=lanczos[overlay];"
      //     "[0:v][overlay]overlay=0:$videoHeight-h[v]";
      //
      // command = "-y "
      //     "-i \"$videoPath\" "
      //     "-i \"$bottomOverlayPath\" "
      //     "-filter_complex \"$filterComplex\" "
      //     "-map \"[v]\" "
      //     "-map 0:a? "
      //     "-c:v libx264 "
      //     "-preset veryfast "
      //     "-crf 18 "
      //     "-pix_fmt yuv420p "
      //     "-movflags +faststart "
      //     "-c:a copy "
      //     "-shortest "
      //     "\"$outputPath\"";
    }

    final session = await FFmpegKit.execute(command!);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath).existsSync() ? outputPath : null;
    } else {
      final logs = await session.getAllLogs();
      for (var log in logs) {
        print(log.getMessage());
      }
      return null;
    }
  } catch (e) {
    log("Merge error: $e");
    return null;
  }
}

/// ===============================
/// COMPLETE EXPORT FLOW
/// ===============================
Future<String?> exportFinalVideo(
  String url,
  GlobalKey overlayKey,
) async {
  final videoPath = await downloadVideo(url);
  if (videoPath == null) {
    log("Video download failed");
    return null;
  }

  final overlayPath = await captureOverlay(
    overlayKey,
    DateTime.now().millisecondsSinceEpoch.toString(),
  );

  if (overlayPath == null) {
    log("Overlay capture failed");
    return null;
  }

  final finalPath = await mergeVideoWithOverlay(videoPath, overlayPath);

  if (finalPath != null) {
    log("Export success: $finalPath");
  } else {
    log("Export failed");
  }

  return finalPath;
}

/// ===============================
/// SHARE VIDEO
/// ===============================
Future<void> shareVideo(String path) async {
  await Share.shareXFiles(
    [
      XFile(
        path,
        mimeType: "video/mp4",
      )
    ],
    text: "Check this out!",
  );
}
