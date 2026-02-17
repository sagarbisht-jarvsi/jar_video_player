# jar_video_player

A modern, reels-ready, customizable network video player for Flutter.

`jar_video_player` is built for real-world performance. It provides
automatic lifecycle handling, route awareness, visibility-based playback
control, and optimized support for vertical reel-style feeds like
Instagram or TikTok.


https://github.com/user-attachments/assets/f1f8e44a-3425-4870-aa0e-35beab325ad8


------------------------------------------------------------------------

## ✨ Features

-   🎥 Network video playback
-   🔁 Reels mode (auto play/pause based on visibility)
-   🔄 Route-aware auto pause
-   📱 App lifecycle handling (background/foreground safety)
-   🎛 External controller support
-   ⚡ Optimized for `PageView` reels
-   🧠 Safe async initialization (prevents ghost audio issues)
-   🧹 Proper resource disposal to prevent memory leaks

------------------------------------------------------------------------

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

``` yaml
dependencies:
  jar_video_player: ^0.1.2
```

Then run:

``` bash
flutter pub get
```

------------------------------------------------------------------------

## 🚀 Overlya Jar Video Player

``` dart
import 'package:flutter/material.dart';
import 'package:jar_video_player/jar_video_player.dart';

final controller = JarVideoPlayerController();

JarVideoPlayerOverlay(
        url: videoUrl,
        aspectRatio: 9 / 16,
        reelsMode: true,

        ///top overlay widget
        // topStripe: Container(
        //   color: Colors.green,
        //   width: double.infinity,
        //   height: 50,
        //   child: Text("Hello leaders", style: TextStyle(fontSize: 37)),
        // ),

        /// this is bottom overlay
        bottomStripe: Container(
          color: Colors.red,
          width: double.infinity,
          height: 70,
          child: Text("Hello Sagar"),
        ),

        /// if you want custom downlaod or share functions
        // onDownload: () {},
        // onShare: () {},

        ///if you want reel mode, controller is not necessary
        // controller: ctrl,
      ),
    );
```

------------------------------------------------------------------------

## 🎬 Reels Mode

Reels mode automatically plays the video when it becomes visible and
pauses it when it goes out of view.

``` dart
JarVideoPlayer(
  controller: controller,
  url: videoUrl,
  reelsMode: true,
);
```

### Recommended Usage with PageView

``` dart
PageView.builder(
  scrollDirection: Axis.vertical,
  itemCount: videoList.length,
  itemBuilder: (context, index) {
    final controller = JarVideoPlayerController();

    return JarVideoPlayer(
      controller: controller,
      url: videoList[index],
      reelsMode: true,
    );
  },
);
```

------------------------------------------------------------------------

## 🎛 Controller API

You can control playback manually using the controller:

``` dart
controller.play();
controller.pause();
controller.seekTo(Duration(seconds: 10));
controller.dispose();
```

------------------------------------------------------------------------

## 🔄 Lifecycle & Route Handling

`jar_video_player` automatically:

-   Pauses when navigating to a new route
-   Pauses when app goes to background
-   Resumes safely when returning
-   Prevents audio leaks during fast scroll

------------------------------------------------------------------------

## 🧩 Best Practices

-   Dispose controllers properly when no longer needed.
-   Use `reelsMode: true` inside `PageView` for best performance.
-   Avoid initializing multiple heavy videos simultaneously on low-end
    devices.

------------------------------------------------------------------------

## 📚 Example

A complete working example is available inside the `example/` folder of
this package.

------------------------------------------------------------------------

## 🛠 Requirements

-   Flutter 3.10+
-   Dart \>=3.0.0 \<4.0.0

------------------------------------------------------------------------

## 📝 License

MIT License

Copyright (c) 2026 Sagar

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish the Software.




