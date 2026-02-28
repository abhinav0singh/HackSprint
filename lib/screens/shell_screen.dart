import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/all_goals_screen.dart';
import 'goals/add_edit_goal_screen.dart';
import 'analytics/analytics_screen.dart';

// ─────────────────────────────────────────────────────────
// ShellScreen  (PRD §4.1, Q3 answer)
//
// 3 tabs: Dashboard | Goals | Analytics
// FAB: '+' neon green, bottom-right (PRD §5.2)
// ─────────────────────────────────────────────────────────

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;

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
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
