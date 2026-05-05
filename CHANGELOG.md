# Registro de versiones y novedades

Flujo de trabajo: Revisar correcciones y mejoras, desarrollar la tarea, probar mejora, registrar mejoras o errores capturados, subir a git.
Se registrara lo siguiente: Primero la version y fecha. Luego: `Funcionalidades`, `Problemas conocidos`, `Correcciones y merjoras`, `Sugerencias`

**Tests**: Todos los tests unitarios de modelos están implementados y listos para ejecutar con `flutter test`.

## v0.6.2 - 2026-05-04 🎬 Axon VBT: Bio-Cinemática de Precisión

### Funcionamiento del Módulo
El módulo **Axon VBT** (Velocity Based Training) integra análisis de video con regresiones estadísticas para la monitorización del entrenamiento. El flujo consiste en:
1. **Configuración**: Selección de ejercicio, ROM, peso (kg) y parte corporal.
2. **Marcación de Frames**: Identificación visual del inicio y fin de la fase concéntrica.
3. **Cálculo Cinemático**: El motor procesa la velocidad media (VMC), calcula fatiga, potencia y estima el 1RM.
4. **Exportación**: Generación de un dashboard visual de alta resolución para compartir o guardar.

### Funcionalidades y Mejoras
* **Modelo de Regresión Polinómica**: Sustitución de ecuaciones lineales por modelos polinómicos de 2do grado para una estimación del 1RM más precisa según el perfil individual de carga-velocidad.
* **Cálculo de Potencia y Carga**: Incorporación de input de Peso (kg) para cálculo automático de Potencia Máxima (Watts) y e1RM absoluto.
* **Dashboard Analítico (Shareable Card)**:
  - Rediseño completo a una **lista vertical modular elegante** que prioriza la legibilidad.
  - Inclusión de métricas avanzadas: **VMC Media, VMC Mínima y Coeficiente de Variación (CV%)**.
  - Visualización de porcentaje estimado con indicador de aproximación (~% 1RM).
* **Gráfico de Evolución Cinemática**:
  - Ejes optimizados: Eje Y ("v/s") y Eje X ("REPETICIONES" con etiquetas numéricas limpias).
  - Línea horizontal punteada para seguimiento visual de la **VMC Objetivo**.
* **Gestión de Sesión**:
  - Implementación de **Borrado de Repeticiones** con re-indexación automática de datos.
  - Unificación de Step 3 y 4 en un resumen de serie dinámico.
* **Branding**: Transición visual a **MyoAxon** y simplificación de leyendas legales.
* **Correcciones**:
  - Ajuste de `TextInputFormatter` para compatibilidad total con teclados decimales (comas por puntos).
  - Optimización de `RepaintBoundary` para captura estable en entornos Web y Móvil.
  - Generación de imagen con el resumen de rendimiento y opción de compartir a otras aplicaciones.
* **Overlay de Rendimiento (OSD)**:
  - Nueva capa visual sobre el video con estética de benchmark (GPU Review).
  - Visualización en tiempo real de los FPS detectados y versión del motor Axon Core.

### Correcciones
* Limpieza masiva de dependencias y código de la arquitectura antigua de "Laboratorio Axon".

## v0.5.0 - 2026-04-29 🧬 Axon Peak: Optimización de Periodización Científica

### Funcionalidades y Mejoras
* **Motor de Periodización Axon Peak**:
  - Implementación de métodos **Por Pasos (Step-Loading)** y **Lineal Tradicional**.
  - Lógica de autorregulación basada en **VMC (Velocidad Media Concéntrica)**.
  - Regla de Estabilidad de 2 Bloques: Detección automática de estancamiento de velocidad (< 0.35 m/s).
  - Sistema de "Freno de Emergencia": Opción de repetir bloques si el rendimiento VBT no es óptimo.
* **Interfaz de Usuario Premium**:
  - Vista Dual Interactiva: Visualización simultánea de Carga (Kg) e Intensidad (%).
  - Soporte universal de decimales (permite uso de `,` y `.` indistintamente).
  - Micro-animaciones y reconstrucción dinámica de estados mediante `ValueKey`.
* **Refactorización de Datos**:
  - Eliminación de parámetros obsoletos (`athleteLevel`).
  - Optimización de persistencia Hive con recarga forzada para sincronización UI.

