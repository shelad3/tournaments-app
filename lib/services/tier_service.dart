import '../models/user_tier.dart';
import 'user_stats_service.dart';

class TierService {
  UserTier calculateTier({
    required UserStats stats,
    required int accountAgeDays,
    required bool emailVerified,
  }) {
    if (_meetsRequirements(UserTier.platinum, stats, accountAgeDays, emailVerified)) {
      return UserTier.platinum;
    }
    if (_meetsRequirements(UserTier.gold, stats, accountAgeDays, emailVerified)) {
      return UserTier.gold;
    }
    if (_meetsRequirements(UserTier.silver, stats, accountAgeDays, emailVerified)) {
      return UserTier.silver;
    }
    return UserTier.bronze;
  }

  bool _meetsRequirements(UserTier tier, UserStats stats, int accountAgeDays, bool emailVerified) {
    if (stats.tournamentsPlayed < tier.minPlayed) return false;
    if (stats.winRate < tier.minWinRate) return false;
    if (accountAgeDays < tier.minAccountDays) return false;
    if (tier.requireEmailVerified && !emailVerified) return false;
    return true;
  }

  bool canAccess(UserTier userTier, UserTier requiredTier) {
    final tiers = UserTier.values;
    return tiers.indexOf(userTier) >= tiers.indexOf(requiredTier);
  }

  double progressToNext(UserStats stats, int accountAgeDays, bool emailVerified) {
    final current = calculateTier(stats: stats, accountAgeDays: accountAgeDays, emailVerified: emailVerified);
    final next = current.next;
    if (next == current) return 1.0;

    int met = 0;
    int total = 0;

    if (next.minPlayed > 0) {
      total++;
      if (stats.tournamentsPlayed >= next.minPlayed) met++;
    }
    if (next.minWinRate > 0) {
      total++;
      if (stats.winRate >= next.minWinRate) met++;
    }
    if (next.minAccountDays > 0) {
      total++;
      if (accountAgeDays >= next.minAccountDays) met++;
    }
    if (next.requireEmailVerified) {
      total++;
      if (emailVerified) met++;
    }

    if (total == 0) return 1.0;
    return met / total;
  }

  List<TierRequirement> getRequirementsForNext(UserStats stats, int accountAgeDays, bool emailVerified) {
    final current = calculateTier(stats: stats, accountAgeDays: accountAgeDays, emailVerified: emailVerified);
    final next = current.next;
    if (next == current) return [];

    final reqs = <TierRequirement>[];

    if (next.minPlayed > 0) {
      reqs.add(TierRequirement(
        label: 'Play ${next.minPlayed} tournaments',
        met: stats.tournamentsPlayed >= next.minPlayed,
        current: stats.tournamentsPlayed,
        target: next.minPlayed,
      ));
    }
    if (next.minWinRate > 0) {
      reqs.add(TierRequirement(
        label: '${next.minWinRate.toStringAsFixed(0)}% win rate',
        met: stats.winRate >= next.minWinRate,
        current: stats.winRate.toInt(),
        target: next.minWinRate.toInt(),
      ));
    }
    if (next.minAccountDays > 0) {
      reqs.add(TierRequirement(
        label: 'Account ${next.minAccountDays} days old',
        met: accountAgeDays >= next.minAccountDays,
        current: accountAgeDays,
        target: next.minAccountDays,
      ));
    }
    if (next.requireEmailVerified) {
      reqs.add(TierRequirement(
        label: 'Verify email',
        met: emailVerified,
        current: emailVerified ? 1 : 0,
        target: 1,
      ));
    }

    return reqs;
  }
}

class TierRequirement {
  final String label;
  final bool met;
  final int current;
  final int target;

  TierRequirement({
    required this.label,
    required this.met,
    required this.current,
    required this.target,
  });
}
