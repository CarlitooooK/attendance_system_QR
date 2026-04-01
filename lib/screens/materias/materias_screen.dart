import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../widgets/responsive_shell.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  List<Map<String, dynamic>> _materias = [];
  bool _loading = true;
  String _rol = 'alumno';

  @override
  void initState() {
    super.initState();
    _rol = supabase.auth.currentUser?.userMetadata?['rol'] ?? 'alumno';
    _loadMaterias();
  }

  Future<void> _loadMaterias() async {
    setState(() => _loading = true);
    try {
      final res = await supabase
          .from('materias')
          .select('*')
          .order('nombre', ascending: true);
      if (mounted) {
        setState(() {
          _materias = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFormDialog({Map<String, dynamic>? materia}) {
    final nombreCtrl =
        TextEditingController(text: materia?['nombre'] ?? '');
    final codigoCtrl =
        TextEditingController(text: materia?['codigo'] ?? '');
    final descCtrl =
        TextEditingController(text: materia?['descripcion'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          materia == null ? 'Nueva Materia' : 'Editar Materia',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
            ),
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
              if (!formKey.currentState!.validate()) return;
              try {
                if (materia == null) {
                  // INSERTAR
                  await supabase.from('materias').insert({
                    'nombre': nombreCtrl.text.trim(),
                    'codigo': codigoCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'docente_id': supabase.auth.currentUser?.id,
                  });
                } else {
                  // ACTUALIZAR
                  await supabase.from('materias').update({
                    'nombre': nombreCtrl.text.trim(),
                    'codigo': codigoCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', materia['id']);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadMaterias();
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
            child: Text(materia == null ? 'Guardar' : 'Actualizar',
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar materia?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Esta acción no se puede deshacer.',
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
      await supabase.from('materias').delete().eq('id', id);
      _loadMaterias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Materias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterias,
          ),
        ],
      ),
      floatingActionButton: _rol == 'docente'
          ? FloatingActionButton.extended(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add),
              label: Text('Nueva', style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            )
          : null,
      body: ResponsivePage(
        maxWidth: 1100,
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _materias.isEmpty
                ? _EmptyState(
                    icon: Icons.book_outlined,
                    message: 'No hay materias registradas',
                  )
                : RefreshIndicator(
                    onRefresh: _loadMaterias,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _materias.length,
                      itemBuilder: (ctx, i) {
                        final m = _materias[i];
                        return _MateriaCard(
                          materia: m,
                          rol: _rol,
                          onEdit: () => _showFormDialog(materia: m),
                          onDelete: () => _delete(m['id']),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _MateriaCard extends StatelessWidget {
  final Map<String, dynamic> materia;
  final String rol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MateriaCard({
    required this.materia,
    required this.rol,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.book_rounded, color: Color(0xFF1565C0)),
        ),
        title: Text(
          materia['nombre'] ?? '',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                materia['codigo'] ?? '',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00ACC1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (materia['descripcion'] != null &&
                materia['descripcion'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                materia['descripcion'],
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: rol == 'docente'
            ? PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Editar', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Eliminar',
                            style: GoogleFonts.poppins(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}