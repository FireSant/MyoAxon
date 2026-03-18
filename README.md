# 🏋️ MyoAxon

Aplicación Flutter para el registro y seguimiento de entrenamientos físicos, desarrollada con **Clean Architecture** y arquitectura modular.
Busca ser un Ecosistema de Optimización para atletas de pista y campo. Funciona como un laboratorio de bolsillo que conecta las métricas de carga y técnica directamente con los entrenadores para ajustar el rendimiento en tiempo real

## 🧪 Testing

El proyecto incluye una suite completa de tests unitarios para modelos de datos:

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests de modelos específicos
flutter test test/models/session_model_test.dart
flutter test test/models/gym_exercise_model_test.dart
flutter test test/models/tech_exercise_model_test.dart

# Con cobertura
flutter test --coverage
```

### Cobertura de Tests

- ✅ **SessionModel**: Constructores, serialización Firebase, validaciones
- ✅ **GymExerciseModel**: CRUD, toFirebase/fromFirebase, cálculos
- ✅ **TechExerciseModel**: CRUD, toFirebase/fromFirebase, validaciones

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

## 🏗️ Arquitectura

```
lib/
├── main.dart                 # Inicialización y configuración principal
├── data/
│   ├── models/              # Modelos de datos (Hive)
│   │   ├── session_model.dart
│   │   ├── gym_exercise_model.dart
│   │   └── tech_exercise_model.dart
│   ├── repositories/        # Repositorios (abstracción de datos)
│   │   └── session_repository.dart
├── providers/               # State Management (Riverpod)
│   ├── session_provider.dart
│   └── user_profile_provider.dart
└── ui/
    ├── screens/            # Pantallas principales
    │   ├── main_screen.dart
    │   ├── nuevo_registro_screen.dart
    │   ├── historial_screen.dart
    │   └── dashboard_screen.dart
    ├── widgets/            # Widgets reutilizables
    │   ├── gym_exercise_card.dart
    │   ├── tech_exercise_card.dart
    │   └── stepper_input_card.dart
    └── charts/             # Componentes de gráficos
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
| `hive` | ^2.2.3 | Base de datos local |
| `hive_flutter` | ^1.1.0 | Integración Hive-Flutter |
| `fl_chart` | ^0.68.0 | Gráficos |
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
