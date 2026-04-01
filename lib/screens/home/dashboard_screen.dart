import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../../widgets/responsive_shell.dart';

class DashboardScreen extends StatefulWidget {
  final String rol;
  const DashboardScreen({super.key, required this.rol});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalMaterias = 0;
  int _totalSesiones = 0;
  int _totalAsistencias = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      // Materias
      final materiasRes = await supabase.from('materias').select('id');
      // Sesiones de hoy
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final sesionesRes =
          await supabase.from('sesiones').select('id').eq('fecha', hoy);
      // Asistencias
      final asistenciasRes =
          await supabase.from('asistencias').select('id');

      if (mounted) {
        setState(() {
          _totalMaterias = (materiasRes as List).length;
          _totalSesiones = (sesionesRes as List).length;
          _totalAsistencias = (asistenciasRes as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
    final nombre = email.split('@').first;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1200
        ? 4
        : screenWidth >= 700
            ? 3
            : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF00ACC1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '¡Hola, $nombre! 👋',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.rol == 'docente' ? '👨‍🏫 Docente' : '👨‍🎓 Alumno',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ResponsivePage(
              maxWidth: 1200,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de hoy',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats cards
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                        crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard(
                              title: 'Materias',
                              value: '$_totalMaterias',
                              icon: Icons.book_rounded,
                              color: const Color(0xFF1565C0),
                            ),
                            _StatCard(
                              title: 'Sesiones Hoy',
                              value: '$_totalSesiones',
                              icon: Icons.event_rounded,
                              color: const Color(0xFF00ACC1),
                            ),
                            _StatCard(
                              title: 'Asistencias',
                              value: '$_totalAsistencias',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF43A047),
                            ),
                            _StatCard(
                              title: 'Mi Rol',
                              value: widget.rol == 'docente' ? 'Docente' : 'Alumno',
                              icon: Icons.person_rounded,
                              color: const Color(0xFFE53935),
                            ),
                          ],
                        ),

                  const SizedBox(height: 28),

                  // Acciones rápidas
                  Text(
                    'Acciones Rápidas',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (widget.rol == 'alumno')
                    _QuickActionCard(
                      title: 'Escanear QR',
                      subtitle: 'Registra tu asistencia escaneando el código QR',
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF1565C0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QRScannerScreen()),
                      ),
                    ),

                  if (widget.rol == 'docente') ...[
                    _QuickActionCard(
                      title: 'Nueva Sesión',
                      subtitle: 'Crea una nueva sesión y genera el QR para asistencia',
                      icon: Icons.add_circle_rounded,
                      color: const Color(0xFF43A047),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Ve a Sesiones para crear una nueva')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickActionCard(
                      title: 'Ver Reportes',
                      subtitle: 'Consulta las estadísticas de asistencia',
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF00ACC1),
                      onTap: () {},
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}