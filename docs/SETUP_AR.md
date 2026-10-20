# إعداد المشروع خطوة بخطوة

## أ. متطلبات التشغيل
- Flutter SDK حديث.
- Android Studio مع Android SDK، أو VS Code مع إضافات Flutter وDart.
- Python 3.11+ لتشغيل الخادم.
- مفتاح Gemini API اختياري للحصول على ردود فعلية.
- إعداد Firebase مطلوب لاحقًا لتفعيل Google Sign-In الحقيقي.

## ب. تشغيل الخادم محليًا على Windows
1. فك ضغط ZIP.
2. افتح VS Code وافتح مجلد `backend`.
3. افتح Terminal:
   ```powershell
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   copy .env.example .env
   ```
4. افتح `backend/.env` وأضف `GEMINI_API_KEY`.
5. شغّل:
   ```powershell
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
6. افتح المتصفح على `http://127.0.0.1:8000/health`.

## ج. تشغيل Flutter
افتح Terminal جديدًا في مجلد `app`:
```powershell
flutter create . --platforms android
flutter pub get
flutter run
```
في التطبيق افتح رمز الإعدادات وأبقِ عنوان الخادم `http://10.0.2.2:8000` عند استخدام Android Emulator.
للهاتف الحقيقي استخدم عنوان IPv4 للكمبيوتر، مثل `http://192.168.1.20:8000`، واسمح بالاتصال عبر جدار الحماية.

## د. إضافة Google Sign-In الفعلي
هذه النسخة لا تنفذ تسجيل Google الحقيقي بعد. لا يكفي وضع زر شكلي؛ يجب:
1. إنشاء مشروع Firebase.
2. إضافة تطبيق Android بالمعرّف `com.mosaedi.ai`.
3. تنزيل `google-services.json` ووضعه في `app/android/app/` بعد إنشاء ملفات Android.
4. تفعيل Google في Authentication.
5. إضافة حزم Firebase الخاصة بـ Flutter وإعداد Gradle.
6. إرسال Firebase ID token إلى الخادم.
7. التحقق من الرمز على الخادم باستخدام Firebase Admin SDK قبل استعمال UID الحقيقي في نظام الحصص.
لا تثق بقيمة `user_id` المرسلة من التطبيق كما هي.

## هـ. مزود احتياطي
يمكن ضبط `FALLBACK_BASE_URL`, `FALLBACK_API_KEY`, `FALLBACK_MODEL` لمزود يدعم OpenAI-compatible Chat Completions. لا تضع المفاتيح داخل Flutter. استخدم مزودًا لديك تصريح وحصة لاستخدامه.
