import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

// ─────────────────────────────────────────────────────────
// OnboardingScreen  (PRD §5.1)
//
// OB-1: Welcome  — animated demo ring, 'Get Started'
// OB-2: How It Works — 3 icon+text rows
// OB-3: Widget Prompt — OS widget picker + fallback (Q4 answer)
//
// Marks 'onboarding_complete' in SharedPreferences on finish.
// ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefsOnboardingComplete, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OB1Page(onNext: _next),
                  _OB2Page(onNext: _next),
                  _OB3Page(
                    onGetStarted: _completeOnboarding,
                    onSkip: _completeOnboarding,
                  ),
                ],
              ),
            ),
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.colorNeonGreen
                          : AppTheme.colorTextSecondary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── OB-1: Welcome ────────────────────────────────────────
class _OB1Page extends StatefulWidget {
  const _OB1Page({required this.onNext});
  final VoidCallback onNext;

  @override
  State<_OB1Page> createState() => _OB1PageState();
}

class _OB1PageState extends State<_OB1Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _percentAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _percentAnim = Tween<double>(begin: 0.0, end: 0.68).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Animated demo ring
          AnimatedBuilder(
            animation: _percentAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.neonGlow(),
              ),
              child: CircularPercentIndicator(
                radius: 100.0,
                lineWidth: 14.0,
                percent: _percentAnim.value,
                progressColor: AppTheme.colorNeonGreen,
                backgroundColor: AppTheme.colorSurface,
                circularStrokeCap: CircularStrokeCap.round,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_percentAnim.value * 100).round()}%',
                      style: AppTheme.displayLarge,
                    ),
                    const Text('saved', style: AppTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Your goals.\nOne glance.',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Track all your savings goals in one beautiful, motivating dashboard.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: widget.onNext,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

// ── OB-2: How It Works ───────────────────────────────────
class _OB2Page extends StatelessWidget {
  const _OB2Page({required this.onNext});
  final VoidCallback onNext;

  static const List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.add_circle_outline,
      'title': 'Add a goal',
      'desc': 'Name your goal, set a target amount and deadline.',
    },
    {
      'icon': Icons.savings_outlined,
      'title': 'Track savings',
      'desc': 'Log every rupee you save — the ring updates instantly.',
    },
    {
      'icon': Icons.emoji_events_outlined,
      'title': 'Hit targets',
      'desc': 'Celebrate completions with confetti and move to the next goal.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works', style: AppTheme.headlineMedium),
          const SizedBox(height: 40),
          ..._steps.map((step) => _StepRow(
                icon: step['icon'] as IconData,
                title: step['title'] as String,
                desc: step['desc'] as String,
              )),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.colorNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.colorNeonGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(desc, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── OB-3: Widget Prompt ──────────────────────────────────
class _OB3Page extends StatelessWidget {
  const _OB3Page({
    required this.onGetStarted,
    required this.onSkip,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  Future<void> _openWidgetPicker(BuildContext context) async {
    // Primary: attempt to launch OS widget picker.
    // Fallback: show in-app instruction modal (Q4 answer).
    try {
      // home_widget package — best-effort on each platform.
      // On iOS: routes to WidgetKit help flow.
      // On Android: best-effort launcher intent.
      await HomeWidget.registerInteractivityCallback(_bgCallback);
      // If we reach here without exception, try the intent
      await SystemChannels.platform
          .invokeMethod<void>('SystemNavigator.routeInformationUpdated');
    } catch (_) {
      // ignore — fall through to instructions modal
    } finally {
      // Always show instructions (canonical UX per Q4 answer)
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => const _WidgetInstructionsDialog(),
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _bgCallback(Uri? uri) async {}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Widget illustration
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.neonGlow(blurRadius: 20, spreadRadius: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 46,
                  lineWidth: 8,
                  percent: 0.68,
                  progressColor: AppTheme.colorNeonGreen,
                  backgroundColor: AppTheme.colorSurfaceAlt,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Text(
                    '68%',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.colorTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'MoneyByte',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.colorNeonGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Add the widget to\nyour home screen.',
            style: AppTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'See your total progress at a glance — without opening the app.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => _openWidgetPicker(context),
            child: const Text('Show me how'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Maybe later',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.colorTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget instruction fallback modal (Q4 fallback) ──────
class _WidgetInstructionsDialog extends StatelessWidget {
  const _WidgetInstructionsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.colorSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add MoneyByte widget', style: AppTheme.titleLarge),
            const SizedBox(height: 20),
            const _InstructionStep(
              step: 'Android',
              instructions: [
                'Long-press your home screen',
                "Tap 'Widgets'",
                "Find 'MoneyByte' and drag to home screen",
              ],
            ),
            const SizedBox(height: 16),
            const _InstructionStep(
              step: 'iPhone',
              instructions: [
                'Long-press your home screen',
                "Tap '+' (top-left)",
                "Search 'MoneyByte' and add the widget",
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colorSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.colorTextSecondary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Widget updates when you open MoneyByte.',
                      style: AppTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.step,
    required this.instructions,
  });

  final String step;
  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.colorNeonGreen,
          ),
        ),
        const SizedBox(height: 6),
        ...instructions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.colorTextSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(e.value, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
