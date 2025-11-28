import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminEmployeesPage extends StatefulWidget {
  final ApiService api;

  const AdminEmployeesPage({super.key, required this.api});

  @override
  State<AdminEmployeesPage> createState() => _AdminEmployeesPageState();
}

class _AdminEmployeesPageState extends State<AdminEmployeesPage> {
  late Future<List<Map<String, dynamic>>> _futureEmployees;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _futureEmployees = widget.api.getEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Empleados registrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureEmployees,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final employees = snapshot.data ?? [];

                if (employees.isEmpty) {
                  return const Center(
                    child: Text('No hay empleados registrados'),
                  );
                }

                return ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = employees[index];

                    final id = e['id'] ?? '-';
                    final username = e['username'] ?? '-';
                    final nombre = e['nombre'] ?? '-';
                    final apellido = e['apellido'] ?? '-';
                    final rol = e['role'] ?? e['rol'] ?? '-';
                    final area = e['area_trabajo'] ?? e['area'] ?? '-';
                    final huellaId = e['huella_id'] ?? '-';
                    final rfid = e['rfid'] ?? '-';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$nombre $apellido',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'ID: $id',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Username: $username',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Rol: $rol',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Área: $area',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Huella ID: $huellaId',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'RFID: $rfid',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Aquí luego puedes abrir pantalla de editar empleado
                                },
                                child: const Text('Ver / Editar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
