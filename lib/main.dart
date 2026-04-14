import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/exercise_access_service.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SGALearningApp());
}

class SGALearningApp extends StatefulWidget {
  const SGALearningApp({super.key});

  @override
  State<SGALearningApp> createState() => _SGALearningAppState();
}

class _SGALearningAppState extends State<SGALearningApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        final uid = AuthService.currentUser?.uid;
        if (uid != null) {
          ProgressService.syncOnStartup(uid);
          ExerciseAccessService.syncPendingUnlocks(uid);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveStatus();
    }
  }

  Future<void> _checkActiveStatus() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final isActive = data['isActive'] as bool? ?? true;

      if (!isActive) {
        await AuthService.logout();
        if (navigatorKey.currentContext != null) {
          Navigator.of(
            navigatorKey.currentContext!,
            rootNavigator: true,
          ).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SGA Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final user = await AuthService.checkLoginStatus();
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    ProgressService.syncOnStartup(user.uid);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}