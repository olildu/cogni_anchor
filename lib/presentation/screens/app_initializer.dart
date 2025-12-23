import 'package:camera/camera.dart';
import 'package:cogni_anchor/data/models/user_model.dart';
import 'package:cogni_anchor/data/services/camera_store.dart';
import 'package:cogni_anchor/data/services/embedding_service.dart';
import 'package:cogni_anchor/data/services/notification_service.dart';
import 'package:cogni_anchor/data/services/pair_context.dart';
import 'package:cogni_anchor/data/services/patient_status_service.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/screens/permission/patient_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:cogni_anchor/presentation/screens/auth/login_page.dart';
import 'package:cogni_anchor/presentation/screens/user_selection_page.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp(); 
  }

  Future<void> _initializeApp() async {
    try {
      await Supabase.initialize(
        url: 'https://joayctkupytsedmpfyng.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvYXljdGt1cHl0c2VkbXBmeW5nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1Mjc2MDAsImV4cCI6MjA4MTEwMzYwMH0.rFDWxQUM0n1nQmOuX3yFvjgCqVosMn3Ajgr8TMQmll4',
      );

      await NotificationService().init();
      await initPairContext();

      cameras = await availableCameras();

      await EmbeddingService.instance.loadModel();

      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e, s) {
      debugPrint(" App init failed: $e");
      debugPrintStack(stackTrace: s);
    }
  }

  Future<Widget> _resolveStartScreen() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    final data = await client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data['role'] == null) {
      return const UserSelectionPage();
    }

    final role = UserModel.values.firstWhere(
      (e) => e.name == data['role'],
    );

    if (role == UserModel.patient) {
      final status = await client
          .from('patient_status')
          .select('location_permission, mic_permission')
          .eq('patient_user_id', user.id)
          .maybeSingle();

      final locationGranted = status?['location_permission'] == true;
      final micGranted = status?['mic_permission'] == true;

      if (!locationGranted || !micGranted) {
        return const PatientPermissionsScreen();
      }
    }

    if (role == UserModel.patient) {
      await PatientStatusService.updateLastActive();
    }

    return BlocProvider(
      create: (_) => ReminderBloc(),
      child: MainScreen(userModel: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<Widget>(
      future: _resolveStartScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }

  Future<void> initPairContext() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final patientPair = await client
        .from('pairs')
        .select('id')
        .eq('patient_user_id', user.id)
        .maybeSingle();

    if (patientPair != null) {
      PairContext.set(patientPair['id']);
      return;
    }

    final caretakerPair = await client
        .from('pairs')
        .select('id')
        .eq('caretaker_user_id', user.id)
        .maybeSingle();

    if (caretakerPair != null) {
      PairContext.set(caretakerPair['id']);
    }
  }
}
