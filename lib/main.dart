import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/data/datasources/local_storage.dart';
import 'core/data/providers.dart';
import 'core/platform/platform_init.dart';

final themeProviderOverride = ChangeNotifierProvider<ThemeProvider>(
  (ref) => ThemeProvider(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializePlatformServices();

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'An error occurred: ${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage(prefs, secureStorage)),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: const ElevateHRApp(),
    ),
  );
}

class ElevateHRApp extends ConsumerWidget {
  const ElevateHRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeProvider = ref.watch(themeProviderOverride);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}
