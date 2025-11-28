import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://asistencia-iot-api.onrender.com';

  // Claves para SharedPreferences
  static const String _kTokenKey = 'auth_token';
  static const String _kUserKey = 'current_user';

  String? _token;
  Map<String, dynamic>? _currentUser;

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?['role'] == 'admin';

  Map<String, String> _authHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // =============== PERSISTENCIA DE SESIÓN ===============

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null && _currentUser != null) {
      await prefs.setString(_kTokenKey, _token!);
      await prefs.setString(_kUserKey, jsonEncode(_currentUser));
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_kTokenKey);
    final storedUser = prefs.getString(_kUserKey);

    if (storedToken != null && storedUser != null) {
      _token = storedToken;
      try {
        _currentUser = jsonDecode(storedUser) as Map<String, dynamic>;
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _clearSession();
  }

  // ================== AUTH ==================

  /// POST /auth/login
  Future<void> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access_token'];
      _currentUser = data['user'];
      await _persistSession(); // 🔹 guardamos token + usuario
    } else {
      String msg = 'Error al iniciar sesión';
      try {
        msg = jsonDecode(res.body)['msg'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ================== EMPLEADOS ==================

  /// GET /users/ (lista de empleados)
  Future<List<Map<String, dynamic>>> getEmployees() async {
    final url = Uri.parse('$baseUrl/users/');
    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> users = data['users'] ?? [];
      return users.cast<Map<String, dynamic>>();
    } else {
      print('Body error empleados: ${res.body}');
      throw Exception('Error al obtener empleados (${res.statusCode})');
    }
  }

  /// POST /users/create (crear empleado)
  Future<void> createEmployee({
    required String nombre,
    required String apellido,
    required String username,
    required String password,
    required String genero, // 'M' o 'F'
    DateTime? fechaNacimiento,
    DateTime? fechaContrato,
    String? areaTrabajo,
    String? huellaId,
    String? rfid,
  }) async {
    // convertir fechas al formato que espera el backend: YYYY-MM-DD
    String? _toApiDate(DateTime? d) {
      if (d == null) return null;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final Map<String, dynamic> body = {
      "nombre": nombre,
      "apellido": apellido,
      "username": username,
      "password": password,
      "genero": genero, // 'M' o 'F'
      "role": "empleado", // por ahora siempre creamos empleados
      if (fechaNacimiento != null)
        "fecha_nacimiento": _toApiDate(fechaNacimiento),
      if (fechaContrato != null)
        "fecha_contrato": _toApiDate(fechaContrato),
      if (areaTrabajo != null && areaTrabajo.trim().isNotEmpty)
        "area_trabajo": areaTrabajo.trim(),
      if (rfid != null && rfid.trim().isNotEmpty) "rfid": rfid.trim(),
    };

    // huella_id es opcional y numérico
    if (huellaId != null && huellaId.trim().isNotEmpty) {
      final parsed = int.tryParse(huellaId.trim());
      if (parsed == null) {
        throw Exception('huella_id debe ser numérico');
      }
      body["huella_id"] = parsed;
    }

    final url = Uri.parse('$baseUrl/users/create');
    final res = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      String msg = 'Error al crear empleado (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        if (data['msg'] != null) msg = data['msg'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ================== HORARIOS (ADMIN) ==================

  /// GET /schedules/
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final url = Uri.parse('$baseUrl/schedules/');
    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Body error schedules: ${res.body}');
      throw Exception('Error al obtener horarios (${res.statusCode})');
    }
  }

  /// POST /schedules/  (crear horario)
  Future<void> createSchedule({
    required String nombre,
    required String horaEntrada, // "HH:MM"
    required String horaSalida, // "HH:MM"
    required int toleranciaEntrada,
    required int toleranciaSalida,
    required List<String> dias, // ej: ['Lun','Mar','Mie']
    required String tipo, // 'fijo' o 'rotativo'
  }) async {
    final url = Uri.parse('$baseUrl/schedules/');
    final body = {
      "nombre": nombre,
      "hora_entrada": horaEntrada,
      "hora_salida": horaSalida,
      "tolerancia_entrada": toleranciaEntrada,
      "tolerancia_salida": toleranciaSalida,
      "dias": dias,
      "tipo": tipo,
    };

    final res = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      String msg = 'Error al crear horario (${res.statusCode})';
      try {
        msg = jsonDecode(res.body)['msg'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// PUT /schedules/<id>  (editar horario)
  Future<void> updateSchedule({
    required int id,
    required String nombre,
    required String horaEntrada,
    required String horaSalida,
    required int toleranciaEntrada,
    required int toleranciaSalida,
    required List<String> dias,
    required String tipo,
  }) async {
    final url = Uri.parse('$baseUrl/schedules/$id');
    final body = {
      "nombre": nombre,
      "hora_entrada": horaEntrada,
      "hora_salida": horaSalida,
      "tolerancia_entrada": toleranciaEntrada,
      "tolerancia_salida": toleranciaSalida,
      "dias": dias,
      "tipo": tipo,
    };

    final res = await http.put(
      url,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      String msg = 'Error al actualizar horario (${res.statusCode})';
      try {
        msg = jsonDecode(res.body)['msg'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// POST /schedules/assign  (asignar horario a empleado)
  Future<void> assignSchedule({
    required int userId,
    required int scheduleId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String _fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day'; // YYYY-MM-DD
    }

    final url = Uri.parse('$baseUrl/schedules/assign');
    final body = {
      "user_id": userId,
      "schedule_id": scheduleId,
      "start_date": _fmt(startDate),
      if (endDate != null) "end_date": _fmt(endDate),
    };

    final res = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      String msg = 'Error al asignar horario (${res.statusCode})';
      try {
        msg = jsonDecode(res.body)['msg'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ================== ASISTENCIAS (ADMIN) ==================

  /// GET /attendance/admin/users
  Future<List<Map<String, dynamic>>> getAttendanceAdminUsers() async {
    final url = Uri.parse('$baseUrl/attendance/admin/users');
    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List users = data['users'] ?? [];
      return users.cast<Map<String, dynamic>>();
    } else {
      print('Body error admin users: ${res.body}');
      throw Exception(
        'Error al obtener usuarios para asistencias (${res.statusCode})',
      );
    }
  }

  /// GET /attendance/admin/report
  ///
  /// Filtros opcionales:
  ///  - userId -> user_id
  ///  - startDate -> start_date (YYYY-MM-DD)
  ///  - endDate -> end_date   (YYYY-MM-DD)
  ///  - area -> area
  Future<List<Map<String, dynamic>>> getAttendanceAdminReport({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? area,
  }) async {
    String _fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final qp = <String, String>{};
    if (userId != null) qp['user_id'] = userId.toString();
    if (startDate != null) qp['start_date'] = _fmt(startDate);
    if (endDate != null) qp['end_date'] = _fmt(endDate);
    if (area != null && area.trim().isNotEmpty) {
      qp['area'] = area.trim();
    }

    final base = Uri.parse('$baseUrl/attendance/admin/report');
    final url = base.replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List asistencias = data['asistencias'] ?? [];
      return asistencias.cast<Map<String, dynamic>>();
    } else {
      print('Body error admin report: ${res.body}');
      throw Exception(
        'Error al obtener reporte de asistencias (${res.statusCode})',
      );
    }
  }

  // ================== ASISTENCIAS (EMPLEADO) ==================

  /// GET /attendance/my-attendance
  ///
  /// Filtros opcionales:
  ///  - startDate -> start_date (YYYY-MM-DD)
  ///  - endDate   -> end_date   (YYYY-MM-DD)
  ///
  /// Devuelve:
  ///  {
  ///    'attendance': List<Map<String,dynamic>>,
  ///    'userInfo': Map<String,dynamic>
  ///  }
  Future<Map<String, dynamic>> getMyAttendance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String _fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final qp = <String, String>{};
    if (startDate != null) qp['start_date'] = _fmt(startDate);
    if (endDate != null) qp['end_date'] = _fmt(endDate);

    final base = Uri.parse('$baseUrl/attendance/my-attendance');
    final url = base.replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final List asistenciasRaw = data['asistencias'] ?? [];
      final attendance = asistenciasRaw.cast<Map<String, dynamic>>();

      final userInfo =
          (data['user_info'] ?? {}) as Map<String, dynamic>;

      _currentUser = {
        ...(_currentUser ?? {}),
        ...userInfo,
      };
      await _persistSession(); // 🔹 guardamos cambios del usuario

      return {
        'attendance': attendance,
        'userInfo': userInfo,
      };
    } else {
      print('Body error my-attendance: ${res.body}');
      throw Exception(
        'Error al obtener mis asistencias (${res.statusCode})',
      );
    }
  }

  // =============== HORARIO EMPLEADO ===============

  /// GET /schedules/my
  ///
  /// Devuelve una lista de horarios asignados al usuario:
  /// [
  ///   {
  ///     "schedule_id": 1,
  ///     "nombre": "...",
  ///     "hora_entrada": "08:00",
  ///     "tolerancia_entrada": 0,
  ///     "hora_salida": "12:00",
  ///     "tolerancia_salida": 0,
  ///     "dias": "Lun,Mar,Mie,Jue,Vie",
  ///     "tipo": "fijo",
  ///     "start_date": "2025-11-28T00:00:00-05:00",
  ///     "end_date": null
  ///   },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> getMySchedules() async {
    final url = Uri.parse('$baseUrl/schedules/my');
    final res = await http.get(url, headers: _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List list = data;
      return list.cast<Map<String, dynamic>>();
    } else {
      print('Body error schedules/my: ${res.body}');
      throw Exception(
        'Error al obtener mi horario (${res.statusCode})',
      );
    }
  }
}
