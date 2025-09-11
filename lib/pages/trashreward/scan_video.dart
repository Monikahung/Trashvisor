import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:trashvisor/core/colors.dart';
import 'trashreward_page.dart';
import 'guide_video.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../globals.dart';

// Fungsi upload video ke Hugging Face
Future<Map<String, dynamic>?> _sendVideoToHuggingFace(
  String videoPath,
  String missionType,
) async {
  final dio = Dio();
  const url =
      'https://monikahung-git-detection-video-throw-garbage.hf.space/validate';

  try {
    debugPrint("Mengirim video ke Hugging Face: $videoPath");
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(videoPath, filename: 'upload.mp4'),
      'mission_type': missionType,
    });

    final response = await dio.post(
      url,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    debugPrint("Response status: ${response.statusCode}");
    if (response.statusCode == 200 && response.data != null) {
      final result = response.data as Map<String, dynamic>;
      debugPrint("Hasil dari Hugging Face: $result");
      return result;
    } else {
      debugPrint("Upload gagal, status code: ${response.statusCode}");
    }
  } on DioException catch (e) {
    debugPrint("Error saat upload video (DioException): $e");
  } catch (e) {
    debugPrint("Error tidak terduga saat upload video: $e");
  }

  return null;
}

class ScanVideo extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String missionType;
  const ScanVideo({
    super.key,
    required this.cameras,
    required this.missionType,
  });

  @override
  State<ScanVideo> createState() => _ScanVideoState();
}

