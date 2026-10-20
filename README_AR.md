# Mosaedi AI Flutter — مشروع بداية متكامل

هذه حزمة مشروع قابلة للتطوير تحتوي على تطبيق Flutter وواجهة خلفية Python/FastAPI.
**مهم:** لا يمكن جعل تسجيل Google أو مفاتيح مزودي الذكاء الاصطناعي تعمل قبل إعداد حساباتك ومفاتيحك. كما أن الحصص المجانية ليست مضمونة ولا يمكن تجاوز حدود المزودين.

## محتويات المشروع
- `app/`: واجهة Flutter عربية RTL، محادثة، إعدادات الخادم، وحفظ محلي بسيط للمحادثة.
- `backend/`: خادم FastAPI، نقاط فحص الصحة والمحادثة، اختيار Gemini ثم مزود OpenAI-compatible اختياري.
- `docs/SETUP_AR.md`: تعليمات التشغيل.
- `.env.example`: قالب إعدادات الخادم.

## تشغيل الخادم
1. ثبّت Python 3.11 أو أحدث.
2. افتح الطرفية داخل `backend`.
3. نفّذ:
   ```bash
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate
   # macOS/Linux:
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
4. انسخ `.env.example` إلى `.env` واملأ مفتاح Gemini اختياريًا.
5. شغّل:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
6. افتح `http://127.0.0.1:8000/health`.

## تشغيل Flutter
1. ثبّت Flutter SDK وAndroid Studio أو VS Code.
2. افتح مجلد `app`.
3. أنشئ ملفات المنصة إذا لم تكن موجودة:
   ```bash
   flutter create . --platforms android
   flutter pub get
   flutter run
   ```
4. في صفحة الإعدادات داخل التطبيق، أدخل عنوان الخادم:
   - Android Emulator: `http://10.0.2.2:8000`
   - هاتف فعلي: `http://IP-الكمبيوتر-على-الشبكة:8000` مع وجود الجهازين على الشبكة نفسها.
   - لا تستخدم عنوان localhost من الهاتف الفعلي.

## تسجيل الدخول بحساب Google
الواجهة الخلفية هنا لا تدّعي التحقق من Google تلقائيًا، والتطبيق الحالي لا يفعّل Google Sign-In افتراضيًا. لتفعيله:
- أنشئ مشروع Firebase.
- أضف تطبيق Android باستخدام package name `com.mosaedi.ai`.
- نزّل `google-services.json` إلى `app/android/app/`.
- فعّل Google provider في Firebase Authentication.
- أضف الحزم وإعدادات Android وفق وثائق Firebase Flutter الرسمية، ثم أرسل Firebase ID token للخادم وتحقق منه على الخادم باستخدام Firebase Admin SDK قبل ربط الحصة بالحساب.

## الحصص ومزودو الذكاء الاصطناعي
- مفتاح المزود يوضع في الخادم فقط، وليس في Flutter.
- مثال Gemini API عبر `GEMINI_API_KEY`.
- المزود البديل اختياري عبر `FALLBACK_BASE_URL`, `FALLBACK_API_KEY`, `FALLBACK_MODEL` إذا كان لديك مزود يسمح بذلك.
- حدود مزودي API غالبًا تُحسب على مستوى مشروع/حساب المزود، وليست حصة مستقلة مضمونة لكل مستخدم Google.
- الحصة اليومية الموجودة في هذا النموذج داخل الذاكرة للتجربة فقط؛ تُصفّر عند إعادة تشغيل الخادم. قبل النشر استبدلها بقاعدة بيانات مثل PostgreSQL/Redis وأضف تحقق Google حقيقيًا ومحددات معدل.
- لا تتجاوز شروط المزود أو حدود الخطة المجانية؛ إذا انتهت حصص كل المزودين، يعرض التطبيق رسالة واضحة.

## بناء APK
بعد إعداد Flutter:
```bash
cd app
flutter build apk --release
```
الملف الناتج عادةً في `app/build/app/outputs/flutter-apk/app-release.apk`.

هذه حزمة بداية تشغيلية، وليست تطبيقًا منشورًا أو نظام إنتاج جاهزًا دون إعداد واختبار أمني.
