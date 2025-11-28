import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminEmployeeFormPage extends StatefulWidget {
  final ApiService api;

  const AdminEmployeeFormPage({super.key, required this.api});

  @override
  State<AdminEmployeeFormPage> createState() => _AdminEmployeeFormPageState();
}

class _AdminEmployeeFormPageState extends State<AdminEmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _huellaCtrl = TextEditingController();
  final _rfidCtrl = TextEditingController();

  String _genero = 'M'; // M = Masculino, F = Femenino
  DateTime? _fechaNac;
  DateTime? _fechaContrato;

  bool _loading = false;
  String? _error;

  String _formatDisplayDate(DateTime? d) {
    if (d == null) return '';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year'; // dd/mm/aaaa para mostrar
  }

  Future<void> _pickDate({required bool isNacimiento}) async {
    final initial = DateTime.now();
    final firstDate = DateTime(1950);
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        if (isNacimiento) {
          _fechaNac = picked;
        } else {
          _fechaContrato = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.createEmployee(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        genero: _genero, // 'M' o 'F'
        fechaNacimiento: _fechaNac,
        fechaContrato: _fechaContrato,
        areaTrabajo: _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text,
        huellaId: _huellaCtrl.text.trim().isEmpty ? null : _huellaCtrl.text,
        rfid: _rfidCtrl.text.trim().isEmpty ? null : _rfidCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado registrado correctamente')),
      );
      Navigator.pop(context, true); // volvemos y avisamos éxito
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
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _areaCtrl.dispose();
    _huellaCtrl.dispose();
    _rfidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar empleado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellidoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese el apellido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese el username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese la contraseña' : null,
              ),
              const SizedBox(height: 12),

              // Género
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _genero,
                    items: const [
                      DropdownMenuItem(
                        value: 'M',
                        child: Text('Masculino'),
                      ),
                      DropdownMenuItem(
                        value: 'F',
                        child: Text('Femenino'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _genero = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fecha de nacimiento
              GestureDetector(
                onTap: () => _pickDate(isNacimiento: true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      hintText: 'dd/mm/aaaa',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _formatDisplayDate(_fechaNac),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fecha de contrato
              GestureDetector(
                onTap: () => _pickDate(isNacimiento: false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de contrato',
                      hintText: 'dd/mm/aaaa',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _formatDisplayDate(_fechaContrato),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Área de trabajo (ej. Cocina, Limpieza)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Opcionales
              TextFormField(
                controller: _huellaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Huella ID (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rfidCtrl,
                decoration: const InputDecoration(
                  labelText: 'RFID (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Registrar empleado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
