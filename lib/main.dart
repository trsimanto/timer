import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'functions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerApp(),
    );
  }
}

class TimerApp extends StatefulWidget {
  @override
  _TimerAppState createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  final ScreenshotController screenshotController = ScreenshotController();
  List<Uint8List> _imagesList = [];
  Timer? _timer;
  int _elapsedTime = 0; // Track elapsed time in seconds
  bool _isRunning = false;
  CameraMacOSController? macOSController;
  GlobalKey cameraKey = GlobalKey();
  List<String> captureImagePathList = [];
  String? selectedVideoDevice;

  @override
  void initState() {
    super.initState();
    listVideoDevices(context).then((value) {
      selectedVideoDevice = value;
      if(mounted)
      setState(() {});
    }


    );
  }

  void _startPauseTimer() {
    if (_isRunning) {
      // Pause the timer
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      // Start the timer
      _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
        takePhoto(macOSController,context).then((value) {
          setState(() {
            if (value != null) captureImagePathList.add(value);
          });
        });
        // Capture the screenshot
        final Uint8List? image = await screenshotController.capture();
        if (image != null) {
          setState(() {
            _imagesList.add(image);
            _elapsedTime++; // Increment elapsed time
          });
        }
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _imagesList.clear();
      captureImagePathList.clear();
      _elapsedTime = 0; // Reset elapsed time
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture screenshots and Images every second'),
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Column(
          children: [
            if (selectedVideoDevice != null && selectedVideoDevice!.isNotEmpty)
              Container(
                  width: 200,
                  height: 200 * (9 / 16),
                  child: CameraMacOSView(
                    key: cameraKey,
                    deviceId: selectedVideoDevice,
                    fit: BoxFit.fitWidth,
                    cameraMode: CameraMacOSMode.photo,
                    onCameraInizialized: (CameraMacOSController controller) {
                      setState(() {
                        macOSController = controller;
                      });
                    },
                  )),
            Text(
              'Elapsed Time: $_elapsedTime seconds',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startPauseTimer,
                  child: Text(_isRunning ? 'Pause' : 'Start'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _reset,
                  child: Text('Reset'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_imagesList.isNotEmpty)
              Row(
                children: [
                  Text(
                    'Screen Sorts',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            Container(
              height: 100, // Height of the image list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagesList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(
                      _imagesList[index],
                      height: 100, // Height of each image
                      fit: BoxFit.fitHeight,
                    ),
                  );
                },
              ),
            ),
            if (captureImagePathList.isNotEmpty)
              Row(
                children: [
                  Text(
                    'Headshots',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: captureImagePathList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        openPicture(captureImagePathList[index]);
                      },
                      child: Image.file(
                        File(captureImagePathList[index]),
                        height: 100,  // Height of each image
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}