### Correcciones
- ✅ **Fix Reconstrucción de Bloques**: Corregido el error donde los cambios en las cargas no se visualizaban tras finalizar un bloque.
- ✅ **Fix Persistencia Hive**: Reemplazo de `save()` por `_box.put()` para asegurar compatibilidad con entornos de test y producción.
- ✅ **Fix Sintaxis UI**: Corrección de cierres de widgets en diálogos de cierre de bloque.

### Tests
- **Axon Peak Provider**: Suite de pruebas unitarias implementada en `test/providers/axon_peak_provider_test.dart` cubriendo:
  - Generación inicial de macrociclos (StepLoading vs Linear).
  - Lógica de repetición de bloques ante rechazo de incremento.

---

## v0.4.0 - 2026-04-14 🔄 Rutinas Compartibles & Auto-categorización

### Funcionalidades y Mejoras
* **Ecosistema de Archivos (Base64 + Zlib)**:
  - Nuevo módulo `SessionExportService` para generar plantillas estructurales en código Base64.
  - Sistema de compresión cross-platform (Web incluido) instalado vía librería `archive` (algoritmo V3 nativo en Dart).
  - Herramienta inteligente de Regex al importar rutinas que ignora emojis y texto y decodifica únicamente los arrays de la rutina completa.
* **Auto-Categorización del Atleta**:
  - Eliminado el input manual de `Categoría` en el form de "Completar Perfil".
  - El sistema detecta y calcula la edad del atleta dinámicamente frente al calendario para asignar (U14, U16, U18, U20, U23, Senior) y lo muestra en el Widget Drawer y Perfil.
* **Limpieza de ML Kit**:
  - Eliminación definitiva del paquete `google_mlkit_pose_detection` en preparación a usar Mosaicos en Lab Axon.
  - Disminución del tamaño general de la aplicación y aumento en compatiblidad (SDK Constraints de Android aliviados).

### Notas de Versión
* **Pausa Estratégica (Módulo de Video)**: Se ha pausado momentáneamente el desarrollo avanzado de la funcionalidad de video y frame-by-frame biocinemático para priorizar y estabilizar el sistema de Compatibilidad Web, el ecosistema de Exportación de Sesiones Base64, y la depuración estructural de estas nuevas "Features".

---
## v0.3.1 - 2026-04-10 🎥 VBT "Lazy & Light" Integral
*   **Corrección NDK:** Resuelto conflicto de NDK (`libc++_shared.so`) que causaba `PlatformException(channel-error)` en la inicialización de Firebase al compartir dependencias con FFmpeg.
*   **Carga Diferida (Lazy Loading):** Se optimizó la arquitectura del `VideoProcessorService`. Ahora `FFmpegKit` solo se inicializa y consume memoria nativa cuando el usuario entra al Laboratorio Axon, acelerando el arranque de la app y evitando sobrecarga del NDK general.
*   **Min-GPL:** Eliminación de dependencias monstruosas de video. Implementación definitiva de `ffmpeg_kit_flutter_new_min_gpl` para mantener el tamaño del APK controlado.


## v0.2.2 - 2026-04-04 🔐 Estabilización de Sesiones (Doble Persistencia)

### Funcionalidades y Mejoras
* **Doble Persistencia (Arquitectura Robusta)**:
  - Implementación de `currentUserIdProvider` centralizado que unifica Firebase Auth con una bandera de sesión local en Hive.
  - **Arranque Instantáneo**: La app detecta la sesión localmente y entra al Home/Perfil de inmediato, mientras Firebase se despierta en segundo plano.
  - **Escudo de Perfil**: Protección contra el borrado accidental de datos locales durante los cambios de estado transitorios de Firebase en el arranque en frío.
* **Optimización de Almacenamiento**:
  - Migración de la bandera de autenticación a una caja dedicada (`auth_box`), eliminando los "registros vacíos" que aparecían en el historial de entrenamientos.
  - Limpieza automática de banderas de sesión heredadas de versiones anteriores.
* **Backend y Offline**:
  - Forzada la persistencia `LOCAL` en Web para evitar cierres de sesión al refrescar el navegador.
  - Activada la caché ilimitada de Firestore offline para garantizar acceso a datos históricos sin conexión.

