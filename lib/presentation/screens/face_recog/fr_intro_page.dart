import 'dart:ui';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_scan_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_add_person_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_people_list_page.dart';
import 'package:gap/gap.dart';

class FacialRecognitionPage extends StatefulWidget {
  const FacialRecognitionPage({super.key});

  @override
  State<FacialRecognitionPage> createState() => _FacialRecognitionPageState();
}

class _FacialRecognitionPageState extends State<FacialRecognitionPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  bool get _isExpanded =>
      _fabAnimController.status == AnimationStatus.forward ||
      _fabAnimController.status == AnimationStatus.completed;

  void _toggleFabMenu() {
    if (_isExpanded) {
      _fabAnimController.reverse();
    } else {
      _fabAnimController.forward();
    }
  }

  void _closeFabMenu() {
    if (_isExpanded) _fabAnimController.reverse();
  }

  void _onAddPersonTap() {
    _closeFabMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FRAddPersonPage()),
    );
  }

  void _onEditDetailsTap() {
    _closeFabMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FRPeopleListPage(forEditing: true),
      ),
    );
  }

  void _onRemovePersonTap() {
    _closeFabMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FRPeopleListPage(forEditing: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ================= MAIN SCREEN =================
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: colors.appColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
            ),
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 5.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Gap(15.h),
                  Container(
                    width: 75.w,
                    height: 75.w,
                    decoration: BoxDecoration(
                      color: colors.appColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.face_retouching_natural,
                      size: 36.sp,
                      color: colors.appColor,
                    ),
                  ),
                  Gap(18.h),
                  AppText(
                    "Face Recognition",
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  Gap(5.h),
                  AppText(
                    "Let's help you recognize someone",
                    fontSize: 15.sp,
                    color: Colors.black54,
                  ),
                  Gap(35.h),
                  const FRHowItWorksCard(),

                  const Spacer(),

                  // -------- FAB-STYLE START BUTTON (UNCHANGED) --------
                  Padding(
                    padding: EdgeInsets.only(bottom: 107.h),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(30.r),
                      shadowColor: colors.appColor.withOpacity(0.4),
                      child: FRMainButton(
                        label: "Start Scanning",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FRScanPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ================= DARK OVERLAY =================
        AnimatedBuilder(
          animation: _fabAnimController,
          builder: (context, child) {
            if (_fabAnimController.value == 0) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: GestureDetector(
                onTap: _closeFabMenu,
                child: Container(
                  color: Colors.black.withOpacity(
                    0.45 * _fabAnimController.value,
                  ),
                ),
              ),
            );
          },
        ),

        // ================= EXPANDABLE FAB =================
        Positioned(
          bottom: 30.h,
          right: 20.w,
          child: _ExpandableFAB(
            animationController: _fabAnimController,
            onMainButtonTap: _toggleFabMenu,
            onAddPersonTap: _onAddPersonTap,
            onRemovePersonTap: _onRemovePersonTap,
            onEditDetailsTap: _onEditDetailsTap,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// EXPANDABLE FAB (FIXED CIRCULAR FAB)
// =============================================================

class _ExpandableFAB extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onMainButtonTap;
  final VoidCallback onAddPersonTap;
  final VoidCallback onRemovePersonTap;
  final VoidCallback onEditDetailsTap;

  const _ExpandableFAB({
    required this.animationController,
    required this.onMainButtonTap,
    required this.onAddPersonTap,
    required this.onRemovePersonTap,
    required this.onEditDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    const double d1 = 75;
    const double d2 = 145;
    const double d3 = 215;

    return SizedBox(
      width: 250.w,
      height: 240.h,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _AnimatedOption(
            controller: animationController,
            distance: d3.h,
            label: "Edit details",
            icon: Icons.edit,
            onTap: onEditDetailsTap,
          ),
          _AnimatedOption(
            controller: animationController,
            distance: d2.h,
            label: "Remove person",
            icon: Icons.person_remove,
            onTap: onRemovePersonTap,
          ),
          _AnimatedOption(
            controller: animationController,
            distance: d1.h,
            label: "Add person",
            icon: Icons.person_add,
            onTap: onAddPersonTap,
          ),

          // -------- PERFECT CIRCULAR FAB --------
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                backgroundColor: colors.appColor,
                shape: const CircleBorder(),
                onPressed: onMainButtonTap,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: animationController.value * 3.14159,
                      child: Icon(
                        animationController.value > 0.1
                            ? Icons.close
                            : Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// FAB MENU OPTION
// =============================================================

class _AnimatedOption extends StatelessWidget {
  final AnimationController controller;
  final double distance;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedOption({
    required this.controller,
    required this.distance,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -distance * controller.value),
          child: Opacity(opacity: controller.value, child: child),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AppText(
                  label,
                  fontSize: 13.sp,
                  color: colors.appColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Gap(10.w),
              CircleAvatar(
                radius: 20.r,
                backgroundColor: colors.appColor,
                child: Icon(icon, size: 20.sp, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