class _ScanVideoState extends State<ScanVideo> {
  CameraController? _controller;
  bool _isControllerInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  bool _isRecording = false;
  bool _isLoading = false;
  Timer? _timer;
  int _secondsRecorded = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    // Check if the widget is still mounted before using context
    if (!mounted) {
      return;
    }

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      // If permissions are granted, initialize the camera
      _initializeCamera(widget.cameras.first);
    } else {
      // If permissions are denied, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin kamera dan mikrofon ditolak. Aplikasi tidak dapat merekam.',
          ),
        ),
      );
    }
  }

  // Fungsi untuk inisialisasi kamera
  void _initializeCamera(CameraDescription camera) {
    if (_controller != null) {
      return;
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller
        ?.initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isControllerInitialized = true;
          });
        })
        .catchError((e) {
          if (e is CameraException) {
            debugPrint(
              'Error saat inisialisasi kamera: ${e.code}\n${e.description}',
            );
          }
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    _controller = null;
    super.dispose();
  }

  // Fungsi untuk beralih kamera
  void _toggleCamera() async {
    if (_controller == null || !_isControllerInitialized) {
      return;
    }

    if (_isRecording) {
      await _stopVideoRecording();
    }

    final newCamera =
        (_controller!.description.lensDirection == CameraLensDirection.front)
        ? widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          )
        : widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );

    await _controller!.dispose();
    _controller = null;

    setState(() {
      _isControllerInitialized = false;
    });

    _initializeCamera(newCamera);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    final nextFlashMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    try {
      await _controller!.setFlashMode(nextFlashMode);
      setState(() => _flashMode = nextFlashMode);
    } on CameraException catch (e) {
      debugPrint('Error saat mengubah flash mode: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo) {
      return;
    }

    try {
      setState(() {
        _isRecording = true;
        _isLoading = false;
        _secondsRecorded = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRecorded >= 8) {
          _stopVideoRecording();
          timer.cancel();
        } else {
          setState(() {
            _secondsRecorded++;
          });
        }
      });

      await _controller!.startVideoRecording();
      debugPrint("Perekaman video dimulai.");
    } on CameraException catch (e) {
      debugPrint(
        "Error saat memulai perekaman video: ${e.code}\n${e.description}",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai perekaman: ${e.description}')),
      );
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      debugPrint("Controller null atau tidak dalam mode merekam.");
      return;
    }

    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isLoading = true;
    });

    try {
      debugPrint("Menghentikan perekaman video...");
      final XFile video = await _controller!.stopVideoRecording();
      debugPrint("Perekaman selesai. File: ${video.path}");

      if (!mounted) {
        debugPrint("Widget sudah unmounted setelah stop recording.");
        return;
      }

      // Snackbar berhasil merekam
      debugPrint("Menampilkan snackbar: Berhasil merekam video, tunggu notifikasi.");
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Berhasil Merekam Video. Silakan Tunggu Notifikasi'),
        ),
      );

      // Balik ke EcoRewardPage
      debugPrint("Navigasi ke EcoRewardPage...");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EcoRewardPage(cameras: widget.cameras),
        ),
      );

      // Upload video + validasi di background
      debugPrint("Mulai upload & validasi video ke Hugging Face...");
      _sendVideoToHuggingFace(video.path, widget.missionType)
          .then((result) {
            debugPrint("Respons Hugging Face diterima: $result");

            String message;
            if (result != null) {
              final isValid = result['is_valid'] ?? false;
              message = isValid
                  ? 'Validasi berhasil! Selamat Anda mendapatkan poin!'
                  : 'Validasi gagal. Objek tidak terdeteksi atau jenis tidak cocok.';
            } else {
              message = 'Gagal mendapatkan hasil dari AI. Silakan coba lagi.';
            }

            debugPrint("Menampilkan snackbar hasil validasi: $message");
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text(message)),
            );

            if (mounted) {
              debugPrint("Loading indicator dimatikan.");
              setState(() => _isLoading = false);
            }
          })
          .catchError((e) {
            debugPrint("Error saat upload/validasi: $e");
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Terjadi error saat validasi: $e')),
            );
            if (mounted) setState(() => _isLoading = false);
          });
    } on CameraException catch (e) {
      debugPrint("Error saat menghentikan perekaman video: ${e.code}\n${e.description}");
      if (mounted) {
        setState(() => _isLoading = false);
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Gagal menghentikan perekaman: ${e.description}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(context),
                Expanded(child: _buildCameraView(screenHeight, screenWidth)),
                _buildCameraControls(screenHeight, screenWidth),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.fernGreen),
                ),
              ),
            if (_isRecording)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((255 * 0.7).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Merekam maksimal 8 detik',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (_isRecording)
              Positioned(
                bottom: screenHeight * 0.35,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_secondsRecorded',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: AppColors.whiteSmoke,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.whiteSmoke),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.fernGreen,
              shape: const CircleBorder(),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.fernGreen, width: 1),
            ),
            child: InkWell(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const GuideVideo(),
              ),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Panduan',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.fernGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.help, color: AppColors.fernGreen, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView(double screenHeight, double screenWidth) {
    if (!_isControllerInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_controller!),
        CustomPaint(
          size: Size(screenWidth * 0.8, screenHeight * 0.5),
          painter: ViewfinderPainter(),
        ),
        Positioned(
          bottom: 20,
          child: Text(
            'Arahkan kamera saat membuang sampah',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls(double screenHeight, double screenWidth) {
    return Container(
      color: AppColors.whiteSmoke,
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.05,
        horizontal: screenWidth * 0.1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
              color: AppColors.fernGreen,
              size: 30,
            ),
            onPressed: _toggleFlash,
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fernGreen, width: 4),
            ),
            child: Center(
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : AppColors.fernGreen,
                ),
                child: InkWell(
                  onTap: _isRecording
                      ? _stopVideoRecording
                      : _startVideoRecording,
                  borderRadius: BorderRadius.circular(55 / 2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.cameraswitch,
              color: AppColors.fernGreen,
              size: 30,
            ),
            onPressed: _toggleCamera,
          ),
        ],
      ),
    );
  }
}

class ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.fernGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerRadius = 20.0;
    const lineLength = 50.0;
    final path = Path();

    path.moveTo(0, lineLength);
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );
    path.lineTo(lineLength, 0);

    path.moveTo(size.width - lineLength, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    path.lineTo(size.width, lineLength);

    path.moveTo(size.width, size.height - lineLength);
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: const Radius.circular(cornerRadius),
    );
    path.lineTo(size.width - lineLength, size.height);

    path.moveTo(lineLength, size.height);
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    path.lineTo(0, size.height - lineLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
