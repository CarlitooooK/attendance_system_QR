import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/responsive_shell.dart';

class QRDisplayScreen extends StatelessWidget {
  final String token;
  final String materia;
  final String fecha;

  const QRDisplayScreen({
    super.key,
    required this.token,
    required this.materia,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Código QR de Sesión'),
      ),
      body: ResponsivePage(
        maxWidth: 620,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
                'QR de Asistencia',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Muestra este código a tus alumnos',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // QR Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Info de la sesión
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.book_rounded,
                              color: Color(0xFF1565C0), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            materia,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today,
                              color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            fecha,
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Code
                    QrImageView(
                      data: token,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1565C0),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Token visible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        token.substring(0, 8).toUpperCase() + '...',
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          color: Colors.grey[600],
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Indicador de sesión activa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF43A047).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF43A047)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesión Activa',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF43A047),
                            ),
                          ),
                          Text(
                            'Los alumnos pueden escanear para registrar su asistencia',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}