import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
import '../materias/materias_screen.dart';
import '../sesiones/sesiones_screen.dart';
import '../asistencias/reportes_screen.dart';
import '../perfil/perfil_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _rol = 'alumno';

  @override
  void initState() {
    super.initState();
    _loadRol();
  }

  void _loadRol() {
    final metadata = supabase.auth.currentUser?.userMetadata;
    setState(() => _rol = metadata?['rol'] ?? 'alumno');
  }

  List<Widget> get _screens => [
        DashboardScreen(rol: _rol),
        const MateriasScreen(),
        const SesionesScreen(),
        const ReportesScreen(),
        const PerfilScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Inicio',
                    index: 0,
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.book_outlined,
                    activeIcon: Icons.book,
                    label: 'Materias',
                    index: 1,
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.event_outlined,
                    activeIcon: Icons.event,
                    label: 'Sesiones',
                    index: 2,
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Reportes',
                    index: 3,
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Perfil',
                    index: 4,
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1565C0).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF1565C0) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF1565C0) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}