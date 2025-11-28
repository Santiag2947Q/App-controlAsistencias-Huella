import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmployeeSchedulePage extends StatefulWidget {
  final ApiService api;

  const EmployeeSchedulePage({super.key, required this.api});

  @override
  State<EmployeeSchedulePage> createState() => _EmployeeSchedulePageState();
}

class _EmployeeSchedulePageState extends State<EmployeeSchedulePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules({bool showSnack = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.api.getMySchedules();
      setState(() {
        _schedules = data;
      });

      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado')),
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

  DateTime? _parseIso(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String? _formatIsoDate(String? iso) {
    final dt = _parseIso(iso);
    if (dt == null) return null;
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  String _vigenciaText(Map<String, dynamic> s) {
    final start = _formatIsoDate(s['start_date'] as String?);
    final end = _formatIsoDate(s['end_date'] as String?);

    if (start == null && end == null) return 'Indefinido';
    if (start != null && end == null) return 'Desde $start';
    if (start == null && end != null) return 'Hasta $end';
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    // Título + botón actualizar
                    Row(
                      children: [
                        const Text(
                          'Mi horario',
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
                              : () => _loadSchedules(showSnack: true),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_loading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Expanded(
                        child: Center(
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_schedules.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No tienes horarios asignados',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Expanded(child: _buildTable()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Encabezado de la “tabla”
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
                    'Nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Días',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Entrada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Salida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Tipo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Vigencia',
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
          ..._schedules.map((s) {
            final nombre = s['nombre'] ?? '';
            final dias = s['dias'] ?? '';
            final entrada = s['hora_entrada'] ?? '--:--';
            final salida = s['hora_salida'] ?? '--:--';
            final tipo = s['tipo'] ?? '';
            final vigencia = _vigenciaText(s);

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
                      nombre.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dias.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entrada.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      salida.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      tipo.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      vigencia,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
