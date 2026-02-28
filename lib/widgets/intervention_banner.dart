// lib/widgets/intervention_banner.dart
// NEW FILE — Do not modify existing files

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterventionBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onSeeDetails; // navigate to Analytics tab

  const InterventionBanner({
    super.key,
    required this.message,
    this.onSeeDetails,
  });

  @override
  State<InterventionBanner> createState() => _InterventionBannerState();
}

class _InterventionBannerState extends State<InterventionBanner> {
  static const _prefKey = 'intervention_banner_dismissed_at';
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(_prefKey);
    if (dismissedAt != null) {
      final dismissedDate = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      // Reset weekly
      if (dismissedDate.isAfter(weekAgo)) {
        setState(() => _isDismissed = true);
      } else {
        // Expired — clear it
        await prefs.remove(_prefKey);
      }
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, DateTime.now().millisecondsSinceEpoch);
    setState(() => _isDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF9800), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Alert',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Color(0xFFB0B3BA),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onSeeDetails,
                        child: const Text(
                          'See Details',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _dismiss,
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(
                            color: Color(0xFF6B6F7A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}