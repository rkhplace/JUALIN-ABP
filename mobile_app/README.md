# mobile_app

A new Flutter project.

## API backend

The app uses the deployed backend by default:

```bash
https://jualin-abp-production-cbe5.up.railway.app/api/v1
```

To run against another backend without editing source code:

```bash
flutter run --dart-define=API_BASE_URL=https://your-railway-service.up.railway.app/api/v1
```

For Android emulator with a local Laravel backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
