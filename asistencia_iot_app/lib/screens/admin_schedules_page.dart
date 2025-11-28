import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminSchedulesPage extends StatefulWidget {
  final ApiService api;

  const AdminSchedulesPage({super.key, required this.api});

  @override
  State<AdminSchedulesPage> createState() => _AdminSchedulesPageState();
}

class _AdminSchedulesPageState extends State<AdminSchedulesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.getSchedules();
      setState(() {
        _schedules = data;
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

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openScheduleForm({Map<String, dynamic>? schedule}) async {
    final rootContext = context;
    final isEdit = schedule != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final nombreCtrl = TextEditingController(
          text: schedule != null ? schedule['nombre'] ?? '' : '',
        );
        final tolEntradaCtrl = TextEditingController(
          text: (schedule != null ? schedule['tolerancia_entrada'] : 0)
              .toString(),
        );
        final tolSalidaCtrl = TextEditingController(
          text: (schedule != null ? schedule['tolerancia_salida'] : 0)
              .toString(),
        );

        TimeOfDay? horaEntrada =
            schedule != null ? _parseTime(schedule['hora_entrada']) : null;
        TimeOfDay? horaSalida =
            schedule != null ? _parseTime(schedule['hora_salida']) : null;

        final allDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
        final Set<String> selectedDays = {
          if (schedule != null && schedule['dias'] != null)
            ...schedule['dias']
                .toString()
                .split(',')
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty)
        };

        String tipo = schedule != null ? (schedule['tipo'] ?? 'fijo') : 'fijo';
        bool saving = false;
        String? localError;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> onSave() async {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty ||
                  horaEntrada == null ||
                  horaSalida == null ||
                  selectedDays.isEmpty) {
                setStateDialog(() {
                  localError =
                      'Completa nombre, horas y al menos un día.';
                });
                return;
              }

              final tolE = int.tryParse(tolEntradaCtrl.text) ?? 0;
              final tolS = int.tryParse(tolSalidaCtrl.text) ?? 0;
              final diasList = selectedDays.toList();

              setStateDialog(() {
                saving = true;
                localError = null;
              });

              try {
                if (isEdit) {
                  await widget.api.updateSchedule(
                    id: schedule!['id'] as int,
                    nombre: nombre,
                    horaEntrada: _formatTime(horaEntrada!),
                    horaSalida: _formatTime(horaSalida!),
                    toleranciaEntrada: tolE,
                    toleranciaSalida: tolS,
                    dias: diasList,
                    tipo: tipo,
                  );
                } else {
                  await widget.api.createSchedule(
                    nombre: nombre,
                    horaEntrada: _formatTime(horaEntrada!),
                    horaSalida: _formatTime(horaSalida!),
                    toleranciaEntrada: tolE,
                    toleranciaSalida: tolS,
                    dias: diasList,
                    tipo: tipo,
                  );
                }
                Navigator.of(context).pop(true);
              } catch (e) {
                setStateDialog(() {
                  saving = false;
                  localError =
                      e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            Future<void> pickTimeEntrada() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: horaEntrada ?? const TimeOfDay(hour: 8, minute: 0),
              );
              if (picked != null) {
                setStateDialog(() => horaEntrada = picked);
              }
            }

            Future<void> pickTimeSalida() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: horaSalida ?? const TimeOfDay(hour: 12, minute: 0),
              );
              if (picked != null) {
                setStateDialog(() => horaSalida = picked);
              }
            }

            return AlertDialog(
              title: Text(isEdit ? 'Modificar horario' : 'Crear horario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Días',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: allDays.map((d) {
                        final selected = selectedDays.contains(d);
                        return FilterChip(
                          label: Text(d),
                          selected: selected,
                          onSelected: (value) {
                            setStateDialog(() {
                              if (value) {
                                selectedDays.add(d);
                              } else {
                                selectedDays.remove(d);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickTimeEntrada,
                            child: Text(
                              'Entrada: ${horaEntrada != null ? _formatTime(horaEntrada!) : '--:--'}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickTimeSalida,
                            child: Text(
                              'Salida: ${horaSalida != null ? _formatTime(horaSalida!) : '--:--'}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tolEntradaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tolerancia entrada (min)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: tolSalidaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tolerancia salida (min)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tipo,
                          items: const [
                            DropdownMenuItem(
                              value: 'fijo',
                              child: Text('Fijo'),
                            ),
                            DropdownMenuItem(
                              value: 'rotativo',
                              child: Text('Rotativo'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setStateDialog(() => tipo = v);
                          },
                        ),
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        localError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _loadSchedules();
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content:
              Text(isEdit ? 'Horario actualizado' : 'Horario creado'),
        ),
      );
    }
  }

  Future<void> _openAssignDialog(Map<String, dynamic> schedule) async {
    final rootContext = context;

    List<Map<String, dynamic>> employees;
    try {
      employees = await widget.api.getEmployees();
    } catch (e) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar empleados: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
      return;
    }

    if (employees.isEmpty) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('No hay empleados para asignar'),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        int? selectedUserId;
        DateTime? startDate;
        DateTime? endDate;
        bool saving = false;
        String? localError;

        String fmt(DateTime? d) {
          if (d == null) return '';
          final dd = d.day.toString().padLeft(2, '0');
          final mm = d.month.toString().padLeft(2, '0');
          final yy = d.year.toString();
          return '$dd/$mm/$yy';
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickStart() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setStateDialog(() => startDate = picked);
              }
            }

            Future<void> pickEnd() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate ?? (startDate ?? now),
                firstDate: startDate ?? DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setStateDialog(() => endDate = picked);
              }
            }

            Future<void> onSave() async {
              if (selectedUserId == null || startDate == null) {
                setStateDialog(() {
                  localError =
                      'Selecciona empleado y fecha de inicio.';
                });
                return;
              }

              setStateDialog(() {
                saving = true;
                localError = null;
              });

              try {
                await widget.api.assignSchedule(
                  userId: selectedUserId!,
                  scheduleId: schedule['id'] as int,
                  startDate: startDate!,
                  endDate: endDate,
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                setStateDialog(() {
                  saving = false;
                  localError =
                      e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: const Text('Asignar horario a empleado'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Empleado',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedUserId,
                      items: employees.map((e) {
                        final id = e['id'] as int;
                        final nombre = e['nombre'] ?? '';
                        final apellido = e['apellido'] ?? '';
                        final username = e['username'] ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('$nombre $apellido ($username)'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setStateDialog(() => selectedUserId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickStart,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Fecha inicio',
                            border: OutlineInputBorder(),
                            hintText: 'dd/mm/aaaa',
                          ),
                          controller: TextEditingController(
                            text: fmt(startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickEnd,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Fecha fin (opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'dd/mm/aaaa',
                          ),
                          controller: TextEditingController(
                            text: fmt(endDate),
                          ),
                        ),
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        localError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Asignar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Horario asignado correctamente'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadSchedules,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Horarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _loadSchedules,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _openScheduleForm(),
                child: const Text('Crear horario'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _schedules.isEmpty
                ? const Center(
                    child: Text('No hay horarios registrados'),
                  )
                : ListView.separated(
                    itemCount: _schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = _schedules[index];
                      final nombre = s['nombre'] ?? '';
                      final dias = s['dias'] ?? '';
                      final horaE = s['hora_entrada'] ?? '--:--';
                      final tolE = s['tolerancia_entrada'] ?? 0;
                      final horaS = s['hora_salida'] ?? '--:--';
                      final tolS = s['tolerancia_salida'] ?? 0;
                      final tipo = s['tipo'] ?? '';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Días: $dias'),
                              const SizedBox(height: 2),
                              Text('Entrada: $horaE (Tol: ${tolE}m)'),
                              Text('Salida: $horaS (Tol: ${tolS}m)'),
                              const SizedBox(height: 2),
                              Text('Tipo: $tipo'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        _openScheduleForm(schedule: s),
                                    child: const Text('Editar'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _openAssignDialog(s),
                                    child: const Text('Asignar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