---
## v0.2.1 - 2026-04-03 🛠️ Estabilización y "Modo Seguro"

### Funcionalidades y Mejoras
* **Inicio Robusto (Anti-White Screen)**:
  - Implementación de `try-catch` global en `main.dart` para capturar fallos de inicialización (Firebase/Hive).
  - Pantalla de error técnica en lugar de colgarse en blanco si falla el arranque.
* **Corrección de Navegación (Web Black Screen)**:
  - Corregido error en `NuevoRegistroScreen` que cerraba la app (`Navigator.pop`) al guardar un registro desde la pestaña principal.
  - Implementada limpieza de formulario automática tras guardado exitoso en modo "Nueva Sesión".
* **Optimización Android**:
  - Activado **MultiDex** para soportar el alto número de métodos de las librerías de visión.
  - Configurados filtros **ABI** (`arm64-v8a`, `armeabi-v7a`) en `build.gradle.kts` para mejorar la compatibilidad y reducir el tamaño del binario.
  - Añadidos permisos explícitos de `INTERNET` y `STORAGE`.

### Gestión de Datos
* **Adaptadores Hive seguros**: Refuerzo de `AxonAnalysisModelAdapter` con comprobaciones de nulidad para evitar crashes al leer registros antiguos o incompletos.
* **Diagnóstico de Guardado**: Captura granular de errores en `AxonLabNotifier` con notificaciones visuales (SnackBar) para el usuario.

### Notas de Versión
* **Aislamiento de Dependencias**: Por motivos de diagnóstico, se han desactivado temporalmente las funciones nativas de `FFmpeg` y `ML Kit` para garantizar un arranque estable. Las funciones de análisis de video están en modo "Stub" (simulado).

---
## v0.2.0 - 2026-03-29 🎬 Laboratorio Axon Offline

### Funcionalidades
* **Análisis Biomecánico de Video (Offline)**: Migración de procesamiento en tiempo real con cámara a procesamiento de archivos de video.
  - Selector nativo de videos (`image_picker`) y previsualización (`video_player`).
  - Al no depender de la latencia de la CPU, usa la tasa de cuadros original (FPS extraídos con `FFprobe`) para calcular el tiempo ($\Delta t = \text{frames} \times \frac{1000}{fps}$), logrando precisión inalterable.
  - Capacidad nativa de analizar videos *Slow Motion* (60, 120, 240 fps) reduciendo drásticamente el margen de error del RSI (ej. baja a error de 8.3ms en 120fps).
* **Motor Asíncrono e Isolates**:
  - `VideoProcessorService`: Extrae silenciosamente cada frame JPEG del video en una caché oculta utilizando comandos nativos de `ffmpeg_kit_flutter_min_gpl`.
  - Mantenimiento UI fluido: Tanto ML Kit (Pliometría) como la iteración binaria por color HSV (VBT) fueron desplazados a un hilo paralelo multiescala (`Isolate.run`), permitiendo que el hilo de Dart principal respire y muestre indicadores fluidos de progreso.
* **Overlays Interactivos de Reproducción**:
  - En lugar de dibujar poses estáticas, la app ahora sincroniza las etiquetas de **🔵 VUELO** y **🟢 CONTACTO** con la reproducción en el tiempo del propio `VideoPlayer` (Pliometría).
  - Componente VBT dibuja una gráfica analítica compacta (`fl_chart`) superpuesta al reproductor indicando la trayectoria exacta per-pixel calculada y marcando la fase concéntrica.

### Sistema y Gestión
* **Dependencias**: Se eliminó `camera`. Se incorporaron `image_picker`, `video_player`, `ffmpeg_kit_flutter_min_gpl` e `image`. (Atención al aumento del tamaño APK a causar de dependencias C++ como libffmpeg).
* **Gestión de Memoria (Test 6)**: Limpieza heurística agresiva (`delete(recursive: true)`) de la memoria /cache al terminar o abortar el análisis.
* **Certificación FPS (Test 5)**: Pruebas unitarias extendidas validando que 30fps y 60fps generen velocidades (`VMC`) idénticas ante equivalencias de distancia.

---
## v0.1.0 - 2026-03-29 🔬 Laboratorio Axon

