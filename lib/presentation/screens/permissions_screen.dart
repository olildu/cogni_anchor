import 'package:cogni_anchor/data/services/pair_context.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cogni_anchor/presentation/screens/permission/caregiver_live_map_screen.dart';
import 'package:cogni_anchor/presentation/screens/permission/mic_sharing_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool locationEnabled = false;
  bool microphoneEnabled = false;
  bool _loadingLocation = false;
  bool _loadingMic = false;
  bool _isPatient = false;

  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final data = await _client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isPatient = data?['role'] == 'patient';
        });
      }
    }
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final pairId = PairContext.pairId;
      if (pairId == null) return;

      final pair = await _client
          .from('pairs')
          .select('patient_user_id')
          .eq('id', pairId)
          .maybeSingle();
      if (pair == null) return;

      final status = await _client
          .from('patient_status')
          .select('location_toggle_on, mic_toggle_on')
          .eq('patient_user_id', pair['patient_user_id'])
          .maybeSingle();

      if (status != null && mounted) {
        setState(() {
          locationEnabled = status['location_toggle_on'] ?? false;
          microphoneEnabled = status['mic_toggle_on'] ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _updatePermissionInDb(String column, bool granted) async {
    final user = _client.auth.currentUser;
    if (user == null || !_isPatient) return;
    await _client
        .from('patient_status')
        .update({column: granted}).eq('patient_user_id', user.id);
  }

  Future<void> _toggleLocation(bool value) async {
    if (_loadingLocation) return;
    setState(() => _loadingLocation = true);

    try {
      final pairId = PairContext.pairId;
      if (pairId == null) throw "No patient connected";

      final pair = await _client
          .from('pairs')
          .select('patient_user_id')
          .eq('id', pairId)
          .single();
      final patientUserId = pair['patient_user_id'];

      if (_isPatient && value == true) {
        var status = await Permission.locationAlways.status;
        if (!status.isGranted) {
          status = await Permission.locationAlways.request();
          if (!status.isGranted) {
            status = await Permission.location.request();
          }
        }

        if (!status.isGranted) {
          _showMsg("Location permission is required to share location.");
          await _updatePermissionInDb('location_permission', false);
          return;
        }
        await _updatePermissionInDb('location_permission', true);
      } else if (!_isPatient && value == true) {
        final pStatus = await _client
            .from('patient_status')
            .select('location_permission')
            .eq('patient_user_id', patientUserId)
            .single();
        if (pStatus['location_permission'] != true) {
          _showMsg(
              "Patient has not granted location permission on their device.");
          return;
        }
      }

      await _client.from('patient_status').update(
          {'location_toggle_on': value}).eq('patient_user_id', patientUserId);
      setState(() => locationEnabled = value);
    } catch (e) {
      _showMsg("Action failed: ${e.toString()}");
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _toggleMic(bool value) async {
    if (_loadingMic) return;
    setState(() => _loadingMic = true);

    try {
      final pairId = PairContext.pairId;
      if (pairId == null) throw "No patient connected";

      final pair = await _client
          .from('pairs')
          .select('patient_user_id')
          .eq('id', pairId)
          .single();
      final patientUserId = pair['patient_user_id'];

      if (_isPatient && value == true) {
        var status = await Permission.microphone.status;
        if (!status.isGranted) {
          status = await Permission.microphone.request();
        }

        if (!status.isGranted) {
          _showMsg("Microphone permission is required.");
          await _updatePermissionInDb('mic_permission', false);
          return;
        }
        await _updatePermissionInDb('mic_permission', true);
      } else if (!_isPatient && value == true) {
        final pStatus = await _client
            .from('patient_status')
            .select('mic_permission')
            .eq('patient_user_id', patientUserId)
            .single();
        if (pStatus['mic_permission'] != true) {
          _showMsg("Patient has not granted microphone permission.");
          return;
        }
      }

      await _client.from('patient_status').update({'mic_toggle_on': value}).eq(
          'patient_user_id', patientUserId);
      setState(() => microphoneEnabled = value);

      if (value == true && mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MicSharingScreen()));
      }
    } catch (e) {
      _showMsg("Action failed");
    } finally {
      setState(() => _loadingMic = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.3),
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText(
          _isPatient ? "Privacy & Sharing" : "Remote Monitor",
          fontSize: 18.sp,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // 🔹 HEADER INFO (Moved from AppBar to Body)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPatient ? Icons.security : Icons.health_and_safety,
                      color: AppColors.primary,
                      size: 40.sp,
                    ),
                  ),
                  Gap(12.h),
                  AppText(
                    _isPatient
                        ? "Control what you share"
                        : "Manage patient devices",
                    color: Colors.grey.shade700,
                    fontSize: 14.sp,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Gap(10.h),

            // 🔹 CONTENT
            _sectionHeader("Live Services"),
            Gap(12.h),
            _permissionTile(
              title:
                  _isPatient ? "Share Live Location" : "View Patient Location",
              subtitle: _isPatient
                  ? "Allow real-time tracking"
                  : "See them on the map",
              icon: Icons.location_on_rounded,
              value: locationEnabled,
              isLoading: _loadingLocation,
              color: Colors.orangeAccent,
              onChanged: _toggleLocation,
            ),

            if (locationEnabled)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r)),
                    ),
                    icon: const Icon(Icons.map),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CaregiverLiveMapScreen()));
                    },
                    label: const Text("Open Live Map",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

            Gap(20.h),

            _permissionTile(
              title: _isPatient ? "Share Audio" : "Listen to Audio",
              subtitle: _isPatient
                  ? "Stream mic to caretaker"
                  : "Hear patient's surroundings",
              icon: Icons.mic_rounded,
              value: microphoneEnabled,
              isLoading: _loadingMic,
              color: Colors.blueAccent,
              onChanged: _toggleMic,
            ),

            Gap(40.h),

            Center(
              child: AppText(
                "These services consume battery power and require an active internet connection.",
                fontSize: 11.sp,
                color: Colors.grey.shade500,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: AppText(
          title,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isLoading,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontSize: 16.sp, fontWeight: FontWeight.w600),
                Gap(4.h),
                AppText(subtitle, fontSize: 12.sp, color: Colors.grey),
              ],
            ),
          ),
          isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.3),
                ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
