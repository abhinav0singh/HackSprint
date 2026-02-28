import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'core/storage_service.dart';
import 'providers/goal_provider.dart';
import 'screens/shell_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

// ─────────────────────────────────────────────────────────
// main.dart  (PRD §4.1, §8 Phase 2)
//
// Responsibilities:
//   1. Initialise Isar and create StorageService singleton.
//   2. Wrap app in ProviderScope with storageServiceProvider override.
//   3. Check onboarding flag (SharedPreferences) on launch.
//   4. Install WidgetsBindingObserver to invalidate goalsProvider
//      on AppLifecycleState.resumed — ensures daysRemaining and
//      isOverdue are recomputed after midnight or background. (Fix #13)
// ─────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Isar singleton
  final storageService = await StorageService.init();

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone =
      prefs.getBool(kPrefsOnboardingComplete) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: MoneyByteApp(showOnboarding: !onboardingDone),
    ),
  );
}

class MoneyByteApp extends StatelessWidget {
  const MoneyByteApp({super.key, required this.showOnboarding});
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyByte',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: showOnboarding ? '/onboarding' : '/home',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home':       (_) => const _AppLifecycleWrapper(),
      },
    );
  }
}

// ── WidgetsBindingObserver wrapper (Fix #13) ─────────────
/// Wraps ShellScreen to catch AppLifecycleState.resumed.
/// On resume: invalidates goalsProvider so daysRemaining and
/// isOverdue are recomputed. No DB writes — isOverdue is a pure getter.
class _AppLifecycleWrapper extends ConsumerStatefulWidget {
  const _AppLifecycleWrapper();

  @override
  ConsumerState<_AppLifecycleWrapper> createState() =>
      _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Invalidate the stream provider to trigger re-sort.
      // isOverdue is a pure computed getter — no batch DB write needed.
      // This handles the midnight edge case (Fix #13).
      ref.invalidate(goalsProvider);
    }
  }

  @override
  Widget build(BuildContext context) => const ShellScreen();
}