### Funcionalidades
* **Laboratorio Axon**: Nueva sección accesible desde el Drawer (`Icons.biotech`) con análisis de rendimiento deportivo en tiempo real mediante la cámara del dispositivo.
  - Dos módulos: **Potencia y Gimnasio (VBT)** y **Pliometría y Carrera (RSI)**
  - Pantalla principal con tarjetas animadas (micro-animaciones on tap) y paleta Titanium Minimalist (`#F8FAFC` / `#0284C7`)

* **VBT — Velocity Based Training**:
  - `VbtCalibrationScreen`: Input del diámetro del disco (ej. 0.45 m) con presets de carga olímpica. Calcula automáticamente el ratio px/m.
  - `VbtAnalysisScreen`: `CameraPreview` con overlay `VbtTrackingPainter` (círculo de tracking + línea de trayectoria en degradado) sobre el disco.
  - Detección de fases: ↓ Excéntrica / — Isometría / ↑ Concéntrica con anti-ruido (`minConcentricFrames`).
  - Cálculo VMC (Velocidad Media Concéntrica): desplazamiento(m) / tiempo_concéntrico(s).
  - Detección de disco por color (espacio HSV) con blob detection.

* **Pliometría y Carrera (RSI)**:
  - `PlyometryAnalysisScreen`: ML Kit Pose Detection con `PosePainter` que superpone el esqueleto completo sobre la cámara.
  - Máquina de estados: `idle → grounded → takeoff → flight → landing` con debounce por frames.
  - Indicadores: 🟢 Contacto / 🔵 Vuelo / 🟡 Aterrizaje con colores en tiempo real.
  - RSI = TV(s) / TC(s) con código de color (verde ≥2.5, ámbar ≥1.5, rojo <1.5).

* **Gestión de Datos**:
  - Modelo `AxonAnalysisModel` (Hive `typeId: 4`) con campos VBT y Pliometría unificados.
  - `AxonLabProvider` (Riverpod): persistencia local (Hive) + sync Firestore.
  - Etiquetado por **Carpetas de Análisis** (ej. "Sentadilla Posterior ½").
  - Actualización automática del **ADN del Atleta** en Firestore (`users/{uid}/dna_atletico/axon_lab`) al guardar.

* **Tests unitarios** (20 tests, todos pasando):
  - `test/lab/vbt_calibration_test.dart` → error < 3%, inversibilidad, edge cases
  - `test/lab/vbt_phase_detection_test.dart` → isometría no dispara concéntrica, ruido, proporcionalidad VMC
  - `test/lab/plyometry_timing_test.dart` → RSI puro, desviación ≤1 frame (33ms), estados válidos/inválidos

### Dependencias añadidas
* `camera: ^0.11.0+2` — Preview y captura de frames
* `google_mlkit_pose_detection: ^0.12.0` — Detección de esqueleto para RSI
* `path_provider: ^2.1.3` — Almacenamiento local

### Problemas conocidos
* ML Kit Pose Detection **requiere dispositivo físico Android** con GPU (no funciona en emulador).
* El tracking de disco usa detección por color HSV. En condiciones de muy baja iluminación o discos sin contraste puede perder el lock (Test 4 pendiente validación en dispositivo).

### Sugerencias
* Añadir histórico con gráficas de VMC y RSI por ejercicio (integrar con `fl_chart`).
* Exportar sesión de Laboratorio Axon a PDF/CSV.
* Soporte para análisis offline de video ya grabado.
* Implementar tracking con TensorFlow Lite para mayor robustez en disco sin color contrastante.

---
## v0.0.9+2 - 2026-03-23 🐛 Hotfix: Sync Crash & Context

### Correcciones y mejoras
* ✅ **Crash en Sincronización**: Solucionado error al forzar sincronización desde el Drawer.
  - **Causa**: Uso de `context` desmontado al cerrar el Drawer antes de abrir el diálogo, y conflicto de nombres de variable `context`.
  - **Solución**: Se mantiene el Drawer abierto durante el proceso y se usa un contexto explícito (`dialogContext`) para el diálogo.

---
## v0.0.9+1 - 2026-03-23 🐛 Hotfix: Drawer Crash

