# DZ MAP Flutter app

## المتطلبات
- Flutter 3.29+ وDart 3.7+ على الأقل للنسخة الأولية.
- Android Studio أو Android SDK حديث.
- JDK 21 موصى به لإصدارات MapLibre الحديثة.

## إنشاء ملفات المنصات
من داخل مجلد app نفّذ:

```bash
flutter create . --platforms=android,ios
flutter pub get
```

## إعداد رابط Style للخرائط
لا يوجد مزود خرائط إنتاجي مفعّل في المستودع حتى الآن. بعد اختيار مزود يسمح بالاستخدام التجاري، مرّر رابط MapLibre Style URL:

```bash
flutter run --dart-define=DZ_MAP_STYLE_URL=https://YOUR-LICENSED-PROVIDER/style.json
```

لا تستبدل الرابط بمصدر عشوائي أو بخادم بلاطات عام دون مراجعة شروطه. يجب أن يحتوي الـ style ومصادره على الإسناد المطلوب من المزود.

## ملاحظة
عند عدم إعداد DZ_MAP_STYLE_URL يعرض التطبيق شاشة توضيحية بدلاً من تحميل خريطة من مصدر غير معتمد.
