import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/services/background_audio/background_audio.dart';
import 'core/services/download_service.dart';
import 'core/services/font_scale_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Services synchrones légers — doivent être prêts avant le premier rendu.
  await ThemeService().init();
  await FontScaleService().init();
  await DownloadService().init();

  // Lance l'app immédiatement : plus de blanc/gel au démarrage.
  runApp(const App());

  // Services réseau initialisés en arrière-plan (Firebase, FCM, audio).
  // Ils sont prêts bien avant que l'utilisateur interagisse avec l'app.
  _initBackgroundServices();
}

Future<void> _initBackgroundServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.init();
  } catch (_) {}
  try {
    await initBackground();
  } catch (_) {}
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService(), FontScaleService()]),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Serigne Sam Mbaye',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().mode,
          routerConfig: AppRouter.router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(FontScaleService().scale)),
            child: child!,
          ),
        );
      },
    );
  }
}
