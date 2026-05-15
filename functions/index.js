const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// ─── M-Pesa Config (set via `firebase functions:secrets:set`) ─────
const CONSUMER_KEY = defineString('MPESA_CONSUMER_KEY');
const CONSUMER_SECRET = defineString('MPESA_CONSUMER_SECRET');
const PASSKEY = defineString('MPESA_PASSKEY');
const SHORTCODE = defineString('MPESA_SHORTCODE');
const ENV = defineString('MPESA_ENVIRONMENT');

function baseUrl(env) {
  return env === 'production'
    ? 'https://api.safaricom.co.ke'
    : 'https://sandbox.safaricom.co.ke';
}

let accessToken = null;
let tokenExpiry = 0;

async function getToken(consumerKey, consumerSecret, env) {
  if (Date.now() < tokenExpiry) return accessToken;
  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
  const res = await axios.get(`${baseUrl(env)}/oauth/v1/generate?grant_type=client_credentials`, {
    headers: { Authorization: `Basic ${auth}` },
  });
  accessToken = res.data.access_token;
  tokenExpiry = Date.now() + (res.data.expires_in - 60) * 1000;
  return accessToken;
}

function timestamp() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  return `${y}${m}${d}${h}${min}${s}`;
}

function password(passkey, shortcode) {
  const ts = timestamp();
  return Buffer.from(`${shortcode}${passkey}${ts}`).toString('base64');
}

// ─── Helper: verify Firebase Auth ────────────────────────────────
function assertAuth(context) {
  if (!context.auth) throw new HttpsError('unauthenticated', 'You must be logged in');
}

