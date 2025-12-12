import 'dart:convert';
import 'dart:io';

import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_found_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_not_found_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/services/face_crop_service.dart';
import 'package:cogni_anchor/services/embedding_service.dart';
import 'package:cogni_anchor/services/api_service.dart';

class FRScanPage extends StatefulWidget {
  const FRScanPage({super.key});

  @override
  State<FRScanPage> createState() => _FRScanPageState();
}

class _FRScanPageState extends State<FRScanPage> {
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

        // start one scan
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

  Future<void> _scanFace() async {
    setState(() => _isScanning = true);

    try {
      // 1) capture image
      final xFile = await _cameraController.takePicture();
      final imageFile = File(xFile.path);

      // 2) crop face
      final croppedFace =
          await FaceCropService.instance.detectAndCropFace(imageFile);

      if (croppedFace == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
          );
        }
        return;
      }

      // 3) embedding
      final faceBytes = await croppedFace.readAsBytes();
      final embedding = await EmbeddingService.instance.getEmbedding(faceBytes);

      // 4) backend check
      final result = await ApiService.scanPerson(embedding: embedding);

      if (result['matched'] == true) {
        final person = result['person'] as Map<String, dynamic>;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FRResultFoundPage(person: person),
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
    } catch (e) {
      debugPrint("❌ Error scanning face: $e");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController.value.aspectRatio;

    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_cameraController)),
          ),

          /// TOP TEXT
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

          /// SCAN BOX + STATUS
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280.w,
                  height: 350.h,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.appColor,
                      width: 3,
                    ),
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

          /// BOTTOM BUTTONS
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

          /// BACK BUTTON
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
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