### Correcciones y mejoras
* ✅ **Estabilidad Drawer**: Solucionado definitivamente el crash al abrir el menú lateral.
  - **Causa**: Conflicto de layout (`RenderFlex children have non-zero flex but incoming width constraints are unbounded`) al usar `Flexible` dentro de un `Row` anidado.
  - **Solución**: Se envolvieron los widgets de información (chips de deporte/categoría) en `Flexible` dentro del `Row` padre en `AthleteDrawer`.

---
## v0.0.9 - 2026-03-18 🏀 Athlete-First Drawer & Profile Editing

### Funcionalidades
* **Drawer "Athlete-First"**: Nuevo menú lateral con diseño tipo "ID Card" deportiva
  - Header con avatar (iniciales), nombre y rol en misma línea
  - Badges de perfil deportivo y categoría
  - Gradiente azul con estilo profesional
* **Navegación del Drawer**:
  - "Mi Perfil" → `ProfileScreen` con edición campo por campo
  - "Sincronización" → Estado en tiempo real + botón forzar sync
  - "Cerrar Sesión" al final del drawer (separado con spacer)
* **ProfileScreen**: Edición individual de cada campo del perfil
  - TextFields para campos de texto
  - DatePicker para fechas
  - SimpleDialog para opciones (Sexo, Perfil Deportivo)
  - Guardado automático con `saveAndSyncProfile()`
* **Sincronización reactiva**:
  - `sessionListProvider` muestra cantidad de sesiones pendientes en tiempo real
  - Diálogo de sincronización con estado detallado
  - `syncPending()` para forzar subida a Firebase

### Correcciones y mejoras
* ✅ **Layout Drawer**: Corregido `mainAxisSize: MainAxisSize.min` en Row de chips para evitar unbounded constraints
* ✅ **Botón logout**: Eliminado duplicado del AppBar, ahora solo en drawer

### Problemas conocidos
* **Drawer crashea**: Persisten crashes de layout al abrir el drawer (investigando)


---

## v0.0.8 - 2026-03-18 🚀 MyoAxon Rebranding & Sync
### Funcionalidades
* **Reactivación de Autenticación**: Restaurado el flujo completo de `AuthGate` y `LoginScreen` (superando el modo de inicio rápido de v0.0.7).
* **Rebranding a MyoAxon**: Renombre total del paquete y la aplicación en todas las plataformas.
* **Perfiles de Usuario & Roles**:
  - Implementación de `UserProfileModel` con roles (`atleta` / `entrenador`).
  - Pantalla `CompleteProfileScreen` para recolección de datos iniciales.
  - Control de acceso basado en roles en el historial.
* **Sincronización Offline-First**:
  - Guardado inmediato en Hive y subida asíncrona a Firestore.
  - Reintento automático de sincronización de sesiones pendientes al iniciar sesión.
* **Refinamiento de Modelos**:
  - `TechExerciseModel`: Renombrado `serieNum` a `series` para claridad (cantidad total de series).
* **Limpieza de Arquitectura**:
  - Eliminado `RegistroScreen` legacy en favor de `NuevoRegistroScreen`.
  - Eliminados modelos y repositorios obsoletos (`ExerciseRecord`, `TrainingRepository`).

### Correcciones y mejoras
* ✅ **Aislamiento Estricto**: Corregido bug donde sesiones de otros usuarios podían aparecer en el Dashboard.
* ✅ **Estabilidad de Hive**: Regeneración de adaptadores tras cambios en los modelos.
* ✅ **Código Limpio**: Reducción de deuda técnica eliminando 4 archivos huérfanos.

### Problemas conocidos
* **Drawer crashea al abrir**: El menú lateral (drawer) tiene problemas de layout (unbounded constraints) que causan crash al abrir. Se está trabajando en la corrección.
* **Versión web sin configurar**: La app no funciona en navegador porque falta configuración de Firebase para web (firebase_options.dart requiere valores reales).

---

## v0.0.7 - 2026-03-12 Inicio Rápido (Auth desactivado)

### Funcionalidades

* **Modo de inicio rápido sin autenticación**: La aplicación ahora inicia directamente en `MainScreen` sin requerir login
* **LoginScreen deshabilitado**: Pantalla de login muestra mensaje informativo cuando se accede
* **Eliminación de dependencias de autenticación en tiempo de ejecución**: La app funciona sin Firebase Auth configurado
* **Mantenida compatibilidad futura**: Estructura preparada para reactivar autenticación cuando sea necesario

