// web/admin/firebase.js

import {
  getDatabase,
  ref,
  onValue,
  push,
  update,
  set,
  get
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-database.js";

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";

// ✅ استخدام متغيرات البيئة من Firebase Hosting
const firebaseConfig = {
  apiKey: "{{FIREBASE_API_KEY}}",
  authDomain: "{{FIREBASE_AUTH_DOMAIN}}",
  databaseURL: "{{FIREBASE_DATABASE_URL}}",
  projectId: "{{FIREBASE_PROJECT_ID}}",
  storageBucket: "{{FIREBASE_STORAGE_BUCKET}}",
  messagingSenderId: "{{FIREBASE_MESSAGING_SENDER_ID}}",
  appId: "{{FIREBASE_APP_ID}}"
};

const app = initializeApp(firebaseConfig);
const db = getDatabase(app);

// ============================================================
// 🔑 الرمز الإداري (تم التحديث)
// ============================================================

// ✅ الرمز الجديد: Mando332011
const ADMIN_SECRET_KEY = "Mando332011";

// ============================================================
// 📊 دوال الإحصائيات
// ============================================================

export function getVisitors(callback) {
  const visitorsRef = ref(db, "visitors");
  onValue(visitorsRef, snapshot => callback(snapshot.val()));
}

export function incrementCounter(path) {
  const counterRef = ref(db, path);
  get(counterRef).then(snapshot => {
    const current = snapshot.val()?.count || 0;
    update(counterRef, { count: current + 1 });
  });
}

// ============================================================
// 🔐 دالة تسجيل دخول الإدارة
// ============================================================

export function loginAdmin(secretKey) {
  return new Promise((resolve, reject) => {
    // ✅ التحقق من الرمز Mando332011
    if (secretKey === ADMIN_SECRET_KEY) {
      sessionStorage.setItem("privoo_admin", "true");
      sessionStorage.setItem("privoo_admin_time", Date.now());
      resolve("success");
    } else {
      reject({ code: "auth/invalid-credentials" });
    }
  });
}

// ============================================================
// 🔓 دالة تسجيل الخروج
// ============================================================

export function logoutAdmin() {
  sessionStorage.removeItem("privoo_admin");
  sessionStorage.removeItem("privoo_admin_time");
}

// ============================================================
// ✅ التحقق من حالة تسجيل الدخول
// ============================================================

export function isAdminLoggedIn() {
  const isAdmin = sessionStorage.getItem("privoo_admin");
  const loginTime = sessionStorage.getItem("privoo_admin_time");
  
  if (isAdmin === "true" && loginTime) {
    const elapsed = Date.now() - parseInt(loginTime);
    if (elapsed < 8 * 60 * 60 * 1000) {
      return true;
    } else {
      logoutAdmin();
      return false;
    }
  }
  return false;
}

// ============================================================
// تصدير الأدوات
// ============================================================

export { db, ref, onValue, push, update, set, get };