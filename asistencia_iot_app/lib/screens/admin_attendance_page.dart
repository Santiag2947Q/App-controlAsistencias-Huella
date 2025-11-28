import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminAttendancePage extends StatefulWidget {
  final ApiService api;

  const AdminAttendancePage({super.key, required this.api});

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _records = [];

  int? _selectedUserId; // null = Todos
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _areaCtrl = TextEditingController();

  final DateFormat _dtFormat = DateFormat('dd/MM/yyyy, h:mm a');

  @override
  void initState() {
    super.initState();
    _loadUsersAndInitialReport();
  }

  Future<void> _loadUsersAndInitialReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await widget.api.getAttendanceAdminUsers();
      final records = await widget.api.getAttendanceAdminReport();
      setState(() {
        _users = users;
        _records = records;
        _selectedUserId = null;
        _startDate = null;
        _endDate = null;
        _areaCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'dd/mm/aaaa';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  String _fmtDateTime(String? iso) {
    if (iso == null) return '---';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return _dtFormat.format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _buildStatusChip(String? status) {
    status = status ?? '';
    Color color;
    switch (status) {
      case 'presente':
        color = Colors.green;
        break;
      case 'tarde':
        color = Colors.orange;
        break;
      case 'fuera_de_horario':
        color = Colors.red;
        break;
      case 'sin_horario':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final first = DateTime(now.year - 1);
    final last = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records = await widget.api.getAttendanceAdminReport(
        userId: _selectedUserId,
        startDate: _startDate,
        endDate: _endDate,
        area: _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      );
      setState(() {
        _records = records;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Contenido principal centrado y con ancho máximo
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título + Actualizar
        Row(
          children: [
            const Text(
              'Reporte de Asistencias (Admin)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loadUsersAndInitialReport,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filtros
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Empleado',
                  border: OutlineInputBorder(),
                ),
                value: _selectedUserId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._users.map((u) {
                    final id = u['id'] as int;
                    final nombre = u['nombre'] ?? '';
                    final apellido = u['apellido'] ?? '';
                    final username = u['username'] ?? '';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text('$nombre $apellido ($username)'),
                    );
                  }).toList(),
                ],
                onChanged: (v) {
                  setState(() => _selectedUserId = v);
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: GestureDetector(
                onTap: () => _pickDate(isStart: true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _startDate == null ? '' : _fmtDate(_startDate),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: GestureDetector(
                onTap: () => _pickDate(isStart: false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _endDate == null ? '' : _fmtDate(_endDate),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Área (ej. Cocina)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _loading ? null : _search,
              child: const Text('Buscar'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_loading) const LinearProgressIndicator(),

        if (_error != null && (_users.isNotEmpty || _records.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        const SizedBox(height: 8),

        // Tabla
        Expanded(
          child: _records.isEmpty
              ? const Center(
                  child: Text(
                    'No hay asistencias para los filtros seleccionados',
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Empleado')),
                        DataColumn(label: Text('Área')),
                        DataColumn(label: Text('Entrada')),
                        DataColumn(label: Text('Salida')),
                        DataColumn(label: Text('Duración')),
                        DataColumn(label: Text('Estado')),
                      ],
                      rows: _records.map((r) {
                        final nombre = r['nombre'] ?? '';
                        final apellido = r['apellido'] ?? '';
                        final username = r['username'] ?? '';
                        final area = r['area_trabajo'] ?? '';
                        final entry = _fmtDateTime(r['entry_time']);
                        final exit = r['exit_time'] != null
                            ? _fmtDateTime(r['exit_time'])
                            : '---';
                        final dur = r['duracion_jornada'] ?? 'En curso';
                        final estado = r['estado_entrada'];

                        return DataRow(
                          cells: [
                            DataCell(Text('$nombre $apellido\n$username')),
                            DataCell(Text(area)),
                            DataCell(Text(entry)),
                            DataCell(Text(exit)),
                            DataCell(Text(dur)),
                            DataCell(_buildStatusChip(estado)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );

    // Center + maxWidth para que no quede pegado a la izquierda
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}