### Problemas conocidos

* **Firebase Auth deshabilitado**: Funcionalidad de multi-usuario y sincronización cloud no disponible en este modo
* **LoginScreen no funcional**: La pantalla de login solo muestra mensaje informativo (no se puede iniciar sesión)
* **Dependencias Firebase en pubspec.yaml**: Aún presentes pero no utilizadas (pueden eliminarse para reducir tamaño)

### Correcciones y mejoras

* ✅ **Inicio más rápido**: Eliminado el flujo de autenticación reduce tiempo de arranque
* ✅ **App funcional offline**: No requiere conexión a Firebase para operaciones básicas
* ✅ **Código simplificado**: Eliminada complejidad de Riverpod providers para auth
* ✅ **Fácil reactivación**: Documentada ruta para restaurar autenticación completa

### Cómo reactivar la autenticación

Para volver a habilitar el sistema de login completo:

1. Restaurar `lib/providers/auth_provider.dart` con `AuthService` y proveedores Riverpod
2. Modificar `lib/main.dart` para usar `authStateProvider` y navegar condicionalmente
3. Restaurar `lib/ui/screens/main_screen.dart` a versión con `ConsumerStatefulWidget` y botón logout
4. Restaurar `lib/ui/screens/login_screen.dart` con formulario completo y lógica de auth
5. Verificar configuración Firebase (google-services.json, firebase_options.dart)
6. Ejecutar `flutter pub get` y `flutter pub run build_runner build`

---

## v0.0.6 - 2026-03-10 🔐 Autenticación Multi-Usuario con Firebase

### Funcionalidades

* **Autenticación Firebase Auth completa**:
  - Registro de usuarios con email/contraseña
  - Inicio de sesión con validación de credenciales
  - Recuperación de contraseña via email
  - Stream de estado de autenticación en tiempo real
* **Modelo de perfil de usuario (`UserProfile`)**: Almacenamiento local en Hive con datos de Firebase (UID, email, nombre, foto, fechas)
* **Aislamiento de datos multi-usuario**: Cada usuario solo ve sus propias sesiones de entrenamiento
* **Integración Riverpod + Firebase Auth**:
  - `authStateProvider`: Stream de estado de autenticación
  - `currentUserIdProvider`: UID del usuario actual
  - `userProfileProvider`: Perfil de usuario desde Firestore
* **SessionModel mejorado**: Campo `userId` para vinculación con Firebase UID
* **SessionRepository con filtrado por usuario**: Métodos `getAllSessionsForUser()` y `getUnsyncedSessionsForUser()`
* **SessionProvider actualizado**: Carga automáticamente solo las sesiones del usuario autenticado
* **NuevoRegistroScreen**: Asigna automáticamente el `userId` al guardar sesiones
* **LoginScreen completo**: Formulario de login/registro con validación y manejo de errores

### Problemas conocidos

* **Firebase opcional**: La app funciona sin conexión si `firebase_options.dart` no está configurado, pero la sincronización cloud queda deshabilitada
* **Build runner requerido**: Modificar modelos Hive exige ejecutar `flutter pub run build_runner build` para regenerar adaptadores
* **Dependencia de google-services.json**: Android requiere el archivo de configuración Firebase en `android/app/`
* **Perfil de usuario no persistente en Firestore**: El método `getUserProfileFromFirestore()` actualmente retorna datos de Firebase Auth, no de Firestore (pendiente implementar colección `users`)

### Correcciones y mejoras

* ✅ **Aislamiento de datos**: Cada usuario ahora ve únicamente sus propias sesiones
* ✅ **ID de atleta automático**: Se usa el Firebase UID como `idAtleta` en `SessionModel`
* ✅ **Login integrado**: Redirección automática desde `LoginScreen` a `MainScreen` tras autenticación exitosa
* ✅ **Validación robusta**: Manejo de errores de Firebase Auth con mensajes específicos
* ✅ **SessionRepository mejorado**: Métodos específicos para filtrado por usuario

### Sugerencias

