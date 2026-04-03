# 🏋️ MyoAxon — v0.2.0

Aplicación Flutter para el registro, seguimiento y **análisis de rendimiento deportivo en tiempo real** mediante la cámara del dispositivo. Desarrollada con **Clean Architecture** y arquitectura modular.
Busca ser un Ecosistema de Optimización para atletas de pista y campo: un laboratorio de bolsillo que conecta métricas de carga (VBT), pliometría (RSI) y técnica con los entrenadores para ajustar el rendimiento en tiempo real.

## 🧪 Testing

El proyecto incluye una suite completa de tests unitarios (26 tests totales):

```bash
# Todos los tests
flutter test

# Solo tests de Laboratorio Axon (lógica VBT + RSI pura)
flutter test test/lab/

# Tests de modelos de datos
flutter test test/models/

# Con cobertura
flutter test --coverage
```

### Cobertura de Tests

**Modelos de datos**
- ✅ **SessionModel**: Constructores, serialización Firebase, validaciones
- ✅ **GymExerciseModel**: CRUD, toFirebase/fromFirebase, cálculos
- ✅ **TechExerciseModel**: CRUD, toFirebase/fromFirebase, validaciones

**Laboratorio Axon (Offline) (23 tests)**
- ✅ **VBT Calibración**: error < 3%, inversibilidad, edge cases de ratio px/m
- ✅ **VBT Detección de Fase**: isometría no dispara concéntrica, debounce anti-ruido, proporcionalidad VMC
- ✅ **Pliometría RSI**: cálculo puro TV/TC, desviación ≤1 frame (33ms a 30fps), validez de resultado
- ✅ **Integración Offline**: Consistencia FPS métrica (Test 5) y validación de purgado de caché de memoria de video (Test 6).

Ver detalles en [`test/README.md`](test/README.md:1).

## 🔐 Autenticación Multi-Usuario

La aplicación implementa autenticación completa con **Firebase Auth**, permitiendo que múltiples usuarios utilicen la app con datos completamente aislados:

### Características de Autenticación

- **Registro de usuarios**: Crear cuenta con email y contraseña
- **Inicio de sesión**: Autenticación con credenciales existentes
- **Recuperación de contraseña**: Envío de email para restablecimiento
- **Aislamiento de datos**: Cada usuario solo ve sus propias sesiones de entrenamiento
- **Perfil de usuario**: Almacenamiento local y remoto con roles (`atleta`/`entrenador`), fecha de nacimiento y pesos.
- **Sincronización Inteligente**: Envío automático a Firestore tras guardado local y reintento al inicio.

### Flujo de Autenticación

1. **Primer inicio**: La app muestra `LoginScreen` automáticamente
2. **Registro**: Usuario crea cuenta → Firebase Auth crea UID → Perfil local se guarda en Hive
3. **Login**: Usuario se autentica → `authStateProvider` notifica cambio → Navegación a `MainScreen`
4. **Datos**: Al guardar sesiones, se asigna automáticamente el `userId` del usuario autenticado
5. **Filtrado**: `SessionRepository` filtra todas las consultas por `userId` para aislamiento total

### Proveedores de Autenticación (Riverpod)

- [`authStateProvider`](lib/providers/auth_provider.dart:9): Stream de estado de autenticación
- [`currentUserIdProvider`](lib/providers/auth_provider.dart:19): UID del usuario actual
- [`isAuthenticatedProvider`](lib/providers/auth_provider.dart:24): Booleano de estado de login
- [`userProfileProvider`](lib/providers/auth_provider.dart:29): Perfil de usuario desde Firestore

### Modelos de Datos

- **`UserProfile`** ([`lib/data/models/user_profile_model.dart`](lib/data/models/user_profile_model.dart)): Perfil de usuario extendido con roles.
- **`SessionModel.userId`** ([`lib/data/models/session_model.dart`](lib/data/models/session_model.dart)): Vinculación única por usuario.

### Servicios

- **`AuthService`** ([`lib/data/services/auth_service.dart`](lib/data/services/auth_service.dart:1)): Lógica de autenticación Firebase Auth
- **`SessionRepository.getUserSessions()`**: Filtra sesiones por `userId` para aislamiento

