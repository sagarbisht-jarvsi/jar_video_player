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

  final List<String> videoUrls = [
    "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",

  ];

  @override
  void initState() {
    super.initState();

    /// Generate 10 random pages (true = video, false = image)
    isVideoPage = List.generate(20, (_) => _random.nextBool());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        itemBuilder: (context, index) {
          if (isVideoPage[index]) {
            return _buildVideoPage(index);
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

  Widget _buildVideoPage(int index) {
    // final ctrl = JarVideoPlayerController();
    final videoUrl = videoUrls[index % videoUrls.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),

      child: JarVideoPlayer(
        url: videoUrl,
        // aspectRatio: 9/16,
        // reelsMode: true,

        // topStripe: Container(
        //   color: Colors.green,
        //   width: double.infinity,
        //   height: 50,
        //   child: Text("Hello leaders", style: TextStyle(fontSize: 37)),
        // ),
        // bottomStripe: Container(
        //   color: Colors.red,
        //   width: double.infinity,
        //   height: 70,
        //   child: Text("Hello Sagar"),
        // ),
        // onDownload: () {},
        // onShare: () {},

        ///if you want reel mode, controller is not necessary
        // controller: ctrl,
      ),

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
