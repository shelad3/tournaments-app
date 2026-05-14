const express = require('express');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// ─── Firebase Init ───────────────────────────────────────
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});
const db = admin.firestore();

// ─── M-Pesa Config ──────────────────────────────────────
const CONSUMER_KEY = process.env.MPESA_CONSUMER_KEY;
const CONSUMER_SECRET = process.env.MPESA_CONSUMER_SECRET;
const PASSKEY = process.env.MPESA_PASSKEY;
const SHORTCODE = process.env.MPESA_SHORTCODE || '174379';
const ENV = process.env.MPESA_ENVIRONMENT || 'sandbox';
const BASE_URL = ENV === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

let accessToken = null;
let tokenExpiry = 0;

async function getToken() {
  if (Date.now() < tokenExpiry) return accessToken;
  const auth = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString('base64');
  const res = await axios.get(`${BASE_URL}/oauth/v1/generate?grant_type=client_credentials`, {
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

function password() {
  const ts = timestamp();
  const str = `${SHORTCODE}${PASSKEY}${ts}`;
  return Buffer.from(str).toString('base64');
}

// ─── STK Push (Deposit) ─────────────────────────────────
// Flutter calls this → user receives M-Pesa prompt on phone
app.post('/api/mpesa/stkpush', async (req, res) => {
  try {
    const { phone, amount, userId, transactionRef } = req.body;
    const token = await getToken();
    const ts = timestamp();

    const payload = {
      BusinessShortCode: SHORTCODE,
      Password: password(),
      Timestamp: ts,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,           // user's phone number
      PartyB: SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: `${process.env.CALLBACK_URL}/api/mpesa/callback`,
      AccountReference: `FC${transactionRef}`,
      TransactionDesc: 'FC Tournaments Deposit',
    };

    const response = await axios.post(
      `${BASE_URL}/mpesa/stkpush/v1/processrequest`,
      payload,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    // Save pending transaction
    await db.collection('mpesa_requests').doc(transactionRef).set({
      userId,
      phone,
      amount,
      status: 'pending',
      checkoutRequestId: response.data.CheckoutRequestID,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      success: true,
      checkoutRequestId: response.data.CheckoutRequestID,
      responseDescription: response.data.ResponseDescription,
    });
  } catch (err) {
    console.error('STK Push error:', err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Callback (M-Pesa hits this after user enters PIN) ──
app.post('/api/mpesa/callback', async (req, res) => {
  try {
    const { Body } = req.body;
    if (!Body?.stkCallback) return res.json({ ResultCode: 1 });

    const { ResultCode, ResultDesc, CheckoutRequestID, CallbackMetadata } = Body.stkCallback;

    // Find the pending request
    const snap = await db.collection('mpesa_requests')
      .where('checkoutRequestId', '==', CheckoutRequestID)
      .get();

    if (snap.empty) return res.json({ ResultCode: 1 });

    const doc = snap.docs[0];
    const data = doc.data();

    if (ResultCode === 0) {
      // Payment successful — extract amount paid from metadata
      const items = CallbackMetadata?.Item || [];
      const amountItem = items.find(i => i.Name === 'Amount');
      const paidAmount = amountItem?.Value || data.amount;

      // Credit user's wallet
      const walletRef = db.collection('wallets').doc(data.userId);
      await db.runTransaction(async (tx) => {
        const walletDoc = await tx.get(walletRef);
        if (!walletDoc.exists) return;
        const wallet = walletDoc.data();
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

      // Mark request as completed
      await doc.ref.update({ status: 'completed', resultDesc: ResultDesc });
    } else {
      await doc.ref.update({ status: 'failed', resultDesc: ResultDesc });
    }

    res.json({ ResultCode: 0, ResultDesc: 'Success' });
  } catch (err) {
    console.error('Callback error:', err);
    res.json({ ResultCode: 1, ResultDesc: 'Error' });
  }
});

// ─── B2C (Withdrawal) ────────────────────────────────────
app.post('/api/mpesa/b2c', async (req, res) => {
  try {
    const { phone, amount, userId } = req.body;
    const token = await getToken();

    const payload = {
      InitiatorName: 'testapi',
      SecurityCredential: process.env.MPESA_SECURITY_CREDENTIAL || '',
      CommandID: 'BusinessPayment',
      Amount: amount,
      PartyA: SHORTCODE,
      PartyB: phone,
      Remarks: 'FC Tournaments Withdrawal',
      QueueTimeOutURL: `${process.env.CALLBACK_URL}/api/mpesa/b2c-timeout`,
      ResultURL: `${process.env.CALLBACK_URL}/api/mpesa/b2c-result`,
    };

    await axios.post(
      `${BASE_URL}/mpesa/b2c/v1/paymentrequest`,
      payload,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    res.json({ success: true, message: 'Withdrawal initiated' });
  } catch (err) {
    console.error('B2C error:', err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Check Transaction Status ────────────────────────────
app.get('/api/mpesa/status/:ref', async (req, res) => {
  const doc = await db.collection('mpesa_requests').doc(req.params.ref).get();
  if (!doc.exists) return res.json({ status: 'not_found' });
  res.json({ status: doc.data().status });
});

// ─── Health Check ────────────────────────────────────────
app.get('/api/health', (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`M-Pesa server running on port ${PORT}`));
