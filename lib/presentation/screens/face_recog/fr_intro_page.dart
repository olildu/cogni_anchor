import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_scan_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class FacialRecognitionPage extends StatelessWidget {
  const FacialRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: colors.appColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.r), bottomRight: Radius.circular(20.r)),
          ),
          title: AppText("Facial Recoginition", fontSize: 20.sp, color: Colors.white),
        ),
      ),

      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gap(20.h),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(color: colors.appColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16.r)),
                child: Icon(Icons.face_retouching_natural, size: 40.sp, color: colors.appColor),
              ),
              Gap(20.h),
              AppText("Face Recognition", fontSize: 24.sp, fontWeight: FontWeight.w700),
              Gap(6.h),
              AppText("Let's help you recognize someone", fontSize: 15.sp, color: Colors.black54),

              Gap(40.h),
              const FRHowItWorksCard(),

              const Spacer(),

              FRMainButton(
                label: "Start Scanning",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FRScanPage()));
                },
              ),
              Gap(30.h),
            ],
          ),
        ),
      ),
    );
  }
}
