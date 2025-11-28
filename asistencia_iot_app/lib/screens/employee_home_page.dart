import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_attendance_page.dart';
import 'employee_schedule_page.dart';
import 'login_page.dart';

class EmployeeHomePage extends StatefulWidget {
  final ApiService api;

  const EmployeeHomePage({super.key, required this.api});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    await widget.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(api: widget.api)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.api.currentUser ?? {};
    final nombre = ((user['nombre'] ?? '') as String).trim();
    final apellido = ((user['apellido'] ?? '') as String).trim();
    final fullName = [nombre, apellido].where((e) => e.isNotEmpty).join(' ');

    final pages = [
      EmployeeAttendancePage(api: widget.api),
      EmployeeSchedulePage(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencias IOT'),
        actions: [
          if (fullName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  fullName,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Mis asistencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Mi horario',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
