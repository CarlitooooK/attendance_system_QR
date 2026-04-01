import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
import '../../widgets/responsive_shell.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _alumno;
  bool _loading = true;
  String _rol = 'alumno';

  @override
  void initState() {
    super.initState();
    _rol = supabase.auth.currentUser?.userMetadata?['rol'] ?? 'alumno';
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    if (_rol == 'alumno') {
      try {
        final userId = supabase.auth.currentUser?.id;
        final res = await supabase
            .from('alumnos')
            .select('*')
            .eq('user_id', userId!)
            .single();
        if (mounted) setState(() => _alumno = res);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showEditarDialog() {
    if (_alumno == null) return;
    final nombreCtrl = TextEditingController(text: _alumno!['nombre']);
    final apellidoCtrl = TextEditingController(text: _alumno!['apellido']);
    final carreraCtrl =
        TextEditingController(text: _alumno!['carrera'] ?? '');
    final semestreCtrl = TextEditingController(
        text: _alumno!['semestre']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar Perfil',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: apellidoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: carreraCtrl,
                decoration: const InputDecoration(labelText: 'Carrera'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semestreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Semestre'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('alumnos').update({
                  'nombre': nombreCtrl.text.trim(),
                  'apellido': apellidoCtrl.text.trim(),
                  'carrera': carreraCtrl.text.trim(),
                  'semestre': int.tryParse(semestreCtrl.text),
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', _alumno!['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadPerfil();
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
            child:
                Text('Guardar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_rol == 'alumno' && _alumno != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditarDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePage(
              maxWidth: 760,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF00ACC1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _alumno != null && _alumno!['nombre'].isNotEmpty
                            ? _alumno!['nombre'][0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _alumno != null
                        ? '${_alumno!['nombre']} ${_alumno!['apellido']}'
                        : email.split('@').first,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _rol == 'docente' ? '👨‍🏫 Docente' : '👨‍🎓 Alumno',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Info card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: email,
                        ),
                        if (_alumno != null) ...[
                          const Divider(height: 1, indent: 60),
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Matrícula',
                            value: _alumno!['matricula'] ?? 'N/A',
                          ),
                          const Divider(height: 1, indent: 60),
                          _InfoTile(
                            icon: Icons.school_outlined,
                            label: 'Carrera',
                            value: _alumno!['carrera'] ?? 'No especificada',
                          ),
                          const Divider(height: 1, indent: 60),
                          _InfoTile(
                            icon: Icons.format_list_numbered_outlined,
                            label: 'Semestre',
                            value: _alumno!['semestre']?.toString() ?? 'N/A',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        'Cerrar Sesión',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}