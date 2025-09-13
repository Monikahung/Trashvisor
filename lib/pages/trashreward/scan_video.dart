import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'guide_video.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../globals.dart';

final supabase = Supabase.instance.client;

void _showCustomSnackbar(String message, Color color, IconData icon) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

String _yyyyMmDd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<Map<String, dynamic>?> _sendVideoToHuggingFace(
  String videoPath,
  String missionType,
) async {
  final dio = Dio();
  const url = 'https://monikahung-git-detection-video-throw-garbage.hf.space/validate';

  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(videoPath, filename: 'upload.mp4'),
      'mission_type': missionType,
    });

    final response = await dio.post(
      url,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) return response.data;
      if (response.data is String) {
        final decoded = jsonDecode(response.data);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    }
  } catch (e) {
    debugPrint("Upload/validate error: $e");
  }
  return null;
}

class ScanVideo extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String missionType;
  final String missionKey;                  // agar status “xxx:<key>”
  final String? reuseRowId;                 // NEW: id row 'failed' yang mau di-reuse (boleh null)
  final void Function(bool isValid) onValidationComplete;

  const ScanVideo({
    super.key,
    required this.cameras,
    required this.missionType,
    required this.missionKey,
    required this.onValidationComplete,
    this.reuseRowId,
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

  // NEW: simpan id baris yang lagi dipakai (reused / inserted)
  String? _rowIdInUse;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    if (!mounted) return;

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      _initializeCamera(widget.cameras.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera & mikrofon ditolak.')),
      );
    }
  }

  void _initializeCamera(CameraDescription camera) {
    if (_controller != null) return;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller?.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isControllerInitialized = true);
    }).catchError((e) {
      debugPrint('Camera init error: $e');
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    _controller = null;
    super.dispose();
  }

  void _toggleCamera() async {
    if (_controller == null || !_isControllerInitialized) return;
    if (_isRecording) await _stopVideoRecording();

    final newCamera =
        (_controller!.description.lensDirection == CameraLensDirection.front)
            ? widget.cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back)
            : widget.cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

    await _controller!.dispose();
    _controller = null;
    setState(() => _isControllerInitialized = false);
    _initializeCamera(newCamera);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo) return;

    try {
      setState(() {
        _isRecording = true;
        _isLoading = false;
        _secondsRecorded = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_secondsRecorded >= 8) {
          _stopVideoRecording();
          t.cancel();
        } else {
          setState(() => _secondsRecorded++);
        }
      });

      await _controller!.startVideoRecording();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mulai rekam: $e')),
      );
    }
  }

  /// NEW: tulis `processing:<key>` dengan REUSE row gagal jika ada.
  Future<void> _markProcessing() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final todayStr = _yyyyMmDd(DateTime.now());
    final processing = 'processing:${widget.missionKey}';
    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      // Kalau dikasih reuseRowId -> update row itu jadi 'processing'
      if (widget.reuseRowId != null && widget.reuseRowId!.isNotEmpty) {
        final updated = await supabase
            .from('mission_history')
            .update({'status': processing, 'created_at': nowIso})
            .eq('id', widget.reuseRowId!) // non-null !
            .select('id')
            .maybeSingle();

        if (updated != null) {
          _rowIdInUse = (updated['id'] ?? widget.reuseRowId!).toString();
          return;
        }
        // Jika entah kenapa update gagal, fallback ke insert di bawah.
      }

      // Insert baris baru processing
      final inserted = await supabase
          .from('mission_history')
          .insert({
            'user_id': user.id,
            'mission_date': todayStr,
            'status': processing,
            'created_at': nowIso,
          })
          .select('id')
          .maybeSingle();

      _rowIdInUse = (inserted?['id'] ?? '').toString();
    } catch (e) {
      debugPrint('markProcessing error: $e');
    }
  }

  /// NEW: transisi processing → completed/failed di ROW YANG SAMA bila _rowIdInUse ada.
  Future<void> _transitionProcessing({required bool success}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final todayStr = _yyyyMmDd(DateTime.now());
    final toStatus = success ? 'completed:${widget.missionKey}' : 'failed:${widget.missionKey}';

    try {
      if (_rowIdInUse != null && _rowIdInUse!.isNotEmpty) {
        await supabase
            .from('mission_history')
            .update({'status': toStatus})
            .eq('id', _rowIdInUse!) // non-null !
            .select('id')
            .maybeSingle();
        return;
      }

      // Fallback lama (jaga-jaga)
      await supabase
          .from('mission_history')
          .update({'status': toStatus})
          .match({
            'user_id': user.id,
            'mission_date': todayStr,
            'status': 'processing:${widget.missionKey}',
          })
          .select('id');
    } catch (e) {
      debugPrint('transitionProcessing error: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _timer?.cancel();
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isLoading = true;
    });

    try {
      final XFile video = await _controller!.stopVideoRecording();

      // 1) tandai processing (REUSE row bila ada)
      await _markProcessing();

      // 2) Snackbar info & kembali ke parent → parent ubah tombol ke "Proses"
      _showCustomSnackbar(
        'Berhasil merekam. Validasi sedang diproses...',
        Colors.blue,
        Icons.cloud_upload_outlined,
      );
      Navigator.pop(context, true);

      // 3) Upload + validasi (background)
      unawaited(
        _sendVideoToHuggingFace(video.path, widget.missionType).then((result) async {
          final isValid = (result != null && result['status'] == 'valid');

          await _transitionProcessing(success: isValid);

          _showCustomSnackbar(
            isValid
                ? 'Validasi berhasil! Silakan klaim poin.'
                : 'Validasi gagal. Coba rekam lagi.',
            isValid ? AppColors.fernGreen : Colors.red,
            isValid ? Icons.check_circle_outline : Icons.error_outline,
          );

          widget.onValidationComplete(isValid);
        }).catchError((e) async {
          await _transitionProcessing(success: false);
          _showCustomSnackbar('Terjadi error saat validasi.', Colors.red, Icons.error_outline);
          widget.onValidationComplete(false);
        }),
      );
    } catch (e) {
      if (mounted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Gagal stop rekam: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(context),
                Expanded(child: _buildCameraView(h, w)),
                _buildCameraControls(h, w),
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
                top: 100, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((255 * 0.7).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Merekam maksimal 8 detik',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (_isRecording)
              Positioned(
                bottom: h * 0.35, left: 0, right: 0,
                child: Center(
                  child: Text(
                    '$_secondsRecorded',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
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
                    Text('Panduan',
                      style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14,
                        color: AppColors.fernGreen, fontWeight: FontWeight.bold,
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

  Widget _buildCameraView(double h, double w) {
    if (!_isControllerInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_controller!),
        CustomPaint(size: Size(w * 0.8, h * 0.5), painter: ViewfinderPainter()),
        const Positioned(
          bottom: 20,
          child: Text(
            'Arahkan kamera saat membuang sampah',
            style: TextStyle(
              fontFamily: 'Roboto', fontSize: 14, color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls(double h, double w) {
    return Container(
      color: AppColors.whiteSmoke,
      padding: EdgeInsets.symmetric(vertical: h * 0.05, horizontal: w * 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(_flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
              color: AppColors.fernGreen, size: 30),
            onPressed: _toggleFlash,
          ),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.fernGreen, width: 4)),
            child: Center(
              child: Container(
                width: 55, height: 55,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _isRecording ? Colors.red : AppColors.fernGreen),
                child: InkWell(
                  onTap: _isRecording ? _stopVideoRecording : _startVideoRecording,
                  borderRadius: BorderRadius.circular(55 / 2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: AppColors.fernGreen, size: 30),
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

    const r = 20.0;
    const l = 50.0;
    final p = Path();

    p.moveTo(0, l); p.lineTo(0, r); p.arcToPoint(const Offset(r, 0), radius: const Radius.circular(r)); p.lineTo(l, 0);
    p.moveTo(size.width - l, 0); p.lineTo(size.width - r, 0); p.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r)); p.lineTo(size.width, l);
    p.moveTo(size.width, size.height - l); p.lineTo(size.width, size.height - r); p.arcToPoint(Offset(size.width - r, size.height), radius: const Radius.circular(r)); p.lineTo(size.width - l, size.height);
    p.moveTo(l, size.height); p.lineTo(r, size.height); p.arcToPoint(Offset(0, size.height - r), radius: const Radius.circular(r)); p.lineTo(0, size.height - l);

    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
