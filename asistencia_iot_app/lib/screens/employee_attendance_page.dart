// lib/screens/employee_attendance_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmployeeAttendancePage extends StatefulWidget {
  final ApiService api;

  const EmployeeAttendancePage({super.key, required this.api});

  @override
  State<EmployeeAttendancePage> createState() =>
      _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _attendance = [];
  Map<String, dynamic>? _userInfo;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==================== LÓGICA ====================

  Future<void> _loadData({bool showSnack = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.getMyAttendance(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _attendance =
            (result['attendance'] as List<Map<String, dynamic>>);
        _userInfo = result['userInfo'] as Map<String, dynamic>;
      });

      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencias actualizadas')),
        );
      }
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

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadData();
  }

  DateTime? _parseIso(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatOnlyDate(String? iso) {
    final dt = _parseIso(iso);
    if (dt == null) return '--';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  String _formatOnlyTime(String? iso) {
    final dt = _parseIso(iso);
    if (dt == null) return '--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _statusChip(String? estado) {
    final value = estado ?? 'desconocido';
    Color bg;
    Color fg;

    switch (value) {
      case 'presente':
      case 'a_tiempo':
        bg = const Color(0xFFE3F6EC);
        fg = const Color(0xFF1E824C);
        break;
      case 'fuera_de_horario':
        bg = const Color(0xFFFFE5E5);
        fg = const Color(0xFFD64545);
        break;
      case 'sin_horario':
        bg = const Color(0xFFEDEDED);
        fg = const Color(0xFF555555);
        break;
      default:
        bg = const Color(0xFFEDEDED);
        fg = const Color(0xFF555555);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final nombre = _userInfo != null
        ? '${_userInfo?['nombre'] ?? ''} ${_userInfo?['apellido'] ?? ''}'
            .trim()
        : widget.api.currentUser?['nombre'] ?? '';
    final area = _userInfo?['area_trabajo'] ??
        widget.api.currentUser?['area_trabajo'] ??
        '';

    String iniciales = '';
    if (nombre.isNotEmpty) {
      final parts = nombre.split(' ');
      iniciales = parts.take(2).map((p) => p[0]).join().toUpperCase();
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Cabecera usuario
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: Text(
                        iniciales.isEmpty ? '?' : iniciales,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre.isEmpty ? 'Empleado' : nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (area.isNotEmpty)
                          Text(
                            'Área: $area',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta principal centrada
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Mis asistencias',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Actualizar',
                                  onPressed: _loading
                                      ? null
                                      : () => _loadData(showSnack: true),
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Filtros
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickStartDate,
                                    icon: const Icon(Icons.calendar_today,
                                        size: 18),
                                    label: Text(
                                      _startDate == null
                                          ? 'Desde'
                                          : _formatDate(_startDate),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickEndDate,
                                    icon: const Icon(Icons.calendar_today,
                                        size: 18),
                                    label: Text(
                                      _endDate == null
                                          ? 'Hasta'
                                          : _formatDate(_endDate),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _loading ? null : _loadData,
                                  icon: const Icon(Icons.filter_list, size: 18),
                                  label: const Text('Filtrar'),
                                ),
                                const SizedBox(width: 4),
                                OutlinedButton.icon(
                                  onPressed: _loading ? null : _clearFilters,
                                  icon:
                                      const Icon(Icons.clear, size: 18),
                                  label: const Text('Limpiar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Contenido (tabla / loader / error)
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_error != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Error: $_error',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else if (_attendance.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'No hay asistencias en el rango elegido',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              _buildTable(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        // Encabezado
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Fecha',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Hora Entrada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Hora Salida',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Estado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Duración',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filas
        ..._attendance.map((a) {
          final entry = a['entry_time'] as String?;
          final exit = a['exit_time'] as String?;
          final estado = a['estado_entrada'] as String?;
          final duracion = a['duracion_jornada']?.toString() ?? '--';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatOnlyDate(entry),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatOnlyTime(entry),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatOnlyTime(exit),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _statusChip(estado),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    duracion,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
