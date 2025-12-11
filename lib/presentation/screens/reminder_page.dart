import 'package:cogni_anchor/data/reminder_model.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/reminder_page/reminder_child_card_widget.dart';
import 'package:cogni_anchor/presentation/widgets/reminder_page/reminder_main_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Reminder> reminders = [
    Reminder(title: "Morning Workout", date: "17 Nov 2025", time: "06:30 AM"),
    Reminder(title: "Team Meeting", date: "17 Nov 2025", time: "10:00 AM"),
    Reminder(title: "Buy Groceries", date: "17 Nov 2025", time: "07:00 PM"),
    Reminder(title: "Call Mom", date: "18 Nov 2025", time: "08:30 PM"),
    Reminder(title: "Submit Assignment", date: "19 Nov 2025", time: "11:59 PM"),
  ];

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
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r)),
          ),
          title: AppText("Reminders", fontSize: 20.sp, color: Colors.white),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: colors.appColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Gap(30.h),

              ReminderMainCardWidget(
                  title: "Drink Water",
                  time: "11:00 AM Today",
                  color: colors.appColor),

              Gap(20.h),

              // Rest of the items (not upcoming)
              Expanded(
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    return ReminderChildCardWidget(
                        title: reminders[index].title,
                        date: reminders[index].date,
                        time: reminders[index].time,
                        color: colors.appColor);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
