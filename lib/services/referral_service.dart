import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referral_model.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateReferralCode(String username, String uid) {
    final suffix = uid.length >= 4 ? uid.substring(uid.length - 4).toUpperCase() : uid.toUpperCase();
    return '${username.toUpperCase()}$suffix';
  }

  Future<String?> getReferrerIdByCode(String code) async {
    final snap = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> createReferral({
    required String referrerId,
    required String referrerCode,
    required String refereeId,
    required String refereeName,
    required String refereeEmail,
  }) async {
    await _firestore.collection('referrals').add(ReferralModel(
      id: '',
      referrerId: referrerId,
      referrerCode: referrerCode,
      refereeId: refereeId,
      refereeName: refereeName,
      refereeEmail: refereeEmail,
    ).toMap());
    await _firestore.collection('users').doc(referrerId).update({
      'referralCount': FieldValue.increment(1),
    });
  }

  Future<void> awardReferralBonus(String referralId, int amount) async {
    final batch = _firestore.batch();
    final referralRef = _firestore.collection('referrals').doc(referralId);
    batch.update(referralRef, {'bonusAwarded': true, 'bonusAmount': amount});
    final referralDoc = await referralRef.get();
    if (!referralDoc.exists) return;
    final data = referralDoc.data()!;
    final referrerId = data['referrerId'] as String?;
    if (referrerId == null) return;
    final walletRef = _firestore.collection('wallets').doc(referrerId);
    batch.update(walletRef, {'balance': FieldValue.increment(amount)});
    await batch.commit();
    await _firestore.collection('users').doc(referrerId).update({
      'referralEarnings': FieldValue.increment(amount),
    });
  }

  Stream<List<ReferralModel>> getReferrals(String userId) =>
      _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('joinedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ReferralModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());

  Future<int> getReferralCount(String userId) async {
    final snap = await _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getReferralEarnings(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return 0;
    return doc.data()?['referralEarnings'] as int? ?? 0;
  }

  Future<void> checkAndAwardReferralBonus(String refereeId, {int amount = 50}) async {
    final snap = await _firestore
        .collection('referrals')
        .where('refereeId', isEqualTo: refereeId)
        .where('bonusAwarded', isEqualTo: false)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await awardReferralBonus(snap.docs.first.id, amount);
  }
}
