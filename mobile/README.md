# Flutter app setup

Prerequisites: Flutter stable, Android Studio/Android SDK, JDK 17, Firebase project.

```bash
flutter create .
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
flutter run
```

If FlutterFire generated `lib/firebase_options.dart`, update `main.dart` to import it and initialize with `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. Add Android notification permission and FCM token registration before claiming push notifications are implemented. This starter currently demonstrates Firebase email auth, a live product stream, search, quantity controls and demo order creation. It is not yet the full customer/dealer feature set: use `IMPLEMENTATION_PLAN.md` as the remaining checklist.
