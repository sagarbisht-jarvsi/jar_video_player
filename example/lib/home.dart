import 'dart:math';
import 'package:example/test_class.dart';
import 'package:flutter/material.dart';
import 'package:jar_video_player/jar_video_player.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PageController _pageController = PageController();
  final Random _random = Random();

  late List<bool> isVideoPage;

  @override
  void initState() {
    super.initState();

    // Generate 10 random pages (true = video, false = image)
    isVideoPage = List.generate(10, (_) => _random.nextBool());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TestClass()),
          );
        },
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: isVideoPage.length,
        onPageChanged: (value) {},
        itemBuilder: (context, index) {
          if (isVideoPage[index]) {
            return _buildVideoPage();
          } else {
            return _buildImagePage();
          }
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.next_plan_outlined),
                title: const Text("Go to Test Page"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TestClass()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPage() {
    final ctrl = JarVideoPlayerController();
    return JarVideoPlayer(
      url:
          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      // only works manually only and only  if reelsMode is set to false (default is false),
      autoPlay: false,
      loop: false,
      controller: ctrl,
      reelsMode: true,
      // routeObserver: routeObserver,
    );
  }

  Widget _buildImagePage() {
    return Image.network(
      "https://picsum.photos/600/900?random=${_random.nextInt(1000)}",
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
    );
  }
}
