import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────
// MoneyByte Constants  (PRD §2.1, §5.5, §6, §9)
// ─────────────────────────────────────────────────────────

// ── Category icon asset paths ────────────────────────────
const String kIconLaptop   = 'assets/icons/laptop.svg';
const String kIconPlane    = 'assets/icons/plane.svg';
const String kIconCar      = 'assets/icons/car.svg';
const String kIconBook     = 'assets/icons/book.svg';
const String kIconPhone    = 'assets/icons/phone.svg';
const String kIconHome     = 'assets/icons/home.svg';
const String kIconCamera   = 'assets/icons/camera.svg';
const String kIconBicycle  = 'assets/icons/bicycle.svg';
const String kIconGift     = 'assets/icons/gift.svg';
const String kIconRing     = 'assets/icons/ring.svg';
const String kIconGamepad  = 'assets/icons/gamepad.svg';
const String kIconDumbbell = 'assets/icons/dumbbell.svg';
const String kIconDefault  = 'assets/icons/default.svg';

/// All 12 category icons in display order.
const List<String> kIconList = [
  kIconLaptop,
  kIconPlane,
  kIconCar,
  kIconBook,
  kIconPhone,
  kIconHome,
  kIconCamera,
  kIconBicycle,
  kIconGift,
  kIconRing,
  kIconGamepad,
  kIconDumbbell,
];

/// Human-readable labels for each icon (same order as kIconList).
const List<String> kIconLabels = [
  'Gadgets',
  'Travel',
  'Vehicle',
  'Education',
  'Phone',
  'Home',
  'Camera',
  'Bicycle',
  'Gifts',
  'Jewellery',
  'Gaming',
  'Fitness',
];

// ── Accent color swatches ────────────────────────────────
/// 8 neon/bright swatches that work on the dark background.
/// Error red (#FF5252) is intentionally excluded per PRD §6.1.
const List<String> kAccentSwatches = [
  '00E676', // Neon green  (primary)
  '00B0FF', // Neon cyan
  'FF9800', // Recovery amber
  'FF4081', // Neon pink
  '8E24AA', // Neon purple
  'FFD600', // Neon yellow
  '00C853', // Neon teal
  '2979FF', // Electric blue
];

// ── SharedPreferences keys ───────────────────────────────
const String kPrefsOnboardingComplete  = 'onboarding_complete';
const String kPrefsWidgetSnapshot      = 'moneybyte_widget_snapshot';

// ── INR Formatter (§9) ───────────────────────────────────
/// Always use this. Never use Western locale formatting.
final NumberFormat inrFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'INR ',
  decimalDigits: 0,
);

/// Compact formatter for small amounts (< 1 lakh).
/// Returns full INR string — use [inrCompact] for lakh/crore labels.
String formatInr(double amount) => inrFormatter.format(amount);

/// Returns a compact label like '1.5 L' or '2.3 Cr'.
/// Used inside the ring center text per PRD §5.2.1.
String inrCompact(double amount) {
  if (amount >= 1e7) {
    final cr = amount / 1e7;
    return 'INR ${_compact(cr)} Cr';
  } else if (amount >= 1e5) {
    final l = amount / 1e5;
    return 'INR ${_compact(l)} L';
  } else {
    return formatInr(amount);
  }
}

String _compact(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

// ── Accent color helper ──────────────────────────────────
/// Parse a hex string like '00E676' into a [Color].
Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// ── Analytics category tag ───────────────────────────────
/// Returns a human-readable label for an icon path.
String iconLabel(String iconPath) {
  final idx = kIconList.indexOf(iconPath);
  if (idx == -1) return 'Goal';
  return kIconLabels[idx];
}
