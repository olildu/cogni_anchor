import 'package:cogni_anchor/data/models/user_model.dart';
import 'package:cogni_anchor/data/services/live_location_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/chatbot/chatbot_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_intro_page.dart';
import 'package:cogni_anchor/presentation/screens/permissions_screen.dart';
import 'package:cogni_anchor/presentation/screens/reminder/reminder_page.dart';
import 'package:cogni_anchor/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  final UserModel userModel;
  const MainScreen({super.key, required this.userModel});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  RealtimeChannel? _patientStatusChannel;
  final SupabaseClient _client = Supabase.instance.client;

  bool? _lastLocationToggle;
  bool? _lastMicToggle;

  late final List<Widget> _allPages = [
    ReminderPage(userModel: widget.userModel), 
    const PermissionsScreen(), 
    const ChatbotPage(),
    const FacialRecognitionPage(),
    SettingsScreen(userModel: widget.userModel) 
  ];

  final List<Map<String, dynamic>> _allNavItems = [
    {
      'index': 0,
      'iconOutlined': Icons.alarm_rounded,
      'iconFilled': Icons.alarm,
      'label': 'Alarm'
    },
    {
      'index': 1,
      'iconOutlined': Icons.share_location_rounded,
      'iconFilled': Icons.share_location,
      'label': 'Share'
    },
    {
      'index': 2,
      'iconOutlined': Icons.chat_bubble_outline_rounded,
      'iconFilled': Icons.chat_bubble,
      'label': 'Chat'
    },
    {
      'index': 3,
      'iconOutlined': Icons.face_outlined,
      'iconFilled': Icons.face,
      'label': 'Face'
    },
    {
      'index': 4,
      'iconOutlined': Icons.settings_outlined,
      'iconFilled': Icons.settings,
      'label': 'Settings'
    },
  ];

  late List<Widget> _pages;
  late List<Map<String, dynamic>> _finalNavItems;

  @override
  void initState() {
    super.initState();
    _filterPagesAndNav();

    if (widget.userModel == UserModel.patient) {
      _startPatientStatusListener();

      _checkInitialServiceStatus();
    }
  }

  Future<void> _checkInitialServiceStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _client
          .from('patient_status')
          .select('location_toggle_on, mic_toggle_on')
          .eq('patient_user_id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        final locationToggle = data['location_toggle_on'] as bool? ?? false;
        final micToggle = data['mic_toggle_on'] as bool? ?? false;

        setState(() {
          _lastLocationToggle = locationToggle;
          _lastMicToggle = micToggle;
        });

        if (locationToggle) {
          debugPrint(" Initial Check: Starting Live Location Service");
          LiveLocationService.instance.start();
        }
      }
    } catch (e) {
      debugPrint(" Error checking initial status: $e");
    }
  }

  void _startPatientStatusListener() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _patientStatusChannel = _client
        .channel('patient_status_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'patient_status',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow == null) return;

            final locationToggle = newRow['location_toggle_on'] as bool?;
            final micToggle = newRow['mic_toggle_on'] as bool?;

            if (_lastLocationToggle == null ||
                locationToggle != _lastLocationToggle) {
              if (locationToggle == true) {
                LiveLocationService.instance.start();
              } else {
                LiveLocationService.instance.stop();
              }
            }

            if (mounted) {
              setState(() {
                _lastLocationToggle = locationToggle;
                _lastMicToggle = micToggle;
              });
            }
          },
        )
        .subscribe();
  }

  void _filterPagesAndNav() {
    if (widget.userModel == UserModel.patient) {
      List<int> allowedIndices = [0, 1, 2, 3, 4];

      _pages = allowedIndices.map((i) => _allPages[i]).toList();
      _finalNavItems = _allNavItems
          .where((item) => allowedIndices.contains(item['index']))
          .toList();
    } else {
      _pages = _allPages;
      _finalNavItems = _allNavItems;
    }
  }

  @override
  void dispose() {
    _patientStatusChannel?.unsubscribe();
    LiveLocationService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: GNav(
              rippleColor: AppColors.primaryLight,
              hoverColor: AppColors.primaryLight,
              gap: 8,
              activeColor: AppColors.primary,
              iconSize: 24.sp,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppColors.primaryLight,
              color: AppColors.textSecondary,
              tabs: _finalNavItems.asMap().entries.map((entry) {
                int i = entry.key;
                IconData iconFilled = entry.value['iconFilled'];
                IconData iconOutlined = entry.value['iconOutlined'];
                String label = entry.value['label'];

                return GButton(
                  icon: _selectedIndex == i ? iconFilled : iconOutlined,
                  text: label,
                );
              }).toList(),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
