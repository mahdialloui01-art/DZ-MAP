# DZ MAP Flutter app

## المتطلبات
- Flutter stable (المشروع يستخدم Dart 3.7+).
- Android SDK حديث.
- JDK الذي توفره بيئة Flutter/GitHub Actions.

## إنشاء ملفات Android محلياً
من داخل مجلد app نفّذ:
```bash
flutter create . --platforms=android --org dz.dzmap --project-name dz_map
flutter pub get
```

## إعداد رابط Style للخرائط
لا يوجد مزود خرائط إنتاجي مفعّل في المستودع حتى الآن. بعد اختيار مزود يسمح بالاستخدام التجاري، مرّر رابط MapLibre Style URL:
```bash
flutter run --dart-define=DZ_MAP_STYLE_URL=https://YOUR-LICENSED-PROVIDER/style.json
```
ويجب أيضاً تمرير إسناد المزود ورابط صفحة حقوقه عبر:
- `DZ_MAP_ATTRIBUTION`
- `DZ_MAP_ATTRIBUTION_URL`

لا تستبدل الرابط بمصدر عشوائي أو بخادم بلاطات عام دون مراجعة شروطه. عند عدم إعداد المتغيرات الثلاثة يعرض التطبيق شاشة توضيحية بدلاً من تحميل خريطة من مصدر غير معتمد.

## بناء APK آلياً
يوجد GitHub Actions workflow في `.github/workflows/build-apk.yml`. كل تحديث على `main` داخل `app/` يشغّل بناء APK بنسخة release، ويرفع الناتج كـ artifact باسم `dz-map-release-apk` لمدة 14 يوماً. من تبويب Actions في GitHub افتح آخر تشغيل ثم نزّل artifact.

## أذونات Android
الـ workflow ينشئ مشروع Android ويضيف أذونات الإنترنت والموقع التقريبي والدقيق. يطلب التطبيق إذن الموقع فقط عندما يضغط المستخدم زر «موقعي»، ولا يطلب الموقع في الخلفية.

## Google Play
إعداد target SDK في workflow هو API 36. هذا لا يعني أن التطبيق جاهز للنشر: يلزم اختيار مزود خرائط مرخص، إعداد مفاتيح الإنتاج بأمان، اختبار الخريطة والموقع على أجهزة فعلية، وتجهيز سياسة الخصوصية وبيانات الأمان وتوقيع النشر.
