// lib/core/spending_simulator.dart
// NEW FILE — Do not modify existing files

const double kSimulatedMonthlyIncome = 50000.0;

class SimulatedTransaction {
  final String id;
  final String merchant;
  final String category;
  final double amount;
  final DateTime date;
  final String emoji;

  const SimulatedTransaction({
    required this.id,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    required this.emoji,
  });
}

class SpendingSimulator {
  // Category keys
  static const String kFood = 'Food & Delivery';
  static const String kEntertainment = 'Entertainment';
  static const String kShopping = 'Shopping';
  static const String kTransport = 'Transport';
  static const String kSavings = 'Savings';

  /// Safe thresholds as fraction of monthly income
  static const Map<String, double> kSafeThresholds = {
    kFood: 0.15,          // 15% → ₹7,500
    kEntertainment: 0.10, // 10% → ₹5,000
    kShopping: 0.20,      // 20% → ₹10,000
    kTransport: 0.08,     // 8%  → ₹4,000
    kSavings: 0.20,       // target > 20% → ₹10,000
  };

  static List<SimulatedTransaction> generate() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);

    // Deliberately overspending on Entertainment (~26%) and Shopping (~28%)
    return [
      // ── FOOD & DELIVERY (₹6,800 = 13.6% — SAFE) ──
      _t('txn_001', 'Zomato', kFood, 420, base.add(const Duration(days: 0)), '🍕'),
      _t('txn_002', 'Swiggy', kFood, 380, base.add(const Duration(days: 1)), '🍔'),
      _t('txn_003', 'Zomato', kFood, 290, base.add(const Duration(days: 3)), '🍜'),
      _t('txn_004', 'Blinkit', kFood, 650, base.add(const Duration(days: 4)), '🛒'),
      _t('txn_005', 'Swiggy', kFood, 510, base.add(const Duration(days: 6)), '🍱'),
      _t('txn_006', 'Zomato', kFood, 340, base.add(const Duration(days: 8)), '🍕'),
      _t('txn_007', 'Swiggy Instamart', kFood, 780, base.add(const Duration(days: 10)), '🛒'),
      _t('txn_008', 'Zomato', kFood, 460, base.add(const Duration(days: 12)), '🍔'),
      _t('txn_009', 'Swiggy', kFood, 390, base.add(const Duration(days: 14)), '🍜'),
      _t('txn_010', 'Blinkit', kFood, 520, base.add(const Duration(days: 16)), '🛒'),
      _t('txn_011', 'Zomato', kFood, 350, base.add(const Duration(days: 18)), '🍱'),
      _t('txn_012', 'Swiggy', kFood, 710, base.add(const Duration(days: 22)), '🍕'),
      _t('txn_013', 'Zomato', kFood, 400, base.add(const Duration(days: 26)), '🍔'),
      _t('txn_014', 'Swiggy', kFood, 600, base.add(const Duration(days: 29)), '🍜'),

      // ── ENTERTAINMENT (₹13,100 = 26.2% — HARMFUL) ──
      _t('txn_015', 'Netflix', kEntertainment, 649, base.add(const Duration(days: 1)), '🎬'),
      _t('txn_016', 'Spotify', kEntertainment, 119, base.add(const Duration(days: 1)), '🎵'),
      _t('txn_017', 'Amazon Prime', kEntertainment, 299, base.add(const Duration(days: 2)), '📺'),
      _t('txn_018', 'BGMI In-App', kEntertainment, 1600, base.add(const Duration(days: 5)), '🎮'),
      _t('txn_019', 'PVR Cinemas', kEntertainment, 780, base.add(const Duration(days: 7)), '🎥'),
      _t('txn_020', 'Disney+ Hotstar', kEntertainment, 299, base.add(const Duration(days: 8)), '📺'),
      _t('txn_021', 'Steam Game', kEntertainment, 1499, base.add(const Duration(days: 10)), '🎮'),
      _t('txn_022', 'PVR Cinemas', kEntertainment, 960, base.add(const Duration(days: 13)), '🎥'),
      _t('txn_023', 'BGMI In-App', kEntertainment, 2400, base.add(const Duration(days: 15)), '🎮'),
      _t('txn_024', 'YouTube Premium', kEntertainment, 189, base.add(const Duration(days: 16)), '📺'),
      _t('txn_025', 'SonyLIV', kEntertainment, 299, base.add(const Duration(days: 18)), '📺'),
      _t('txn_026', 'BGMI In-App', kEntertainment, 1600, base.add(const Duration(days: 20)), '🎮'),
      _t('txn_027', 'PVR Cinemas', kEntertainment, 860, base.add(const Duration(days: 24)), '🎥'),
      _t('txn_028', 'Steam DLC', kEntertainment, 999, base.add(const Duration(days: 27)), '🎮'),
      _t('txn_029', 'BGMI In-App', kEntertainment, 1549, base.add(const Duration(days: 29)), '🎮'),

      // ── SHOPPING (₹14,200 = 28.4% — HARMFUL) ──
      _t('txn_030', 'Myntra', kShopping, 1799, base.add(const Duration(days: 2)), '👕'),
      _t('txn_031', 'Amazon', kShopping, 2499, base.add(const Duration(days: 4)), '📦'),
      _t('txn_032', 'Meesho', kShopping, 649, base.add(const Duration(days: 6)), '👗'),
      _t('txn_033', 'Myntra', kShopping, 2100, base.add(const Duration(days: 9)), '👟'),
      _t('txn_034', 'Amazon', kShopping, 1350, base.add(const Duration(days: 11)), '📦'),
      _t('txn_035', 'Flipkart', kShopping, 899, base.add(const Duration(days: 13)), '🛍️'),
      _t('txn_036', 'Myntra', kShopping, 1499, base.add(const Duration(days: 16)), '👕'),
      _t('txn_037', 'Amazon', kShopping, 1890, base.add(const Duration(days: 19)), '📦'),
      _t('txn_038', 'Meesho', kShopping, 415, base.add(const Duration(days: 21)), '👗'),
      _t('txn_039', 'Flipkart', kShopping, 1099, base.add(const Duration(days: 25)), '🛍️'),

      // ── TRANSPORT (₹3,200 = 6.4% — SAFE) ──
      _t('txn_040', 'Uber', kTransport, 340, base.add(const Duration(days: 1)), '🚗'),
      _t('txn_041', 'Ola', kTransport, 280, base.add(const Duration(days: 3)), '🚗'),
      _t('txn_042', 'BMTC Metro', kTransport, 150, base.add(const Duration(days: 5)), '🚇'),
      _t('txn_043', 'Uber', kTransport, 490, base.add(const Duration(days: 8)), '🚗'),
      _t('txn_044', 'Rapido', kTransport, 120, base.add(const Duration(days: 11)), '🛵'),
      _t('txn_045', 'Ola', kTransport, 360, base.add(const Duration(days: 14)), '🚗'),
      _t('txn_046', 'BMTC Metro', kTransport, 150, base.add(const Duration(days: 17)), '🚇'),
      _t('txn_047', 'Uber', kTransport, 520, base.add(const Duration(days: 21)), '🚗'),
      _t('txn_048', 'Rapido', kTransport, 190, base.add(const Duration(days: 25)), '🛵'),
      _t('txn_049', 'Ola', kTransport, 400, base.add(const Duration(days: 28)), '🚗'),
      _t('txn_050', 'BMTC Metro', kTransport, 200, base.add(const Duration(days: 29)), '🚇'),

      // ── SAVINGS (₹5,000 = 10% — BELOW TARGET 20%) ──
      _t('txn_051', 'SBI RD', kSavings, 2000, base.add(const Duration(days: 1)), '💰'),
      _t('txn_052', 'MoneyByte Goal', kSavings, 1500, base.add(const Duration(days: 10)), '💰'),
      _t('txn_053', 'MoneyByte Goal', kSavings, 1500, base.add(const Duration(days: 20)), '💰'),
    ];
  }

  static SimulatedTransaction _t(
    String id, String merchant, String category, double amount, DateTime date, String emoji) {
    return SimulatedTransaction(
      id: id,
      merchant: merchant,
      category: category,
      amount: amount,
      date: date,
      emoji: emoji,
    );
  }

  /// Group transactions by category and sum amounts
  static Map<String, double> summarizeByCategory(List<SimulatedTransaction> txns) {
    final map = <String, double>{};
    for (final t in txns) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}