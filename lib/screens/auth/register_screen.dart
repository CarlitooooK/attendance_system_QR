import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import 'login_screen.dart';
import '../../widgets/responsive_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _carreraCtrl = TextEditingController();
  String _rol = 'alumno'; // 'alumno' o 'docente'
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {'rol': _rol},
      );
      final userId = res.user?.id;
      if (userId != null && _rol == 'alumno') {
        await supabase.from('alumnos').insert({
          'user_id': userId,
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'matricula': _matriculaCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'carrera': _carreraCtrl.text.trim(),
        });
      }

      // If session is null, Supabase is requiring email confirmation.
      // Avoid sending user to protected screens without an authenticated session.
      if (res.session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuenta creada. Activa tu sesión desde Login. '
              'Si no quieres confirmación por correo, desactívala en Supabase > Auth > Providers > Email.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF1565C0),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 620,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tipo de cuenta',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RolCard(
                                  label: 'Alumno',
                                  icon: Icons.school_outlined,
                                  selected: _rol == 'alumno',
                                  onTap: () => setState(() => _rol = 'alumno'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RolCard(
                                  label: 'Docente',
                                  icon: Icons.person_outlined,
                                  selected: _rol == 'docente',
                                  onTap: () => setState(() => _rol = 'docente'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildField(_nombreCtrl, 'Nombre', Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? 'Campo requerido' : null),
                          const SizedBox(height: 14),
                          _buildField(_apellidoCtrl, 'Apellido',
                              Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? 'Campo requerido' : null),
                          if (_rol == 'alumno') ...[
                            const SizedBox(height: 14),
                            _buildField(_matriculaCtrl, 'Matrícula',
                                Icons.badge_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Campo requerido' : null),
                            const SizedBox(height: 14),
                            _buildField(_carreraCtrl, 'Carrera',
                                Icons.school_outlined),
                          ],
                          const SizedBox(height: 14),
                          _buildField(_emailCtrl, 'Correo electrónico',
                              Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v!.isEmpty ? 'Campo requerido' : null),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Crear Cuenta',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}

class _RolCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RolCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}