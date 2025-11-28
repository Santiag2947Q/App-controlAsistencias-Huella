import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/api_service.dart';
import 'screens/login_page.dart';
import 'screens/admin_home_page.dart';
import 'screens/employee_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiService api = ApiService();
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await api.restoreSession();
    setState(() => _restoring = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget home;

    if (_restoring) {
      // Pantalla de carga mientras se restaura la sesión
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      if (api.token != null && api.currentUser != null) {
        // Sesión restaurada -> mandamos según rol
        home = api.isAdmin
            ? AdminHomePage(api: api)
            : EmployeeHomePage(api: api);
      } else {
        // Sin sesión -> login
        home = LoginPage(api: api);
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Asistencia IoT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Idioma por defecto: español
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: home,
    );
  }
}
