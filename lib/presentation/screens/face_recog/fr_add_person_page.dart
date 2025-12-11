import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

import 'package:cogni_anchor/services/embedding_service.dart';
import 'package:cogni_anchor/services/face_crop_service.dart';

class FRAddPersonPage extends StatefulWidget {
  final File? initialImageFile;

  const FRAddPersonPage({super.key, this.initialImageFile});

  @override
  State<FRAddPersonPage> createState() => _FRAddPersonPageState();
}

class _FRAddPersonPageState extends State<FRAddPersonPage> {
  static const String _baseUrl = "http://10.0.2.2:8000/api/v1/faces/enroll";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isSaving = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImageFile;
    if (_capturedImage == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_capturedImage != null) {
      setState(() => _capturedImage = null);
      return;
    }

    if (!_isCameraInitialized) return;

    try {
      final xFile = await _cameraController.takePicture();
      setState(() => _capturedImage = File(xFile.path));
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  Future<void> _enrollPerson() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Capture a face image first")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // -------- 1️⃣ Crop face --------
      final cropped = await FaceCropService.instance.detectAndCropFace(
        _capturedImage!,
      );
      if (cropped == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face detected in the image")),
        );
        return;
      }

      // -------- 2️⃣ Convert to bytes and embed --------
      final bytes = await cropped.readAsBytes();
      final embedding = await EmbeddingService.instance.getEmbedding(bytes);

      // -------- 3️⃣ Build request JSON --------
      final body = jsonEncode({
        "name": _nameController.text,
        "relationship": _relationshipController.text,
        "occupation": _occupationController.text,
        "age": _ageController.text,
        "notes": _notesController.text,
        "embedding": embedding,
      });

      // -------- 4️⃣ Send to backend --------
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Person enrolled successfully")),
        );
        Navigator.pop(context);
      } else {
        debugPrint("Enroll error: ${res.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
      }
    } catch (e) {
      debugPrint("Enroll exception: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _nameController.dispose();
    _relationshipController.dispose();
    _occupationController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          "Add New Person",
          color: colors.appColor,
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.appColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCaptureSection(),
            Gap(25.h),
            AppText(
              "Person Details",
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            Gap(15.h),
            _buildTextField("Full Name", _nameController),
            Gap(15.h),
            _buildTextField("Relationship", _relationshipController),
            Gap(15.h),
            _buildTextField("Occupation", _occupationController),
            Gap(15.h),
            _buildTextField("Age", _ageController),
            Gap(15.h),
            _buildTextField("Notes", _notesController, maxLines: 3),
            Gap(40.h),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : FRMainButton(label: "Save and Enroll", onTap: _enrollPerson),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildImageCaptureSection() {
    final showCamera = _capturedImage == null && _isCameraInitialized;
    final aspectRatio =
        _isCameraInitialized ? _cameraController.value.aspectRatio : 1.0;

    return Column(
      children: [
        Container(
          height: 400.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colors.appColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: _capturedImage != null
                ? Image.file(_capturedImage!, fit: BoxFit.cover)
                : showCamera
                    ? AspectRatio(
                        aspectRatio: aspectRatio,
                        child: CameraPreview(_cameraController),
                      )
                    : const Center(child: Text("Initializing camera...")),
          ),
        ),
        Gap(15.h),
        SizedBox(
          width: 150.w,
          child: ElevatedButton(
            onPressed:
                showCamera || _capturedImage != null ? _captureImage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _capturedImage != null ? Colors.red : colors.appColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(
              _capturedImage != null ? "Retake" : "Capture Face",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
