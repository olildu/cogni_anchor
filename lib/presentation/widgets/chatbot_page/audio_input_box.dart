import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class AudioInputBox extends StatelessWidget {
  const AudioInputBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(color: const Color(0xfffff0e6), borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        children: [
          AppText("Say how can I help you?", fontSize: 16.sp, fontWeight: FontWeight.w500),
          Gap(20.h),
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.appColor, width: 2)),
            child: Icon(Icons.mic, size: 30.sp, color: colors.appColor),
          ),
        ],
      ),
    );
  }
}
