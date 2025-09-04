import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // import package dio
import 'package:flutter/foundation.dart'; // import untuk menggunakan compute()
import 'package:trashvisor/core/colors.dart';
import 'guide_camera.dart';
import 'result_scan.dart';

// Fungsi upload gambar ke Hugging Face
Future<Map<String, dynamic>?> _sendImageToHuggingFace(String imagePath) async {
  final dio = Dio();
  const url = 'https://monikahung-yolo-trash-endpoint.hf.space/predict'; // endpoint dari HF

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(imagePath, filename: 'upload.png'),
  });

  try {
    debugPrint("Mengirim gambar ke Hugging Face: $imagePath");
    final response = await dio.post(
      url,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
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
    debugPrint("Error saat upload gambar: $e");
  } catch (e) {
    debugPrint("Error unexpected: $e");
  }

  return null;
}

class ScanCamera extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanCamera({super.key, required this.cameras});

  @override
  State<ScanCamera> createState() => _ScanCameraState();
}

class _ScanCameraState extends State<ScanCamera> {
  late CameraController _controller;
  final ImagePicker _picker = ImagePicker();

  bool _isControllerInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isControllerInitialized = true;
      });
    }).catchError((e) {
      if (e is CameraException) {
        debugPrint('Error saat inisialisasi kamera: ${e.code}\n${e.description}');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (!_controller.value.isInitialized) return;

    final nextFlashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;

    try {
      await _controller.setFlashMode(nextFlashMode);
      setState(() {
        _flashMode = nextFlashMode;
      });
    } on CameraException catch (e) {
      debugPrint('Error saat mengubah flash mode: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;

    setState(() => _isLoading = true);

    debugPrint("Memulai upload gambar dari gallery: ${image.path}");
    final result = await compute(_sendImageToHuggingFace, image.path);
    debugPrint("Hasil upload gallery: $result");

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      // Navigasi ke ResultScan tanpa dispose kamera dulu
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScan(
            scannedImagePath: image.path,
            aiResult: result,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan hasil dari AI. Silakan coba lagi.')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) return;

    setState(() => _isLoading = true);

    try {
      final XFile picture = await _controller.takePicture();
      if (!mounted) return;

      debugPrint("Memulai upload gambar dari kamera: ${picture.path}");
      final result = await compute(_sendImageToHuggingFace, picture.path);
      debugPrint("Hasil upload kamera: $result");

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        // Navigasi ke ResultScan tanpa dispose kamera dulu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScan(
              scannedImagePath: picture.path,
              aiResult: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan hasil dari AI. Silakan coba lagi.')),
        );
      }
    } on CameraException catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error saat ambil foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error kamera: ${e.code}')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error unexpected: $e");
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
                builder: (_) => const GuideCamera(),
              ),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text('Panduan',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: AppColors.fernGreen,
                            fontWeight: FontWeight.bold)),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isControllerInitialized)
          CameraPreview(_controller)
        else
          const Center(child: CircularProgressIndicator()),
        CustomPaint(
          size: Size(screenWidth * 0.8, screenHeight * 0.5),
          painter: ViewfinderPainter(),
        ),
        Positioned(
          bottom: 20,
          child: Text(
            'Arahkan kamera ke sampah untuk identifikasi',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
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
          vertical: screenHeight * 0.05, horizontal: screenWidth * 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.folder, color: AppColors.fernGreen, size: 30),
            onPressed: _pickImageFromGallery,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fernGreen,
                ),
                child: InkWell(onTap: _takePicture, borderRadius: BorderRadius.circular(55 / 2)),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                color: AppColors.fernGreen,
                size: 30),
            onPressed: _toggleFlash,
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

    // Sudut kiri atas
    path.moveTo(0, lineLength);
    path.lineTo(0, cornerRadius);
    path.arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius));
    path.lineTo(lineLength, 0);

    // Sudut kanan atas
    path.moveTo(size.width - lineLength, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(Offset(size.width, cornerRadius), radius: const Radius.circular(cornerRadius));
    path.lineTo(size.width, lineLength);

    // Sudut kanan bawah
    path.moveTo(size.width, size.height - lineLength);
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(Offset(size.width - cornerRadius, size.height), radius: const Radius.circular(cornerRadius));
    path.lineTo(size.width - lineLength, size.height);

    // Sudut kiri bawah
    path.moveTo(lineLength, size.height);
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(Offset(0, size.height - cornerRadius), radius: const Radius.circular(cornerRadius));
    path.lineTo(0, size.height - lineLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}