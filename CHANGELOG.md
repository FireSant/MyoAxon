# Registro de versiones y novedades

Flujo de trabajo: Revisar correcciones y mejoras, desarrollar la tarea, probar mejora, registrar mejoras o errores capturados, subir a git.
Se registrara lo siguiente: Primero la version y fecha. Luego: `Funcionalidades`, `Problemas conocidos`, `Correcciones y merjoras`, `Sugerencias`

**Tests**: Todos los tests unitarios de modelos están implementados y listos para ejecutar con `flutter test`.

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

**Última actualización**: 2026-03-18  
**Versión actual**: v0.0.8 (MyoAxon Rebranding & Sync)  
**Estado**: Estable & Sincronizado (Autenticación Obligatoria)
