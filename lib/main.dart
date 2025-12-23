import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogni_anchor/presentation/screens/app_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CogniAnchor());
}

class CogniAnchor extends StatelessWidget {
  const CogniAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReminderBloc(),
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme, 
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}