import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/edit_profile.dart';
import 'features/map_page.dart';
import 'features/profile.dart';
import 'features/settings.dart';
import 'features/sos.dart';
import 'features/welcome.dart';
import 'features/get_started.dart';
import 'features/forgot_password.dart';
import 'features/sign_up_page.dart';
import 'features/dashboard_page.dart';
import 'features/sign_in_page.dart';
import 'features/verify.dart';
import 'features/notifications_page.dart';
import 'features/image_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      name: "dev project", options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => CustomImageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bahanap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blue,
        ),
        focusColor: Colors.blue,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 2.0,
            ),
          ),
        ),
      ),
      initialRoute: 'home',
      routes: {
        'welcome': (context) => const Welcome(),
        'dash': (context) => const DashboardPage(),
        'forgot': (context) => const ForgotPassword(),
        'signup': (context) => const SignUpPage(),
        'notifications': (context) => const NotificationsPage(),
        'map': (context) => const MapPage(),
        'signin': (context) => const SignInPage(),
        'getstarted': (context) => const GetStarted(),
        'verify': (context) => const Verify(),
        'sos': (context) => const SosPage(),
        'profile': (context) => const ProfilePage(),
        'settings': (context) => const SettingsPage(),
        'editprofile': (context) => const EditProfilePage(),
      },
      home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data != null) {
              return const DashboardPage();
            }
            return const Welcome();
          }),
    );
  }
}
