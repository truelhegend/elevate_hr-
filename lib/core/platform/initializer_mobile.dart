import 'package:firebase_core/firebase_core.dart';
import '../../services/notification_service.dart';

Future<void> initializePlatformServices() async {
  await Firebase.initializeApp();
  await NotificationService().initialize();
}
