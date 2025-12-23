import 'package:cogni_anchor/data/models/user_model.dart';
import 'package:cogni_anchor/data/services/pair_context.dart';
import 'package:cogni_anchor/data/services/patient_status_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dementia_profile_screen.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';
import 'package:cogni_anchor/presentation/screens/auth/login_page.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel userModel;

  const SettingsScreen({super.key, required this.userModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  String? pairId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPair();
  }

  Future<void> _loadPair() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      if (widget.userModel == UserModel.patient) {
        final existing = await _client
            .from('pairs')
            .select()
            .eq('patient_user_id', user.id)
            .maybeSingle();

        if (existing == null) {
          final inserted = await _client
              .from('pairs')
              .insert({'patient_user_id': user.id})
              .select()
              .single();
          pairId = inserted['id'];
        } else {
          pairId = existing['id'];
        }
        PairContext.set(pairId!);
      }

      if (widget.userModel == UserModel.caretaker) {
        final existing = await _client
            .from('pairs')
            .select()
            .eq('caretaker_user_id', user.id)
            .maybeSingle();

        pairId = existing?['id'];
        if (pairId != null) {
          PairContext.set(pairId!);
        }
      }
    } catch (_) {
      _showMsg("Failed to load pairing info");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _connectToPatient(String enteredPairId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final cleanId = enteredPairId.trim();

    final pair =
        await _client.from('pairs').select().eq('id', cleanId).maybeSingle();

    if (pair == null) throw Exception("Invalid Pair ID");
    if (pair['caretaker_user_id'] != null) {
      throw Exception("Pair already connected");
    }

    await _client
        .from('pairs')
        .update({'caretaker_user_id': user.id}).eq('id', cleanId);

    setState(() {
      pairId = cleanId;
      PairContext.set(pairId!);
    });
  }

  void _showPairIdDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: AppText("Connect to Patient",
            fontSize: 18.sp, fontWeight: FontWeight.w600),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Enter Patient Pair ID",
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText("Cancel", color: Colors.grey),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              try {
                await _connectToPatient(controller.text);
                if (mounted) Navigator.pop(context);
              } catch (_) {
                _showMsg("Invalid Pair ID");
              }
            },
            child: AppText("Connect", color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (_) => _confirmDialog(
        title: "Log out?",
        message: "Are you sure you want to log out?",
        confirmText: "Yes",
        onConfirm: _logout,
      ),
    );
  }

  Future<void> _logout() async {
    Navigator.pop(context);

    if (widget.userModel == UserModel.patient) {
      await PatientStatusService.markLoggedOut();
    }

    await _client.auth.signOut();
    PairContext.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: AppText(title, fontSize: 18.sp, fontWeight: FontWeight.w600),
      content: AppText(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: AppText("No", color: Colors.grey),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: onConfirm,
          child: AppText(confirmText, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        title: AppText("Settings",
            fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // 🔹 Profile Header (Moved from AppBar)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40.r,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person,
                          size: 40.sp, color: AppColors.primary),
                    ),
                  ),
                  Gap(12.h),
                  AppText(
                    widget.userModel == UserModel.patient
                        ? "Patient Profile"
                        : "Caretaker Profile",
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  AppText(
                    _client.auth.currentUser?.email ?? "",
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            Gap(10.h),

            // 🔹 Menu Items
            _tile(
              Icons.edit_outlined,
              "Edit Profile",
              () => _go(const EditProfileScreen()),
            ),
            _tile(
              Icons.person_outline,
              "Person Living With Dementia's Profile",
              () => _go(const DementiaProfileScreen()),
            ),

            if (widget.userModel == UserModel.patient && pairId != null)
              _patientPairIdBox(),

            if (widget.userModel == UserModel.caretaker)
              pairId == null
                  ? _tile(
                      Icons.group_outlined,
                      "Connect to Patient",
                      _showPairIdDialog,
                    )
                  : _caretakerPairIdBox(),

            _tile(
              Icons.lock_outline,
              "Change Password",
              () => _go(const ChangePasswordScreen()),
            ),
            _tile(
              Icons.description_outlined,
              "Terms and Conditions",
              () => _go(const TermsConditionsScreen()),
            ),

            Gap(20.h),
            _logoutTile(),
            Gap(30.h),
          ],
        ),
      ),
    );
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _patientPairIdBox() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText("Your Pair ID", fontSize: 16.sp, fontWeight: FontWeight.w600),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(pairId ?? "",
                      style: TextStyle(fontSize: 14.sp, fontFamily: 'Poppins')),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pairId ?? ""));
                  _showMsg("Pair ID copied");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _caretakerPairIdBox() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText("Connected Pair ID",
              fontSize: 16.sp, fontWeight: FontWeight.w600),
          Gap(8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                Gap(8.w),
                Expanded(
                    child: SelectableText(pairId ?? "",
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: 'Poppins',
                            color: Colors.green.shade800))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
        title: AppText(title, fontSize: 15.sp, fontWeight: FontWeight.w500),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.logout, color: Colors.red, size: 20.sp),
        ),
        title: AppText(
          'Log out',
          color: Colors.red,
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
        onTap: _confirmLogout,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
