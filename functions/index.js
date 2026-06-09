const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');
const NodeRSA = require('node-rsa');

// تهيئة Firebase Admin
admin.initializeApp();

// إعدادات CORS
const corsHandler = cors({ origin: true });

// ============================================================
// 1. قوائم المستخدمين المميزين (مخزنة بأمان في الخادم)
// ============================================================

// قائمة المستخدمين مدى الحياة (Lifetime)
const LIFETIME_PHONES = [
  '+201208499976',   // المطور
  // '+201112223334', // أضف أرقاماً أخرى هنا
];

// قائمة المشرفين (Admin)
const ADMIN_PHONES = [
  '+201208499976',
];

// ============================================================
// 2. خادم Health Check
// ============================================================
exports.health = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    res.status(200).json({ status: 'ok', timestamp: Date.now() });
  });
});

// ============================================================
// 3. التحقق من حالة المستخدم (Lifetime & Admin)
// ============================================================
exports.checkUserStatus = functions.https.onCall(async (data, context) => {
  const { phoneNumber } = data;
  
  if (!phoneNumber) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing phone number');
  }
  
  const isLifetime = LIFETIME_PHONES.includes(phoneNumber);
  const isAdmin = ADMIN_PHONES.includes(phoneNumber);
  
  // تسجيل النشاط للسجلات
  await admin.database().ref('log').push().set({
    type: 'status_check',
    phone: phoneNumber,
    isLifetime,
    isAdmin,
    timestamp: Date.now()
  });
  
  return {
    isPro: isLifetime,
    isLifetime: isLifetime,
    isAdmin: isAdmin,
    message: isLifetime ? '✅ اشتراك مدى الحياة مفعل' : '❌ اشتراك غير موجود'
  };
});

// ============================================================
// 4. الحصول على قائمة المشرفين (للمشرفين فقط)
// ============================================================
exports.getAdminPhones = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  
  const userId = context.auth.uid;
  const userRecord = await admin.auth().getUser(userId);
  const userPhone = userRecord.phoneNumber;
  
  if (!ADMIN_PHONES.includes(userPhone)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  return { admins: ADMIN_PHONES };
});

// ============================================================
// 5. خادم Blind Signature (Sealed Sender)
// ============================================================

let blindSignKey = null;

async function getBlindSignKey() {
  if (blindSignKey) return blindSignKey;
  
  const privateKeyPem = process.env.BLIND_SIGN_PRIVATE_KEY;
  if (privateKeyPem) {
    blindSignKey = new NodeRSA(privateKeyPem);
  } else {
    // توليد مفتاح مؤقت للتجربة
    blindSignKey = new NodeRSA({ b: 2048 });
    console.warn('⚠️ تم توليد مفتاح جديد مؤقت');
  }
  return blindSignKey;
}

// الحصول على المفتاح العام
exports.getBlindSignPublicKey = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const key = await getBlindSignKey();
  const publicKey = key.exportKey('public');
  return { publicKey: publicKey };
});

// التوقيع الأعمى
exports.blindSign = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { messageHash, recipientId } = data;
  const userId = context.auth.uid;
  
  if (!messageHash || !recipientId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }
  
  // Rate Limiting
  const rateLimitKey = `blind_sign:${userId}`;
  const rateLimitRef = admin.firestore().collection('rate_limits').doc(rateLimitKey);
  
  const now = Date.now();
  const windowStart = now - 60000;
  
  const doc = await rateLimitRef.get();
  let requests = doc.exists ? doc.data().timestamps || [] : [];
  requests = requests.filter(ts => ts > windowStart);
  
  if (requests.length >= 10) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
  }
  
  await rateLimitRef.set({ timestamps: [...requests, now] });
  
  try {
    const key = await getBlindSignKey();
    const messageBuffer = Buffer.from(messageHash, 'base64');
    const blindSignature = key.sign(messageBuffer, 'base64', 'buffer');
    
    return { 
      blindSignature: blindSignature.toString('base64'),
      timestamp: now,
    };
  } catch (error) {
    console.error('Blind sign error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate blind signature');
  }
});

// ============================================================
// 6. Отправка массовых уведомлений (callable)
// ============================================================
exports.sendBulkNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const callerUid = context.auth.uid;
  // Simple permission check: only admin phones in ADMIN_PHONES can send
  const callerUser = await admin.auth().getUser(callerUid);
  const callerPhone = callerUser.phoneNumber;
  if (!ADMIN_PHONES.includes(callerPhone)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const title = data.title || 'Privoo';
  const body = data.body || '';
  const topic = data.topic || 'all'; // default topic

  try {
    const message = {
      notification: { title, body },
      topic: topic,
      android: {
        priority: 'high'
      }
    };

    // send to topic
    const response = await admin.messaging().send(message);

    // Log
    await admin.firestore().collection('notifications').add({
      title,
      body,
      topic,
      sender: callerUid,
      timestamp: Date.now(),
      response
    });

    return { success: true, messageId: response };
  } catch (err) {
    console.error('sendBulkNotification error', err);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});