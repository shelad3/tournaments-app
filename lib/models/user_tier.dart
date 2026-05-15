enum UserTier { bronze, silver, gold, platinum }

extension UserTierExt on UserTier {
  String get label {
    switch (this) {
      case UserTier.bronze: return 'Bronze';
      case UserTier.silver: return 'Silver';
      case UserTier.gold: return 'Gold';
      case UserTier.platinum: return 'Platinum';
    }
  }

  int get minPlayed {
    switch (this) {
      case UserTier.bronze: return 0;
      case UserTier.silver: return 5;
      case UserTier.gold: return 20;
      case UserTier.platinum: return 50;
    }
  }

  double get minWinRate {
    switch (this) {
      case UserTier.bronze: return 0;
      case UserTier.silver: return 0;
      case UserTier.gold: return 40;
      case UserTier.platinum: return 55;
    }
  }

  int get minAccountDays {
    switch (this) {
      case UserTier.bronze: return 0;
      case UserTier.silver: return 0;
      case UserTier.gold: return 30;
      case UserTier.platinum: return 90;
    }
  }

  bool get requireEmailVerified {
    switch (this) {
      case UserTier.bronze: return false;
      case UserTier.silver: return true;
      case UserTier.gold: return true;
      case UserTier.platinum: return true;
    }
  }

  UserTier get next {
    switch (this) {
      case UserTier.bronze: return UserTier.silver;
      case UserTier.silver: return UserTier.gold;
      case UserTier.gold: return UserTier.platinum;
      case UserTier.platinum: return UserTier.platinum;
    }
  }

  String get iconPath {
    switch (this) {
      case UserTier.bronze: return '🥉';
      case UserTier.silver: return '🥈';
      case UserTier.gold: return '🥇';
      case UserTier.platinum: return '💎';
    }
  }
}
