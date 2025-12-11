import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/chatbot_page/audio_input_box.dart';
import 'package:cogni_anchor/presentation/widgets/chatbot_page/bot_bubble.dart';
import 'package:cogni_anchor/presentation/widgets/chatbot_page/quick_chip.dart';
import 'package:cogni_anchor/presentation/widgets/chatbot_page/text_input_box.dart';
import 'package:cogni_anchor/presentation/widgets/chatbot_page/toggle_button.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  bool isAudio = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(20.h),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButton(
                      label: "Audio",
                      selected: isAudio,
                      onTap: () => setState(() => isAudio = true)),
                  Gap(12.w),
                  ToggleButton(
                      label: "Text",
                      selected: !isAudio,
                      onTap: () => setState(() => isAudio = false)),
                ],
              ),
            ),
            Gap(20.h),
            const BotBubble("Hi, What do you want me to do?"),
            Gap(20.h),
            Row(
              children: [
                Icon(Icons.fluorescent_rounded,
                    color: colors.appColor.withValues(alpha: 0.7)),
                Gap(10.w),
                Expanded(
                    child: AppText(
                        "I suggest you some frequently performed tasks.",
                        fontSize: 15.sp)),
              ],
            ),
            Gap(14.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 12.h,
              children: const [
                QuickChip("Set a reminder"),
                QuickChip("Turn on live location"),
                QuickChip("Turn on microphone share"),
                QuickChip("Recognize this person")
              ],
            ),
            const Spacer(),
            isAudio ? const AudioInputBox() : const TextInputBox(),
            Gap(15.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(70.h),
      child: AppBar(
        elevation: 0,
        backgroundColor: colors.appColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r)),
        ),
        title: AppText("Chatbot AI",
            fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
