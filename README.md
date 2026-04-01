# Asistencia QR

Aplicación Flutter para control de asistencia con códigos QR, pensada para alumnos y docentes. Permite autenticar usuarios, administrar materias y sesiones, generar QR para registrar asistencia y consultar reportes en tiempo real.

## Características

- Inicio de sesión y registro con Supabase Auth.
- Roles de usuario: `alumno` y `docente`.
- Dashboard con resumen de materias, sesiones y asistencias.
- CRUD de materias para docentes.
- Creación de sesiones con generación de token QR.
- Escaneo de QR para registrar asistencia desde cámara.
- Reportes y gráficas de asistencia.
- Perfil de usuario con edición de datos del alumno.
- Diseño responsivo para móvil, tablet y web.

## Tecnologías

- Flutter
- Supabase
- QR Flutter
- Mobile Scanner
- Google Fonts
- FL Chart
- UUID
- Intl

## Requisitos

- Flutter 3.x o superior.
- Una cuenta y proyecto en Supabase.
- Permisos de cámara si se ejecuta en móvil.

## Instalación

1. Clona el repositorio.
2. Instala dependencias:

```bash
flutter pub get
```

3. Configura Supabase en [lib/main.dart](lib/main.dart):

```dart
const String supabaseUrl = 'tu-url-de-supabase';
const String supabaseAnonKey = 'tu-anon-key';
```

4. Ejecuta la aplicación:

```bash
flutter run
```

## Ejecución en web

Para correr el proyecto en navegador:

```bash
flutter run -d chrome
```

## Configuración de Supabase

### Autenticación

- Activa el proveedor de correo y contraseña.
- Si no quieres verificación por correo, desactiva la confirmación de email en Supabase Auth.

### Tablas sugeridas

El proyecto usa estas tablas principales:

- `alumnos`
- `materias`
- `sesiones`
- `asistencias`

Campos principales usados por la app:

- `alumnos`: `id`, `user_id`, `nombre`, `apellido`, `matricula`, `email`, `carrera`, `semestre`
- `materias`: `id`, `nombre`, `codigo`, `descripcion`, `docente_id`
- `sesiones`: `id`, `materia_id`, `fecha`, `hora_inicio`, `qr_token`, `activa`
- `asistencias`: `id`, `sesion_id`, `alumno_id`, `metodo`, `hora_registro`

## Uso

### Alumno

1. Crea tu cuenta o inicia sesión.
2. Ve a la pantalla de sesiones.
3. Abre una sesión activa.
4. Escanea el código QR para registrar asistencia.

### Docente

1. Inicia sesión con rol `docente`.
2. Administra materias desde la sección Materias.
3. Crea una sesión desde Sesiones.
4. Comparte el QR generado con tus alumnos.
5. Revisa reportes y estadísticas desde Reportes.

## Estructura del proyecto

```text
lib/
	main.dart
	screens/
		splash_screen.dart
		auth/
		home/
		materias/
		sesiones/
		asistencias/
		perfil/
		qr/
	widgets/
		responsive_shell.dart
```

## Compatibilidad

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Notas importantes

- La lectura de QR requiere que el usuario esté autenticado.
- En web, la interfaz usa un layout adaptativo con navegación lateral en pantallas anchas.
- En móvil, la navegación se mantiene en barra inferior.

## Capturas

Puedes agregar aquí imágenes del proyecto para GitHub, por ejemplo:

- Login
- Dashboard
- Escáner QR
- Reportes

## Licencia

Este proyecto no incluye una licencia definida. Agrega una si deseas publicarlo con condiciones específicas.