### Pantallas

- **`LoginScreen`** ([`lib/ui/screens/login_screen.dart`](lib/ui/screens/login_screen.dart:1)): Formulario de login/registro con validación
- **`NuevoRegistroScreen`** ([`lib/ui/screens/nuevo_registro_screen.dart`](lib/ui/screens/nuevo_registro_screen.dart:99)): Asigna `userId` automáticamente al guardar

### Configuración Requerida

Para habilitar autenticación completa:

1. **Firebase project**: Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. **Habilitar Authentication**: Email/Password provider en Firebase Auth
3. **Configurar Firebase Flutter**:
   ```bash
   flutterfire configure
   ```
4. **Android**: Agregar `google-services.json` en `android/app/`
5. **iOS**: Agregar `GoogleService-Info.plist` en `ios/Runner/`

Ver instrucciones completas en la [documentación oficial](https://firebase.flutter.dev/docs/overview).

## 📋 Características

- **Registro de Sesiones de Entrenamiento**: Captura completa de datos de entrenamiento (fecha, tipo, fase, sueño, fatiga, intensidad, limitantes)
- **Soporte Multimodal**: 
  - 🏋️ **Gimnasio**: Series, repeticiones, peso, RIR, descanso, notas
  - 🏃 **Técnica/Pista**: Series, repeticiones, métrica (tiempo/distancia/altura), descanso, notas
- **Módulo de Atletas**: Registro de atletas con ID autoincremental y perfil completo
- **Historial de Entrenamientos**: Visualización de registros guardados
- **Dashboard Analítico**: Gráficos de progreso y estadísticas
- **Base de Datos Local**: Hive para almacenamiento offline
- **Sincronización Cloud**: Firebase Firestore para backup y multi-dispositivo
- **State Management**: Riverpod para gestión de estado reactiva

### 🎬 Laboratorio Axon *(v0.2.0 - Offline)*

Sección biomécanica de análisis de videos por computadora que opera íntegramente de forma asíncrona mediante hilos dedicados (**Isolates**) y **FFmpeg**, garantizando tiempo exacto basado en *frames* calculados ($1/fps$) en lugar de variaciones de CPU.

- **VBT — Velocity Based Training** (Potencia y Gimnasio):
  - Ingesta de video y extracción rápida vía `ffmpeg_kit_flutter`.
  - Calibración matemática por diámetro de disco y tracking de barra en background sin frisar el UI.
  - Detección de fases transitorias y cálculo de **VMC** (Velocidad Media Concéntrica) en m/s.
  - Reproductor con superposición UI `fl_chart` indicando gráficamente la curva interactiva.
- **Pliometría & Carrera — RSI** (CMJ, Bounds, Sprints):
  - Procesamiento ML Kit Pose Detection delegable frame-a-frame iterativo.
  - HUD Sincronizado sobre el estado del `VideoPlayer` con estatus visual (🟢 CONTACTO / 🔵 VUELO).
  - Cálculo de **RSI** exacto de grado clínico (dependiente de los FPS del video del dispositivo).
- **Control de Recursos**: Purgador automático para evitar colapsar almacenamiento (`VideoProcessorService`).

#### 🔬 ¿Cómo funcionan los algoritmos del Laboratorio Axon?

**1. Módulo VBT (Velocity Based Training)**
El objetivo de VBT es extraer la Velocidad Media Concéntrica (VMC) de un levantador para medir el grado de esfuerzo y regular la carga del día. Su funcionamiento interno se divide en 4 etapas:
1. **Extracción y Decodificación:** `FFmpeg` destroza el video en cientos de *frames* crudos. Un *Isolate* (hilo de ejecución en el fondo) utiliza `package:image` para decodificar los bytes RGBA de cada cuadro a nivel binario.
2. **Tracking Dinámico e IA Básica:** Usando procesamiento de color y algoritmos de blob detection, el software ubica el disco del levantador (conociendo que su contraparte en la vida real es de 0.45m en levantamientos olímpicos) extrayendo el radio y estableciendo la densidad de Píxeles por Metro.
3. **Máquina de Fases Biomecánica:** Se traza una curva de trayectoria $Y$ de toda la barra. El modelo filtra el ruido cinético mediante *debouncing*, detectando cuando la barra *baja* (excéntrica) e *ignora matemáticamente* las micropausas (isometría). En el primer frame de subida sostenida, inicia el cronómetro analítico purgado de lags ($+ \Delta ms$ nativos extraídos de la tasa de FPS de `FFprobe`) detectando la **Fase Concéntrica**.
4. **Overlay y Output:** Los datos matemáticos puros se alimentan a un generador cartográfico (`fl_chart`) que superpone el pico y esfuerzo directamente sobre el reproductor nativo del video.

**2. Módulo RSI (Pliometría y Carrera)**
Mide la fuerza elástica y reactiva de los tendones del atleta calculando $\text{RSI} = \text{Tiempo de Vuelo} / \text{Tiempo de Contacto}$. Funciona puramente iterativo:
1. **Pose Detection Paralelizada:** El *video frame batch* es bombeado secuencialmente al motor en C++ de **Google ML Kit** bajo inicialización de persistencia asíncrona (`BackgroundIsolateBinaryMessenger`), retornando landmarks y coordenadas 3D de todas las articulaciones frame por frame.
2. **Máquina de Estados de Vuelo:**
   - **Grounded:** Monitorea la estabilidad estática de las coordenadas proyectadas en el suelo (Marcadores 31 y 32 de tobillos y puntas de pie). Suma el TC (Tiempo de Contacto).
   - **Takeoff:** Al detectar quiebre de umbral gravitacional inter-frame, cambia el estado de *Grounded* a *Flight* sumando el TV (Tiempo de Vuelo).
   - **Landing:** Detecta el re-ingreso cinemático al eje Y inicial, completando un *Ciclo de Salto Plio*.
3. **Sincronización HUD Inter-Video:** Como el análisis ya obtuvo y *conoce* los milisegundos exactos relativos al inicio, inyectamos un `Listener` en el `VideoPlayer` que muta el estado de una Label Superpuesta (**🟢 CONTACTO** vs **🔵 VUELO**) logrando un efecto de Realidad Aumentada clínica.

## 🏗️ Arquitectura

```
lib/
├── main.dart                    # Inicialización y configuración principal
├── data/
│   ├── models/                 # Modelos de datos (Hive)
│   │   ├── session_model.dart
│   │   ├── gym_exercise_model.dart
│   │   ├── tech_exercise_model.dart
│   │   └── axon_analysis_model.dart  # 🆕 VBT + RSI (typeId: 4)
│   ├── repositories/            # Repositorios (abstracción de datos)
│   │   └── session_repository.dart
│   └── services/                # Servicios de análisis Puros & Offline
│       ├── vbt_analyzer_service.dart      # Calibración, VMC, listado trayectorias Y
│       ├── plyometry_analyzer_service.dart # ML Kit iteración por timestamps simulados
│       └── video_processor_service.dart   # 🆕 Extracción FFmpeg y limpieza de caché
├── providers/                   # State Management (Riverpod)
│   ├── session_provider.dart
│   ├── user_profile_provider.dart
│   └── axon_lab_provider.dart   # 🆕 Persistencia + sync Laboratorio Axon
└── ui/
    ├── screens/                # Pantallas
    │   ├── main_screen.dart
    │   ├── nuevo_registro_screen.dart
    │   ├── historial_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── laboratorio_axon_screen.dart   # 🆕 Hub con 2 módulos
    │   ├── vbt_calibration_screen.dart    # 🆕 Calibración px/m
    │   ├── vbt_analysis_screen.dart       # 🆕 Cámara + tracking overlay
    │   └── plyometry_analysis_screen.dart # 🆕 ML Kit + RSI
    ├── widgets/                # Widgets reutilizables
    │   ├── athlete_drawer.dart  # ← Actualizado con entrada Laboratorio Axon
    │   ├── gym_exercise_card.dart
    │   ├── tech_exercise_card.dart
    │   └── stepper_input_card.dart
    └── charts/
        └── volume_line_chart.dart
```

## 🚀 Instalación

### Prerrequisitos

- Flutter SDK (^3.2.0)
- Dart SDK
- Android Studio / VS Code
- Firebase project configurado

### Configuración

1. **Clonar e instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Generar código Hive**:
   ```bash
   flutter pub run build_runner build
   ```

3. **Configurar Firebase**:
   - Agregar archivo `firebase_options.dart` generado por `flutterfire configure`
   - Configurar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)

4. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

## 📦 Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter_riverpod` | ^2.5.1 | State Management |
| `firebase_core` | ^3.15.2 | Firebase inicialización |
| `cloud_firestore` | ^5.6.12 | Base de datos cloud |
| `firebase_auth` | ^5.0.0 | Autenticación |
| `hive` | ^2.2.3 | Base de datos local |
| `hive_flutter` | ^1.1.0 | Integración Hive-Flutter |
| `video_player` | ^2.9.2 | 🆕 Native video view |
| `image_picker` | ^1.1.2 | 🆕 Galería Media |
| `ffmpeg_kit_flutter_min_gpl`| ^6.0.3 | 🆕 C++ backend Video Decoder |
| `google_mlkit_pose_detection` | ^0.12.0 | Detección de esqueleto (RSI) |
| `image` | ^4.1.7 | 🆕 Image binary parsing |
| `path_provider` | ^2.1.3 | Almacenamiento de archivos |
| `fl_chart` | ^0.68.0 | Gráficos e UI analítica |
| `flutter_typeahead` | ^5.1.0 | Autocompletado |
| `uuid` | ^4.3.3 | Generación de IDs |
| `intl` | ^0.19.0 | Internacionalización |

## 🔄 Migración desde AppScript

Esta Flutter app es una migración completa de la versión original en Google Apps Script (`Codigo.gs`, `Index.html`):

