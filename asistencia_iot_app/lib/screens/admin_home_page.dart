import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_employees_page.dart';
import 'admin_employee_form_page.dart';
import 'admin_schedules_page.dart';
import 'admin_attendance_page.dart';
import 'login_page.dart';

class AdminHomePage extends StatefulWidget {
  final ApiService api;

  const AdminHomePage({super.key, required this.api});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
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
    final user = widget.api.currentUser;
    final nombre = ((user?['nombre'] ?? '') as String).trim();
    final apellido = ((user?['apellido'] ?? '') as String).trim();
    final fullName = [nombre, apellido].where((e) => e.isNotEmpty).join(' ');

    final pages = [
      AdminEmployeesPage(api: widget.api),
      AdminSchedulesPage(api: widget.api),
      AdminAttendancePage(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
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
            icon: Icon(Icons.people),
            label: 'Empleados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Asistencias',
          ),
        ],
      ),
      // FAB solo en la pestaña de Empleados
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEmployeeFormPage(api: widget.api),
                  ),
                );

                // Si se creó un empleado, recargamos la lista
                if (created == true) {
                  setState(() {});
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
