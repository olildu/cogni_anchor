import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/chatbot_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_intro_page.dart';
import 'package:cogni_anchor/presentation/screens/reminder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final orange = colors.appColor;

  final List<Widget> _pages = [
    const ReminderPage(),
    Container(color: Colors.green),
    const ChatbotPage(),
    const FacialRecognitionPage(),
    Container(color: Colors.red)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),
        ),
        child: GNav(
          selectedIndex: _selectedIndex,
          onTabChange: (i) {
            setState(() => _selectedIndex = i);
          },
          haptic: true,
          gap: 6,
          iconSize: 26,
          tabBorderRadius: 12,
          color: Colors.white70,
          activeColor: Colors.white,
          tabBackgroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          mainAxisAlignment: MainAxisAlignment.center,
          tabs: [
            _navItem(
                index: 0,
                iconOutlined: Icons.alarm_rounded,
                iconFilled: Icons.alarm),
            _navItem(
                index: 1,
                iconOutlined: Icons.send_rounded,
                iconFilled: Icons.send),
            _navItem(
                index: 2,
                iconOutlined: Icons.chat_bubble_outline_rounded,
                iconFilled: Icons.chat_bubble),
            _navItem(
                index: 3,
                iconOutlined: Icons.face_outlined,
                iconFilled: Icons.face),
            _navItem(
                index: 4,
                iconOutlined: Icons.settings_outlined,
                iconFilled: Icons.settings),
          ],
        ),
      ),
    );
  }

  GButton _navItem(
      {required int index,
      required IconData iconOutlined,
      required IconData iconFilled}) {
    return GButton(icon: _selectedIndex == index ? iconFilled : iconOutlined);
  }
}
