import 'dart:async';
import 'dart:io';

import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = '';
  double _exportProgress = 0.0;
  String? _filePath;
  VideoPlayerController? _controller;

  @override
  dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(String path) {
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _controller?.setLooping(true);
        _controller?.play();
      });
  }

  Future<void> _uploadFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? galleryVideo =
          await picker.pickVideo(source: ImageSource.gallery);
      if (galleryVideo != null) {
        setState(() {
          _filePath = galleryVideo.path;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _trimAndSpeed() async {
    try {
      final editor = VideoEditorBuilder(videoPath: _filePath!)
          .trim(startTimeMs: 0, endTimeMs: 5000) // Cắt 5 giây đầu
          .speed(speed: 1.5); // Tăng tốc độ 1.5x

      final result = await editor.export();
      setState(() {
        _status = 'Video processed: $result';
      });
      if (result != null) {
        _initVideoPlayer(result);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _removeAudio() async {
    try {
      final editor = VideoEditorBuilder(videoPath: _filePath!).removeAudio();

      final result = await editor.export();
      setState(() {
        _status = 'Audio removed: $result';
      });
      if (result != null) {
        _initVideoPlayer(result);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _getMetadata() async {
    try {
      final editor = VideoEditorBuilder(videoPath: _filePath!);

      final metadata = await editor.getVideoMetadata();
      setState(() {
        _status = 'Metadata: $metadata';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _cropAndRotate() async {
    try {
      final editor = VideoEditorBuilder(videoPath: _filePath!)
          .crop(
              aspectRatio:
                  VideoAspectRatio.ratio16x9) // Crop to widescreen format
          .rotate(degree: RotationDegree.degree90);

      final result = await editor.export();
      setState(() {
        _status = 'Video transformed: $result';
      });
      if (result != null) {
        _initVideoPlayer(result);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final editor = VideoEditorBuilder(videoPath: _filePath!);
      final result =
          await editor.generateThumbnail(positionMs: 1000, quality: 85);
      setState(() {
        _status = 'Thumbnail generated: $result';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _compresWithProgress() async {
    try {
      // Reset progress
      setState(() {
        _exportProgress = 0.0;
        _status = 'Starting export with progress tracking...';
      });

      final editor = VideoEditorBuilder(videoPath: _filePath!)
         // .trim(startTimeMs: 1000, endTimeMs: 10000)
          .compress(resolution: VideoResolution.p720);

      final result = await editor.export(onProgress: (progress) {
        // Update progress state
        setState(() {
          _exportProgress = progress;
          _status = 'Export progress: ${(progress * 100).toStringAsFixed(1)}%';
        });
      });

      setState(() {
        _status = 'Export completed: $result';
      });
      if (result != null) {
        _initVideoPlayer(result);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor Builder Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('File path : $_filePath',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadFile,
                child: const Text('Upload file'),
              ),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _filePath != null ? _trimAndSpeed : null,
                child: const Text('Trim & Speed Up'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _filePath != null ? _removeAudio : null,
                child: const Text('Remove Audio'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _filePath != null ? _cropAndRotate : null,
                child: const Text('Crop & Rotate'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _filePath != null ? _generateThumbnail : null,
                child: const Text('Generate Thumbnail'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _filePath != null ? _getMetadata : null,
                child: const Text('Get metadata'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _filePath != null ? _compresWithProgress : null,
                child: const Text('Compress with Progress'),
              ),
              const SizedBox(height: 10),
              // Progress indicator
              if (_exportProgress > 0)
                Column(
                  children: [
                    LinearProgressIndicator(value: _exportProgress),
                    const SizedBox(height: 5),
                    Text('${(_exportProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              if (_controller != null &&
                  _controller?.value.isInitialized == true)
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