* Implementar colección `users` en Firestore para perfiles completos
* Añadir funcionalidad de editar perfil de usuario
* Implementar sincronización bidireccional completa (descargar sesiones desde cloud)
* Añadir soporte para múltiples atletas por cuenta (familias/entrenadores)
* Escribir tests unitarios para AuthService y SessionRepository con filtrado
* Añadir verificación de email obligatoria
* Implementar login con Google/Apple para mayor comodidad
* Añadir logout con confirmación
* Configurar notificaciones push para recordatorios de entrenamiento

---


## v0.0.5+1 - 2026-03-10 🎯 Migración Flutter Completa + Tests

### Funcionalidades

* **Migración completa a Flutter**: Transformación total de Apps Script/HTML a aplicación nativa Flutter con Dart
* **Arquitectura Clean Architecture**: Estructura modular con carpetas `data/`, `providers/`, `ui/` siguiendo principios de separación de responsabilidades
* **State Management con Riverpod**: Implementación de `StateNotifierProvider` para gestión reactiva de estado
* **Base de datos local Hive**: Almacenamiento offline-first con TypeAdapters generados para modelos de sesión y ejercicios
* **Integración Firebase**: Sincronización opcional con Firestore mediante repositorio abstracto
* **UI Material Design 3**: Tema oscuro con `ColorScheme.fromSeed` y componentes modernos
* **Navegación por pestañas**: `MainScreen` con `BottomNavigationBar` y `IndexedStack` para 3 vistas principales
* **Widgets especializados**:
  - `GymExerciseCard`: Input para ejercicios de gimnasio (series, reps, peso, RIR, descanso, notas)
  - `TechExerciseCard`: Input para ejercicios técnicos (series, reps, métrica, descanso, notas)
  - `StepperInputCard`: Control numérico con botones incrementales
* **Autocompletado de ejercicios**: Integración de `flutter_typeahead` para búsqueda en catálogo
* **Registro de atletas**: ID autoincremental persistente en Hive
* **IDs de sesión compuestos**: Formato `IDAtleta_Fecha_TipoSesion` preservado desde AppScript
* **Orden de ejercicios preservado**: Campo `orden` en cada ejercicio para mantener secuencia
* **Dashboard con gráficos**: `fl_chart` para visualización de progreso de volumen de entrenamiento

### Problemas conocidos

* **Firebase opcional**: La app funciona sin conexión si `firebase_options.dart` no está configurado, pero la sincronización cloud queda deshabilitada
* **Build runner requerido**: Modificar modelos Hive exige ejecutar `flutter pub run build_runner build` para regenerar adaptadores
* **Dependencia de google-services.json**: Android requiere el archivo de configuración Firebase en `android/app/`

### Correcciones y mejoras (vs AppScript)

* ✅ **Eliminación de Google Sheets**: Reemplazado por Hive local + Firestore cloud
* ✅ **Frontend nativo**: HTML/CSS/JS → Flutter widgets con mejor rendimiento y UX
* ✅ **State management centralizado**: Variables JS dispersas → Riverpod providers
* ✅ **Offline-first**: Datos se guardan localmente primero, sincronización asíncrona después
* ✅ **Código maintainable**: Arquitectura modular, testable, con tipos fuertes
* ✅ **Gráficos integrados**: `fl_chart` para visualización de progreso de volumen
* ✅ **Widgets reutilizables**: Componentes tipo-safe para diferentes modalidades de ejercicio
* ✅ **Limpieza de archivos obsoletos**: Eliminados `Codigo.gs` e `Index.html` de la versión AppScript

### Sugerencias

* Implementar autenticación de atletas con Firebase Auth
* Añadir más métricas de gráficos (fuerza, RIR promedio, frecuencia)
* Exportar datos a CSV/PDF desde Historial
* Sincronización bidireccional completa (descargar cambios desde cloud)
* Escribir tests unitarios para providers y repositorios
* Añadir soporte multiidioma con `intl`
* Implementar tema claro/oscuro toggle
* Configurar notificaciones push para recordatorios de entrenamiento
* Optimizar rendimiento de listas largas con `ListView.builder`

---

**Última actualización**: 2026-04-14
**Versión actual**: v0.4.0 — Rutinas Compartibles & Auto-categorización
**Estado**: Estable — Listo para exportar datos con seguridad.
