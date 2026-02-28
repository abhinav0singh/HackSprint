import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/behavior_provider.dart';   // ← NEW
import 'dashboard/dashboard_screen.dart';
import 'goals/all_goals_screen.dart';
import 'goals/add_edit_goal_screen.dart';
import 'analytics/analytics_screen.dart';

// ─────────────────────────────────────────────────────────
// ShellScreen  (PRD §4.1, Q3 answer)
//
// 3 tabs: Dashboard | Goals | Analytics
// FAB: '+' neon green, bottom-right (PRD §5.2)
// [NEW] Listens to shellTabIndexProvider so InterventionBanner's
//       "See Details" button can switch to Analytics (tab 2)
//       from anywhere without needing a Navigator push.
// ─────────────────────────────────────────────────────────

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  static const List<Widget> _screens = [
    DashboardScreen(),
    AllGoalsScreen(),
    AnalyticsScreen(),
  ];

  void _openAddGoal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditGoalScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── NEW: watch the shared tab-index provider ──────────
    // When DashboardScreen's InterventionBanner "See Details"
    // is tapped, it writes to shellTabIndexProvider (= 2),
    // which triggers a rebuild here and switches the tab.
    final tabIndex = ref.watch(shellTabIndexProvider);

    // Keep local state in sync if user taps the bottom nav bar
    // (we write back to the provider so both stay consistent).
    // ─────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: IndexedStack(
        index: tabIndex,            // ← was: _currentIndex
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,     // ← was: _currentIndex
        onTap: (i) {
          // ── NEW: write to provider instead of setState ──
          ref.read(shellTabIndexProvider.notifier).state = i;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoal,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}