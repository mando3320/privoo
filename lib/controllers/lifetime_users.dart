// lib/controllers/lifetime_users.dart
// ✅ قائمة المستخدمين مدى الحياة (Lifetime) - مخزنة محلياً

/// قائمة أرقام الهواتف التي لديها اشتراك مدى الحياة (Lifetime)
const List<String> lifetimePhones = [
  '+201208499976',   // المطور الرئيسي
];

/// قائمة البريد الإلكتروني للمستخدمين مدى الحياة (Lifetime)
const List<String> lifetimeEmails = [
  'saberb45@gmail.com',    // المطور الرئيسي
  'saberb4546@gmail.com',  // نعمه
];

/// قائمة أرقام المشرفين (Admin)
const List<String> adminPhones = [
  '+201208499976',   // المطور الرئيسي
];

/// ✅ قائمة البريد الإلكتروني للمشرفين (Admin)
const List<String> adminEmails = [
  'saberb45@gmail.com',    // المطور الرئيسي
  'saberb4546@gmail.com',  // نعمه
];

/// التحقق مما إذا كان الرقم في قائمة Lifetime
bool isLifetimePhone(String phoneNumber) {
  return lifetimePhones.contains(phoneNumber);
}

/// التحقق مما إذا كان البريد الإلكتروني في قائمة Lifetime
bool isLifetimeEmail(String email) {
  return lifetimeEmails.contains(email);
}

/// التحقق مما إذا كان الرقم في قائمة المشرفين
bool isAdminPhone(String phoneNumber) {
  return adminPhones.contains(phoneNumber);
}

/// التحقق مما إذا كان البريد الإلكتروني في قائمة المشرفين
bool isAdminEmail(String email) {
  return adminEmails.contains(email);
}

/// إضافة رقم جديد إلى القائمة (للتطوير فقط)
void addLifetimePhoneDebug(String phoneNumber) {
  print('⚠️ لإضافة رقم دائم، قم بتحديث قائمة lifetimePhones في هذا الملف');
}