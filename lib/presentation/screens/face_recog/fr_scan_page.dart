import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_found_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_not_found_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:cogni_anchor/services/face_crop_service.dart';
import 'package:cogni_anchor/services/embedding_service.dart';
import 'package:cogni_anchor/config/api_config.dart';

class RecognitionResult {
  final bool matchFound;
  RecognitionResult({required this.matchFound});

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(matchFound: json['match_found'] as bool);
  }
}

class FRScanPage extends StatefulWidget {
  const FRScanPage({super.key});

  @override
  State<FRScanPage> createState() => _FRScanPageState();
}

class _FRScanPageState extends State<FRScanPage> {
  static final String _baseUrl = ApiConfig.recognize;

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _scanFace();
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<List<int>> _getCaptureImageBytes() async {
    if (!_isCameraInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCameraInitialized) throw Exception("Camera not initialized.");
    }

    try {
      final xFile = await _cameraController.takePicture();
      final file = File(xFile.path);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint("Error taking picture: $e");
      rethrow;
    }
  }

  Future<void> _scanFace() async {
    setState(() => _isScanning = true);

    try {
      // 1️⃣ Capture image from camera
      final xFile = await _cameraController.takePicture();
      final imageFile = File(xFile.path);

      // 2️⃣ Crop face locally
      final croppedFace = await FaceCropService.instance.detectAndCropFace(
        imageFile,
      );

      if (croppedFace == null) {
        debugPrint("❌ No face detected");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
          );
        }
        return;
      }

      // 3️⃣ Generate embedding locally
      final faceBytes = await croppedFace.readAsBytes();
      final embedding = await EmbeddingService.instance.getEmbedding(faceBytes);

      // 4️⃣ Send embedding to backend instead of raw image
      final uri = Uri.parse(_baseUrl);
      final headers = {"Content-Type": "application/json"};
      final body = jsonEncode({"embedding": embedding});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['match_found'] == true) {
          final recognizedPerson = RecognizedPerson(
            name: jsonResponse['person_name'] ?? 'Unknown',
            relationship: jsonResponse['relationship'] ?? 'N/A',
            occupation: jsonResponse['occupation'] ?? 'N/A',
            age: jsonResponse['age'] ?? 'N/A',
            notes: jsonResponse['notes'] ?? 'None',
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FRResultFoundPage(person: recognizedPerson),
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
            );
          }
        }
      } else {
        debugPrint("❌ API Error: ${response.body}");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_cameraController)),
          ),
          Positioned(
            top: 60.h,
            left: 0,
            right: 0,
            child: Center(
              child: AppText(
                "Trouble remembering a person?",
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280.w,
                  height: 350.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.appColor, width: 3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                Gap(20.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.camera, color: colors.appColor),
                      Gap(5.h),
                      _isScanning
                          ? AppText(
                              "Scanning face...",
                              fontSize: 12.sp,
                              color: colors.appColor,
                            )
                          : AppText(
                              "Ready to scan",
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.flashlight_on_outlined),
                _circleBtn(Icons.image_outlined),
              ],
            ),
          ),
          Positioned(
            top: 50.h,
            left: 20.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration:
          const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    );
  }
}
