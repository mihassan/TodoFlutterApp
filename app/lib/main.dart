import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/providers/theme_provider.dart';
import 'package:todo_flutter_app/app/router.dart';
import 'package:todo_flutter_app/app/theme.dart';
import 'package:todo_flutter_app/firebase_options.dart';

/// Whether to use Firebase Emulators instead of production services.
///
/// Pass `--dart-define=USE_FIREBASE_EMULATORS=true` when running:
/// ```sh
/// flutter run --dart-define=USE_FIREBASE_EMULATORS=true
/// ```
const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulators) {
    await _connectToEmulators();
  }

  runApp(const ProviderScope(child: TodoApp()));
}

Future<void> _connectToEmulators() async {
  const host = '10.0.2.2'; // Android emulator → host machine

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);

  if (kDebugMode) {
    debugPrint('🔧 Connected to Firebase Emulators at $host');
  }
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    return themeModeAsync.when(
      data: (themeMode) {
        return MaterialApp.router(
          title: 'Todo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode.toFlutterThemeMode(),
          routerConfig: router,
        );
      },
      loading: () {
        // Show a loading screen while theme preference loads
        return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
      error: (error, stackTrace) {
        // Fall back to system theme on error
        return MaterialApp.router(
          title: 'Todo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