### Cambios Principales

1. **Frontend**: HTML/CSS/JS → Flutter (Dart)
2. **Backend**: Google Sheets + Apps Script → Firebase Firestore + Hive local
3. **State Management**: JavaScript DOM → Riverpod
4. **UI/UX**: Estilo web responsivo → Material Design 3
5. **Persistencia**: Google Sheets → Base de datos local + cloud

### Archivos Eliminados

- `Codigo.gs` - Lógica server-side Apps Script
- `Index.html` - Interfaz web HTML/CSS/JS
- `firebase.json` - No necesario en Flutter (se usa `firebase_options.dart`)

### Funcionalidades Preservadas

- ✅ Registro de sesiones (Gimnasio/Técnica)
- ✅ Catálogo de ejercicios con autocompletado
- ✅ Registro de atletas con ID autoincremental
- ✅ Cálculo de IDs de sesión compuestos
- ✅ Orden de ejercicios preservado
- ✅ Campo de descanso entre series

## 📱 Estructura de Datos

### SessionModel
```dart
{
  "idSesion": "01_20250115_G",        // ID compuesto: Atleta_Fecha_Tipo
  "idAtleta": "01",
  "fecha": DateTime,
  "tipoSesion": "Gimnasio" | "Técnica",
  "faseEntrenamiento": "general",
  "horasSueno": 7.5,
  "fatiguaPreentrenamiento": 3,
  "intensidadPercibida": 8,
  "limitantes": "Molestia isquiotibiales",
  "ejerciciosGim": List<GymExerciseModel>,
  "ejerciciosTech": List<TechExerciseModel>,
  "isSynced": bool
}
```

### GymExerciseModel
```dart
{
  "orden": 1,
  "nombre": "Sentadillas",
  "series": "4",
  "reps": "8-10",
  "peso": "80kg",
  "rir": "2",
  "descanso": "2'30",
  "notas": "Baja técnica en última serie"
}
```

## 🧪 Testing

```bash
flutter test
```

## 📄 Licencia

Propietario - Todos los derechos reservados

## 👥 Autor

Desarrollado con Flutter + Clean Architecture
