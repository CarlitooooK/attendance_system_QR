import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../widgets/responsive_shell.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<Map<String, dynamic>> _asistencias = [];
  List<Map<String, dynamic>> _materias = [];
  String? _materiaSeleccionada;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final materiasRes = await supabase
          .from('materias')
          .select('id, nombre');

      final asistenciasRes = await supabase
          .from('asistencias')
          .select('*, sesiones(fecha, materia_id, materias(nombre)), alumnos(nombre, apellido, matricula)')
          .order('hora_registro', ascending: false);

      if (mounted) {
        setState(() {
          _materias = List<Map<String, dynamic>>.from(materiasRes);
          _asistencias = List<Map<String, dynamic>>.from(asistenciasRes);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_materiaSeleccionada == null) return _asistencias;
    return _asistencias.where((a) {
      final sesion = a['sesiones'] as Map<String, dynamic>?;
      return sesion?['materia_id'] == _materiaSeleccionada;
    }).toList();
  }

  Map<String, int> get _porMateria {
    final mapa = <String, int>{};
    for (final a in _asistencias) {
      final sesion = a['sesiones'] as Map<String, dynamic>?;
      final nombre = sesion?['materias']?['nombre'] ?? 'Sin materia';
      mapa[nombre] = (mapa[nombre] ?? 0) + 1;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final porMateria = _porMateria;
    final screenWidth = MediaQuery.of(context).size.width;
    final colores = [
      const Color(0xFF1565C0),
      const Color(0xFF00ACC1),
      const Color(0xFF43A047),
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Reportes de Asistencia'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePage(
              maxWidth: 1200,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Resumen
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: screenWidth >= 900 ? 260 : (screenWidth - 56) / 2,
                        child: _ResumenCard(
                          title: 'Total Asistencias',
                          value: '${_asistencias.length}',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF43A047),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth >= 900 ? 260 : (screenWidth - 56) / 2,
                        child: _ResumenCard(
                          title: 'Materias',
                          value: '${_materias.length}',
                          icon: Icons.book_outlined,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gráfica de barras
                  if (porMateria.isNotEmpty) ...[
                    Text(
                      'Asistencias por Materia',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (porMateria.values.isEmpty
                                  ? 1
                                  : porMateria.values
                                      .reduce((a, b) => a > b ? a : b))
                              .toDouble() + 2,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (v, _) => Text(
                                  v.toInt().toString(),
                                  style: GoogleFonts.poppins(fontSize: 10),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final keys = porMateria.keys.toList();
                                  if (v.toInt() >= keys.length) {
                                    return const SizedBox();
                                  }
                                  final k = keys[v.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      k.length > 8 ? '${k.substring(0, 8)}..' : k,
                                      style: GoogleFonts.poppins(fontSize: 9),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData:
                              const FlGridData(drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          barGroups: porMateria.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((e) => BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value.value.toDouble(),
                                        color: colores[
                                            e.key % colores.length],
                                        width: 24,
                                        borderRadius:
                                            const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                      )
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Filtro por materia
                  Text(
                    'Detalle de Asistencias',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _materiaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por materia',
                      prefixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child:
                            Text('Todas', style: GoogleFonts.poppins()),
                      ),
                      ..._materias.map((m) => DropdownMenuItem<String?>(
                            value: m['id'],
                            child: Text(m['nombre'],
                                style: GoogleFonts.poppins()),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _materiaSeleccionada = v),
                  ),
                  const SizedBox(height: 12),

                  // Lista de asistencias
                  ..._filtradas.map((a) {
                    final alumno =
                        a['alumnos'] as Map<String, dynamic>? ?? {};
                    final sesion =
                        a['sesiones'] as Map<String, dynamic>? ?? {};
                    final materia =
                        sesion['materias'] as Map<String, dynamic>? ?? {};
                    final hora = a['hora_registro'] as String? ?? '';
                    final horaDate =
                        hora.isNotEmpty ? DateTime.tryParse(hora) : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF43A047)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${alumno['nombre'] ?? ''} ${alumno['apellido'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  alumno['matricula'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  materia['nombre'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF1565C0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                sesion['fecha'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              if (horaDate != null)
                                Text(
                                  '${horaDate.hour.toString().padLeft(2, '0')}:${horaDate.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF43A047),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a['metodo'] ?? 'QR',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  if (_filtradas.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Sin registros de asistencia',
                                style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
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

class _ResumenCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ResumenCard({
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  )),
            ],
          ),
        ],
      ),
    );
  }
}