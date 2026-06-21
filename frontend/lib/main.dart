import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/services/background_audio/background_audio.dart';
import 'core/services/download_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.init();
  } catch (_) {
    // Firebase non configuré — exécutez `flutterfire configure` pour activer les notifications.
  }
  try {
    await initBackground();
  } catch (_) {}
  await ThemeService().init();
  await DownloadService().init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Serigne Sam Mbaye',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().mode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
