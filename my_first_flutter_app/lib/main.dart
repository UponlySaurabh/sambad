import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'services/chat_service.dart';
import 'profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort protection against screenshots and background snapshots
  // on Android and iOS. This does not prevent someone from taking a
  // photo of the screen with another device, but it blocks OS-level
  // screenshots and app-switcher previews.
  try {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  } catch (_) {
    // If protection cannot be enabled (e.g., unsupported platform),
    // continue without failing the app.
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final svc = ChatService();
        svc.init();
        return svc;
      },
      child: const LifecycleWatcher(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const LifecycleWatcher({required this.child, super.key});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  ChatService? _svc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // service will be available after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _svc = context.read<ChatService>();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _svc?.handleAppLifecycle(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
