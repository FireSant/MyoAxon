# 🏋️ MyoAxon — v0.6.2

Ecosistema de optimización deportiva para atletas y entrenadores. **MyoAxon** es un laboratorio de bolsillo que integra registro de carga, periodización científica (Axon Peak) y análisis biomécanico por video de alta precisión (Axon VBT & RSI).

## 🎬 Módulo Axon VBT: Bio-Cinemática (v0.6.2)

El corazón analítico de MyoAxon ahora integra un motor de análisis cinemático avanzado que permite cuantificar el rendimiento en tiempo real mediante video:

- **Análisis Basado en Frames**: Cálculo exacto de velocidad ($1/fps$) eliminando errores de latencia de CPU.
- **Modelos de Regresión Polinómica**: Estimación del 1RM mediante ecuaciones de 2do grado específicas para Tren Superior e Inferior, superando la precisión de los modelos lineales tradicionales.
- **Métricas de Potencia**: Cálculo instantáneo de Potencia Mecánica (Watts) basado en la carga (kg) y la velocidad media concéntrica (VMC).
- **Control de Fatiga**: Monitorización de la pérdida de velocidad inter-serie y Coeficiente de Variación (CV%) para ajustar la intensidad al momento.
- **Dashboard Social (Shareable Card)**: Generación nativa de una tarjeta de resultados de alta resolución (1080x1080) con gráficos de evolución y métricas clave para exportación directa.

### ¿Cómo funciona el algoritmo Axon VBT?
1. **Configuración**: Se ingresa el ROM (rango de movimiento en cm), el peso de la carga y el tipo de ejercicio.
2. **Marcación Precisa**: El usuario identifica el frame de inicio y fin de la fase concéntrica.
3. **Cálculo de VMC**: $V = \frac{ROM / 100}{\Delta Frames / FPS}$.
4. **Estimación e1RM**: Aplicación de la regresión:
   - *Tren Inferior*: $-1.133v^2 - 42.171v + 103.38$
   - *Tren Superior*: $-5.961v^2 - 56.485v + 117.09$

## 🧪 Testing

El proyecto incluye una suite completa de tests unitarios (26 tests totales):

```bash
# Todos los tests
flutter test

# Lógica VBT + RSI pura (Grado Clínico)
flutter test test/lab/

# Motor de Periodización Axon Peak
flutter test test/providers/axon_peak_provider_test.dart
```

### Cobertura de Tests

- ✅ **Modelos**: Session, GymExercise, TechExercise, AxonPeakConfig.
- ✅ **Axon Peak**: Generación de macrociclos, autorregulación VBT, lógica de bloques.
- ✅ **Axon VBT**: Calibración px/m, detección de fase concéntrica, consistencia de regresiones.
- ✅ **Pliometría RSI**: Cálculo TV/TC, detección ML Kit Pose (Landing/Takeoff).

## 📋 Características Principales

- **🧬 Axon Peak**: Periodización inteligente con proyecciones de carga automáticas.
- **🎬 Axon Lab (VBT/RSI)**: Laboratorio biomecánico offline con procesamiento asíncrono.
- **🔐 Multi-Usuario**: Autenticación Firebase con aislamiento total de perfiles y sesiones.
- **📱 UX Premium**: Modo oscuro, micro-animaciones, soporte de decimales flexible y teclados optimizados.
- **💾 Persistencia Dual**: Hive (Offline First) + Firestore (Cloud Sync).

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
│   ├── axon_lab_provider.dart   # Persistencia + sync Laboratorio Axon
│   └── axon_peak_provider.dart  # 🆕 Motor de Periodización Proyectada (Axon Peak)
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
