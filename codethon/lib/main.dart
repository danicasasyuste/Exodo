import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import '../widgets/global_btn_status.dart';
import '../widgets/asistente_btn.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('76df6edf-f7b8-4c71-9c70-7f25a558f2f9');

  OneSignal.Notifications.requestPermission(true);

  await NotificationService.init();

  await initializeDateFormatting('es_ES', null);

  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned(
              bottom: 20,
              right: 20,
              child: ValueListenableBuilder<bool>(
                valueListenable: GlobalConfig.mostrarBotonAsistente,
                builder: (context, visible, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        visible
                            ? const BotonAsistente()
                            : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        );
      },
      home: const IntroScreen(),
    );
  }
}
