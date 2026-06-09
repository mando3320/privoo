// lib/controllers/lifetime_users.dart
// ✅ قائمة المستخدمين مدى الحياة (Lifetime) - مخزنة محلياً

/// قائمة أرقام الهواتف التي لديها اشتراك مدى الحياة (Lifetime)
/// ملاحظة: هذه القائمة هي المصدر الأساسي الآن (بدون Cloud Function)
const List<String> lifetimePhones = [
  '+201208499976',   // المطور الرئيسي
  // أضف أرقاماً أخرى هنا
];

/// قائمة أرقام المشرفين (Admin)
const List<String> adminPhones = [
  '+201208499976',   // المطور الرئيسي
  // أضف أرقام مشرفين آخرين هنا
];

/// التحقق مما إذا كان الرقم في قائمة Lifetime
bool isLifetimePhone(String phoneNumber) {
  return lifetimePhones.contains(phoneNumber);
}

/// التحقق مما إذا كان الرقم في قائمة المشرفين
bool isAdminPhone(String phoneNumber) {
  return adminPhones.contains(phoneNumber);
}

/// إضافة رقم جديد إلى القائمة (للتطوير فقط)
/// للتعديل الدائم، قم بتحديث const List أعلاه
void addLifetimePhoneDebug(String phoneNumber) {
  // هذا للإضافة المؤقتة فقط
  print('⚠️ لإضافة رقم دائم، قم بتحديث قائمة lifetimePhones في هذا الملف');
}