import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _scanned = false;
  bool _processing = false;

  Future<void> _processQR(String token) async {
    if (_scanned || _processing) return;
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return;
    setState(() => _processing = true);

    try {
      // 1. Buscar la sesión con ese token
      final sesionRes = await supabase
          .from('sesiones')
          .select('id, activa, materias(nombre)')
          .eq('qr_token', cleanToken)
          .single();

      if (sesionRes['activa'] != true) {
        _showResult(
          success: false,
          title: 'Sesión Inactiva',
          message: 'Esta sesión ya fue cerrada por el docente.',
        );
        return;
      }

      // 2. Buscar el alumno
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showResult(
          success: false,
          title: 'Sesion no valida',
          message:
              'Debes iniciar sesion para registrar asistencia. Si acabas de crear tu cuenta, entra primero desde Login.',
        );
        return;
      }
      final alumnoRes = await supabase
          .from('alumnos')
          .select('id')
          .eq('user_id', userId)
          .single();

      // 3. Registrar asistencia (INSERT con manejo de duplicado)
      await supabase.from('asistencias').insert({
        'sesion_id': sesionRes['id'],
        'alumno_id': alumnoRes['id'],
        'metodo': 'QR',
      });

      setState(() => _scanned = true);
      _showResult(
        success: true,
        title: '¡Asistencia Registrada!',
        message:
            'Tu asistencia en ${sesionRes['materias']['nombre']} fue registrada correctamente.',
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Duplicate key - ya registrado
        _showResult(
          success: false,
          title: 'Ya Registrado',
          message: 'Tu asistencia ya fue registrada para esta sesión.',
        );
      } else {
        _showResult(
          success: false,
          title: 'Error',
          message: e.message,
        );
      }
    } catch (e) {
      _showResult(
        success: false,
        title: 'Error',
        message: 'Ocurrió un error al registrar tu asistencia.',
      );
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showResult({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFF43A047).withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? const Color(0xFF43A047) : Colors.red,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: success ? const Color(0xFF43A047) : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (success) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      success ? const Color(0xFF43A047) : const Color(0xFF1565C0),
                ),
                child: Text(success ? 'Listo' : 'Intentar de nuevo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (!success) setState(() => _scanned = false);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Escanear QR',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _processQR(barcode!.rawValue!);
              }
            },
          ),

          // Overlay con marco de escaneo
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Instrucciones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  if (_processing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    _processing
                        ? 'Registrando asistencia...'
                        : 'Coloca el código QR dentro del marco',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanSize = size.width * 0.7;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Esquinas
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    final corners = [
      [scanRect.topLeft, const Offset(cornerLen, 0), const Offset(0, cornerLen)],
      [scanRect.topRight, const Offset(-cornerLen, 0), const Offset(0, cornerLen)],
      [scanRect.bottomLeft, const Offset(cornerLen, 0), const Offset(0, -cornerLen)],
      [scanRect.bottomRight, const Offset(-cornerLen, 0), const Offset(0, -cornerLen)],
    ];

    for (final corner in corners) {
      final origin = corner[0] as Offset;
      final h = corner[1] as Offset;
      final v = corner[2] as Offset;
      canvas.drawLine(origin, origin + h, cornerPaint);
      canvas.drawLine(origin, origin + v, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}