// ===================================================================
// 1. STK Push (Deposit)
// ===================================================================
exports.stkPush = onCall(async (request) => {
    assertAuth(request);
    const { phone, amount, transactionRef } = request.data;
    if (!phone || !amount || !transactionRef) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    const ck = CONSUMER_KEY.value();
    const cs = CONSUMER_SECRET.value();
    const pk = PASSKEY.value();
    const sc = SHORTCODE.value();
    const env = ENV.value();

    const token = await getToken(ck, cs, env);
    const ts = timestamp();

    const payload = {
      BusinessShortCode: sc,
      Password: password(pk, sc),
      Timestamp: ts,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,
      PartyB: sc,
      PhoneNumber: phone,
      CallBackURL: `https://stkpush-us-central1.fc-tournaments-bc93a.cloudfunctions.net/mpesaCallback`,
      AccountReference: `FC${transactionRef}`,
      TransactionDesc: 'Tournaments Deposit',
    };

    try {
      const response = await axios.post(
        `${baseUrl(env)}/mpesa/stkpush/v1/processrequest`,
        payload,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      await db.collection('mpesa_requests').doc(transactionRef).set({
        userId: request.auth.uid,
        phone,
        amount,
        status: 'pending',
        checkoutRequestId: response.data.CheckoutRequestID,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        checkoutRequestId: response.data.CheckoutRequestID,
        responseDescription: response.data.ResponseDescription,
      };
    } catch (err) {
      console.error('STK Push error:', err.response?.data || err.message);
      throw new HttpsError('internal', err.response?.data?.errorMessage || err.message);
    }
  }
);

// ===================================================================
// 2. M-Pesa Callback (HTTP endpoint — Safaricom POSTs here)
// ===================================================================
exports.mpesaCallback = onRequest(async (req, res) => {
    try {
      const { Body } = req.body;
      if (!Body?.stkCallback) return res.json({ ResultCode: 1 });

      const { ResultCode, ResultDesc, CheckoutRequestID, CallbackMetadata } = Body.stkCallback;

      const snap = await db.collection('mpesa_requests')
        .where('checkoutRequestId', '==', CheckoutRequestID)
        .get();

      if (snap.empty) return res.json({ ResultCode: 1 });

      const doc = snap.docs[0];
      const data = doc.data();

      if (ResultCode === 0) {
        const items = CallbackMetadata?.Item || [];
        const amountItem = items.find(i => i.Name === 'Amount');
        const paidAmount = amountItem?.Value || data.amount;

        // Credit wallet
        await db.runTransaction(async (tx) => {
          const walletRef = db.collection('wallets').doc(data.userId);
          const walletDoc = await tx.get(walletRef);
          if (!walletDoc.exists) return;
          tx.update(walletRef, {
            balance: admin.firestore.FieldValue.increment(paidAmount),
            totalDeposited: admin.firestore.FieldValue.increment(paidAmount),
          });
        });

        // Record transaction
        await db.collection('transactions').add({
          userId: data.userId,
          type: 'deposit',
          amount: paidAmount,
          reference: doc.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await doc.ref.update({ status: 'completed', resultDesc: ResultDesc });
      } else {
        await doc.ref.update({ status: 'failed', resultDesc: ResultDesc });
      }

      res.json({ ResultCode: 0, ResultDesc: 'Success' });
    } catch (err) {
      console.error('Callback error:', err);
      res.json({ ResultCode: 1, ResultDesc: 'Error' });
    }
  }
);

// ===================================================================
// 3. Check Transaction Status
// ===================================================================
exports.checkTransactionStatus = onCall(async (request) => {
  assertAuth(request);
  const { ref } = request.data;
  if (!ref) throw new HttpsError('invalid-argument', 'Missing ref');

  const doc = await db.collection('mpesa_requests').doc(ref).get();
  if (!doc.exists) return { status: 'not_found' };
  return { status: doc.data().status };
});

function withdrawalFee(amount) {
  if (amount >= 50 && amount <= 1000) return 15;
  if (amount <= 5000) return 30;
  return 50;
}

// ===================================================================
// 4. Withdrawal (B2C) with Betika-style fee
// ===================================================================
exports.withdraw = onCall(async (request) => {
    assertAuth(request);
    const { phone, amount } = request.data;
    const userId = request.auth.uid;

    if (!phone || !amount) throw new HttpsError('invalid-argument', 'Missing fields');
    if (amount < 50) throw new HttpsError('invalid-argument', 'Minimum withdrawal is 50 KES');

    const fee = withdrawalFee(amount);
    const sendAmount = amount - fee;

    // Verify user identity
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) throw new HttpsError('not-found', 'User not found');
    const registeredPhone = userDoc.data().phoneNumber;
    if (registeredPhone !== phone) {
      throw new HttpsError('permission-denied', 'Phone number does not match your registered number');
    }

    // Check balance
    const walletDoc = await db.collection('wallets').doc(userId).get();
    if (!walletDoc.exists) throw new HttpsError('not-found', 'Wallet not found');
    const balance = walletDoc.data().balance || 0;
    if (balance < amount) throw new HttpsError('failed-precondition', 'Insufficient balance');

    // Deduct from wallet, credit fee to platform
    await db.runTransaction(async (tx) => {
      const ref = db.collection('wallets').doc(userId);
      const sRef = db.collection('admin').doc('super_wallet');
      const doc = await tx.get(ref);
      const sDoc = await tx.get(sRef);

      tx.update(ref, {
        balance: admin.firestore.FieldValue.increment(-amount),
        totalWithdrawn: admin.firestore.FieldValue.increment(amount),
      });

      if (sDoc.exists) {
        tx.update(sRef, {
          platformEarnings: admin.firestore.FieldValue.increment(fee),
          totalProcessed: admin.firestore.FieldValue.increment(fee),
        });
      } else {
        tx.set(sRef, {
          prizePool: 0,
          platformEarnings: fee,
          totalProcessed: fee,
        });
      }
    });

    // Record withdrawal transaction
    await db.collection('transactions').add({
      userId,
      type: 'withdrawal',
      amount,
      fee,
      reference: `wd_${Date.now()}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Initiate B2C (if production credentials)
    try {
      const env = ENV.value();
      if (env === 'production') {
        const ck = CONSUMER_KEY.value();
        const cs = CONSUMER_SECRET.value();
        const sc = SHORTCODE.value();
        const token = await getToken(ck, cs, env);
        await axios.post(
          `${baseUrl(env)}/mpesa/b2c/v1/paymentrequest`,
          {
            InitiatorName: 'testapi',
            SecurityCredential: '',
            CommandID: 'BusinessPayment',
            Amount: sendAmount,
            PartyA: sc,
            PartyB: phone,
            Remarks: 'Tournaments Withdrawal',
            QueueTimeOutURL: `https://stkpush-us-central1.fc-tournaments-bc93a.cloudfunctions.net/b2cTimeout`,
            ResultURL: `https://stkpush-us-central1.fc-tournaments-bc93a.cloudfunctions.net/b2cResult`,
          },
          { headers: { Authorization: `Bearer ${token}` } }
        );
      }
    } catch (err) {
      console.error('B2C error:', err.message);
    }

    return { success: true, message: `Withdrawal processed (${sendAmount} KES sent, ${fee} KES fee)` };
  }
);

// ===================================================================
// 5. Pay Tournament Fee
// ===================================================================
exports.payTournamentFee = onCall(async (request) => {
  assertAuth(request);
  const { tournamentId } = request.data;
  const userId = request.auth.uid;

  if (!tournamentId) throw new HttpsError('invalid-argument', 'Missing tournamentId');

  const tournamentDoc = await db.collection('tournaments').doc(tournamentId).get();
  if (!tournamentDoc.exists) throw new HttpsError('not-found', 'Tournament not found');
  const baseFee = tournamentDoc.data().entryFee;
  if (!baseFee) throw new HttpsError('failed-precondition', 'Tournament has no entry fee');

  const totalFee = baseFee + Math.floor(baseFee * 5 / 30);
  const platformFee = totalFee - baseFee;

  await db.runTransaction(async (tx) => {
    const wRef = db.collection('wallets').doc(userId);
    const sRef = db.collection('admin').doc('super_wallet');
    const wDoc = await tx.get(wRef);
    if (!wDoc.exists) throw new HttpsError('failed-precondition', 'Wallet not found');
    const bal = wDoc.data().balance || 0;
    if (bal < totalFee) throw new HttpsError('failed-precondition', 'Insufficient balance');

    const sDoc = await tx.get(sRef);

    tx.update(wRef, {
      balance: admin.firestore.FieldValue.increment(-totalFee),
      totalSpent: admin.firestore.FieldValue.increment(totalFee),
    });

    if (sDoc.exists) {
      tx.update(sRef, {
        prizePool: admin.firestore.FieldValue.increment(baseFee),
        platformEarnings: admin.firestore.FieldValue.increment(platformFee),
        totalProcessed: admin.firestore.FieldValue.increment(totalFee),
      });
    } else {
      tx.set(sRef, {
        prizePool: baseFee,
        platformEarnings: platformFee,
        totalProcessed: totalFee,
      });
    }
  });

  await db.collection('transactions').add({
    userId, type: 'tournamentFee', amount: baseFee, reference: tournamentId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (platformFee > 0) {
    await db.collection('transactions').add({
      userId, type: 'platformFee', amount: platformFee, reference: tournamentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return { success: true };
});

// ===================================================================
// 6. Award Prize (multi-position)
// ===================================================================
exports.awardPrize = onCall(async (request) => {
  assertAuth(request);

  const adminDoc = await db.collection('users').doc(request.auth.uid).get();
  const adminRole = adminDoc.data()?.role;
  if (!adminRole || !['admin', 'superAdmin', 'subAdmin'].includes(adminRole)) {
    throw new HttpsError('permission-denied', 'Only admins can award prizes');
  }

  const { tournamentId, prizes } = request.data;
  if (!tournamentId || !prizes || typeof prizes !== 'object') {
    throw new HttpsError('invalid-argument', 'Missing or invalid fields: tournamentId and prizes map required');
  }

  const winnerIds = Object.keys(prizes);
  if (winnerIds.length === 0) throw new HttpsError('invalid-argument', 'At least one winner required');

  const totalPrizes = Object.values(prizes).reduce((sum, v) => sum + (v || 0), 0);
  if (totalPrizes <= 0) throw new HttpsError('invalid-argument', 'Total prize amount must be positive');

  const tournamentDoc = await db.collection('tournaments').doc(tournamentId).get();
  if (!tournamentDoc.exists) throw new HttpsError('not-found', 'Tournament not found');

  await db.runTransaction(async (tx) => {
    const sRef = db.collection('admin').doc('super_wallet');
    const sDoc = await tx.get(sRef);
    if (!sDoc.exists) throw new HttpsError('failed-precondition', 'Super wallet not found');

    const prizePool = sDoc.data().prizePool || 0;
    if (prizePool < totalPrizes) {
      throw new HttpsError('failed-precondition', `Insufficient prize pool. Need ${totalPrizes}, have ${prizePool}`);
    }

    tx.update(sRef, { prizePool: admin.firestore.FieldValue.increment(-totalPrizes) });

    for (const [userId, amount] of Object.entries(prizes)) {
      if (!amount || amount <= 0) continue;
      const wRef = db.collection('wallets').doc(userId);
      const wDoc = await tx.get(wRef);
      if (wDoc.exists) {
        tx.update(wRef, {
          balance: admin.firestore.FieldValue.increment(amount),
          totalPrizeReceived: admin.firestore.FieldValue.increment(amount),
        });
      } else {
        tx.set(wRef, {
          balance: amount,
          totalPrizeReceived: amount,
        });
      }
    }
  });

  const batch = db.batch();
  for (const [userId, amount] of Object.entries(prizes)) {
    if (!amount || amount <= 0) continue;
    const txRef = db.collection('transactions').doc();
    batch.set(txRef, {
      userId, type: 'prizeWon', amount, reference: tournamentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  return { success: true, totalAmount: totalPrizes, winners: winnerIds.length };
});

// ===================================================================
// 7. Chat Notification
// ===================================================================
exports.notifyChat = onCall(async (request) => {
  assertAuth(request);
  const { tournamentId, message } = request.data;
  const senderName = request.auth.token.name || 'Someone';

  const partsSnap = await db.collection('participations')
    .where('tournamentId', '==', tournamentId)
    .where('accepted', '==', true)
    .get();

  const tokens = [];
  for (const doc of partsSnap.docs) {
    const uid = doc.data().userId;
    if (uid === request.auth.uid) continue;
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      const token = userDoc.data()?.fcmToken;
      if (token) tokens.push(token);
    }
  }

  if (tokens.length === 0) return { success: true, sent: 0 };

  const payload = {
    tokens,
    notification: { title: senderName, body: message },
    data: { type: 'tournament_chat', tournamentId },
  };

  const response = await admin.messaging().sendEachForMulticast(payload);
  return { success: true, sent: response.successCount, failed: response.failureCount };
});

// ===================================================================
// 8. B2C Timeout & Result endpoints (for M-Pesa callbacks)
// ===================================================================
exports.b2cTimeout = onRequest((req, res) => {
  console.log('B2C Timeout:', req.body);
  res.json({ ResultCode: 0 });
});

exports.b2cResult = onRequest((req, res) => {
  console.log('B2C Result:', JSON.stringify(req.body, null, 2));
  res.json({ ResultCode: 0 });
});

// ===================================================================
// 9. Delete Account
// ===================================================================
exports.deleteAccount = onCall({ enforceAppCheck: false }, async (request) => {
  assertAuth(request);
  const userId = request.auth.uid;

  // Delete all user data
  const batch = db.batch();

  // User doc
  batch.delete(db.collection('users').doc(userId));

  // Wallet
  batch.delete(db.collection('wallets').doc(userId));

  // FCM tokens
  const tokenSnap = await db.collection('fcm_tokens').where('userId', '==', userId).get();
  tokenSnap.docs.forEach(d => batch.delete(d.ref));

  // Participations
  const partSnap = await db.collection('participations').where('userId', '==', userId).get();
  partSnap.docs.forEach(d => batch.delete(d.ref));

  // Follows (as follower)
  const followSnap = await db.collection('follows').where('followerId', '==', userId).get();
  followSnap.docs.forEach(d => batch.delete(d.ref));

  // Follows (as followed)
  const followedSnap = await db.collection('follows').where('followingId', '==', userId).get();
  followedSnap.docs.forEach(d => batch.delete(d.ref));

  // Forum messages
  const forumSnap = await db.collection('forum_messages').where('userId', '==', userId).get();
  forumSnap.docs.forEach(d => batch.delete(d.ref));

  // Transactions
  const txSnap = await db.collection('transactions').where('userId', '==', userId).get();
  txSnap.docs.forEach(d => batch.delete(d.ref));

  await batch.commit();

  // Delete Firebase Auth account
  await admin.auth().deleteUser(userId);

  return { success: true };
});

// ===================================================================
// 10. Waiting List Auto-Promote
// ===================================================================
exports.autoPromoteFromWaitingList = onDocumentDeleted('participations/{docId}', async (event) => {
  const deletedData = event.data?.data();
  if (!deletedData) return;

  const tournamentId = deletedData.tournamentId;
  if (!tournamentId) return;

  // Check if the tournament still exists and has room
  const tournDoc = await db.collection('tournaments').doc(tournamentId).get();
  if (!tournDoc.exists) return;
  const maxP = tournDoc.data().maxParticipants;
  if (!maxP) return; // no max, no need to promote

  const currentCount = await db.collection('participations')
    .where('tournamentId', '==', tournamentId)
    .where('accepted', '==', true)
    .count().get();

  const acceptedCount = currentCount.data().count || 0;
  if (acceptedCount >= maxP) return; // no room

  // Promote next from waiting list
  const waitingSnap = await db.collection('waiting_list')
    .where('tournamentId', '==', tournamentId)
    .orderBy('createdAt')
    .limit(1)
    .get();

  if (waitingSnap.docs.length === 0) return;

  const waitingDoc = waitingSnap.docs[0];
  const promotedUserId = waitingDoc.data().userId;

  // Create participation
  await db.collection('participations').add({
    userId: promotedUserId,
    tournamentId,
    vote: 'yes',
    accepted: true,
    paid: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Remove from waiting list
  await waitingDoc.ref.delete();

  // Send notification
  const userDoc = await db.collection('users').doc(promotedUserId).get();
  const fcmToken = userDoc.data()?.fcmToken;
  if (fcmToken) {
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'Spot Available!',
          body: `A spot opened up in a tournament you were waiting for. You've been auto-registered!`,
        },
      });
    } catch (_) { /* token may be stale */ }
  }

  const notifRef = db.collection('notifications').doc(promotedUserId).collection('items');
  await notifRef.add({
    title: 'Spot Available!',
    body: `A spot opened up in a tournament. You've been auto-registered from the waiting list.`,
    type: 'waiting_promotion',
    tournamentId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
