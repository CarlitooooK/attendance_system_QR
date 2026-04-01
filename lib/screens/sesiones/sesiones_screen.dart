import 'package:attendance_qr/screens/qr/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../qr/qr_display_screen.dart';
import '../../widgets/responsive_shell.dart';

class SesionesScreen extends StatefulWidget {
  const SesionesScreen({super.key});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  List<Map<String, dynamic>> _sesiones = [];
  List<Map<String, dynamic>> _materias = [];
  bool _loading = true;
  String _rol = 'alumno';

  @override
  void initState() {
    super.initState();
    _rol = supabase.auth.currentUser?.userMetadata?['rol'] ?? 'alumno';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final sesRes = await supabase
          .from('sesiones')
          .select('*, materias(nombre, codigo)')
          .order('fecha', ascending: false)
          .order('hora_inicio', ascending: false);

      final matRes = await supabase.from('materias').select('id, nombre');

      if (mounted) {
        setState(() {
          _sesiones = List<Map<String, dynamic>>.from(sesRes);
          _materias = List<Map<String, dynamic>>.from(matRes);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCrearSesion() {
    String? materiaId;
    final horaCtrl = TextEditingController(
        text: DateFormat('HH:mm').format(DateTime.now()));
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Nueva Sesión',
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: materiaId,
                  decoration: InputDecoration(
                    labelText: 'Materia',
                    prefixIcon: const Icon(Icons.book_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _materias
                      .map((m) => DropdownMenuItem<String>(
                            value: m['id'],
                            child: Text(m['nombre'],
                                style: GoogleFonts.poppins()),
                          ))
                      .toList(),
                  onChanged: (v) => setModalState(() => materiaId = v),
                  validator: (v) => v == null ? 'Selecciona una materia' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: horaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Hora de inicio (HH:MM)',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      final token = const Uuid().v4();
                      final hoy = DateTime.now().toIso8601String().substring(0, 10);
                      await supabase.from('sesiones').insert({
                        'materia_id': materiaId,
                        'fecha': hoy,
                        'hora_inicio': '${horaCtrl.text}:00',
                        'qr_token': token,
                        'activa': true,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.qr_code),
                  label: Text('Crear y Generar QR',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSesion(String id, bool activa) async {
    await supabase.from('sesiones').update({'activa': !activa}).eq('id', id);
    _loadData();
  }

  Future<void> _deleteSesion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar sesión?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Se eliminarán también las asistencias registradas.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.from('sesiones').delete().eq('id', id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Sesiones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: _rol == 'docente'
          ? FloatingActionButton.extended(
              onPressed: _showCrearSesion,
              icon: const Icon(Icons.add),
              label: Text('Nueva Sesión', style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            )
          : null,
      body: ResponsivePage(
        maxWidth: 1100,
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sesiones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No hay sesiones registradas',
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _sesiones.length,
                      itemBuilder: (ctx, i) {
                        final s = _sesiones[i];
                        final materia =
                            s['materias'] as Map<String, dynamic>? ?? {};
                        final activa = s['activa'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: activa
                                ? Border.all(
                                    color: const Color(0xFF43A047), width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: activa
                                            ? const Color(0xFF43A047)
                                                .withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        activa ? '🟢 Activa' : '⭕ Cerrada',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: activa
                                              ? const Color(0xFF43A047)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_rol == 'docente')
                                      PopupMenuButton(
                                        icon: const Icon(Icons.more_vert),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QRDisplayScreen(
                                                  token: s['qr_token'],
                                                  materia: materia['nombre'] ?? '',
                                                  fecha: s['fecha'] ?? '',
                                                ),
                                              ),
                                            ),
                                            child: Row(children: [
                                              const Icon(Icons.qr_code, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Ver QR',
                                                  style: GoogleFonts.poppins()),
                                            ]),
                                          ),
                                          PopupMenuItem(
                                            onTap: () => _toggleSesion(
                                                s['id'], activa),
                                            child: Row(children: [
                                              Icon(
                                                activa
                                                    ? Icons.stop_circle_outlined
                                                    : Icons.play_circle_outlined,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                  activa ? 'Cerrar' : 'Activar',
                                                  style: GoogleFonts.poppins()),
                                            ]),
                                          ),
                                          PopupMenuItem(
                                            onTap: () => _deleteSesion(s['id']),
                                            child: Row(children: [
                                              const Icon(Icons.delete_outline,
                                                  size: 18, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Text('Eliminar',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.red)),
                                            ]),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  materia['nombre'] ?? 'Sin materia',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      s['fecha'] ?? '',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      s['hora_inicio'] ?? '',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if (_rol == 'alumno' && activa) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QRScannerScreen(),
                                        ),
                                      ),
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: Text('Registrar Asistencia',
                                          style: GoogleFonts.poppins()),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF1565C0),
                                        side: const BorderSide(
                                            color: Color(0xFF1565C0)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

