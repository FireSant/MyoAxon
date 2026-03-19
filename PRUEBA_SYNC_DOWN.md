# Guía de Prueba - Sync Down (Descarga desde Firebase)

## Objetivo
Verificar que la funcionalidad de descarga de sesiones desde Firebase funciona correctamente cuando un usuario inicia sesión en un dispositivo nuevo o con base de datos local vacía.

## Prerrequisitos
1. Tener Firebase configurado y la colección `sessions` con al menos 1 documento de prueba para el usuario.
2. La app debe estar en modo debug (para ver logs en consola).
3. Estar logueado con un usuario que tenga sesiones en Firebase.

## Pasos de Prueba

### Prueba A: Limpieza local y verificación de descarga

1. **Preparar dispositivo con datos existentes:**
   - Abre la app y navega a `HistorialScreen`.
   - Deberías ver sesiones locales (si hay).
   - Anota cuántas sesiones ves.

2. **Limpiar base de datos local:**
   - En `HistorialScreen`, toca el ícono de "escoba" (🔴) en la esquina superior derecha.
   - Confirma "Borrar" en el diálogo.
   - La lista debería quedar vacía.
   - Verás un SnackBar "Datos locales borrados".

3. **Forzar descarga desde Firebase:**
   - Cierra la app completamente (no solo background).
   - Vuelve a abrir la app (esto dispara el login automático si ya estabas logueado).
   - **Opcional:** Si no se descarga automáticamente, puedes hacer logout y login nuevamente.

4. **Verificar resultados:**
   - Las sesiones de Firebase deberían aparecer en `HistorialScreen`.
   - En la consola (VSCode terminal o logs del dispositivo) deberías ver:
     ```
     👤 [UserProfileProvider] Usuario logueado, iniciando pullFromFirebase
     🔄 [SessionProvider] Iniciando pullFromFirebase para userId: <tu-user-id>
     📥 [SessionRepository] Iniciando descarga de sesiones para userId: <tu-user-id>
     📥 [SessionRepository] Documentos encontrados en Firebase: X
     📥 [SessionRepository] Sesiones convertidas: X
     📥 [SessionRepository] ✅ Sesiones guardadas en Hive local
     🔄 [SessionProvider] Descarga completada, recargando estado local
     🔄 [SessionProvider] Estado local actualizado. Sesiones en state: X
     ```

### Prueba B: Verificar que no duplica

1. Con las sesiones ya descargadas, haz **logout** y **login** nuevamente.
2. Verifica que el número de sesiones **no aumente** (no debe haber duplicados).
3. En logs deberías ver:
   ```
   📥 [SessionRepository] Documentos encontrados en Firebase: X
   📥 [SessionRepository] Sesiones convertidas: X
   📥 [SessionRepository] ✅ Sesiones guardadas en Hive local
   ```
   (Hive `putAll` sobreescribe las mismas keys, no duplica)

### Prueba C: Sincronización cruzada entre dispositivos

1. **Dispositivo A:** Crea una nueva sesión.
   - Verifica en logs que sube a Firebase:
     ```
     ⬆️ [SessionRepository] Subiendo sesión a Firebase: <session-id>
     ```
2. **Dispositivo B:** (con el mismo usuario)
   - Si la app está abierta, la sesión debería aparecer después de unos segundos (por el `syncPending` automático).
   - Si no aparece, haz logout y login para forzar `pullFromFirebase`.
3. **Verificar:** La nueva sesión del dispositivo A aparece en dispositivo B.

## Notas Técnicas

### Comandos útiles

**Ver datos en Firebase (Firestore):**
```bash
firebase firestore:data:get sessions --pretty
```

**Filtrar por usuario:**
```bash
firebase firestore:data:get sessions --where user_id==<USER_ID> --pretty
```

**Limpiar datos locales desde código (alternativa al botón):**
```dart
import 'package:hive_flutter/hive_flutter.dart';
await Hive.box('sessions_box').clear();
```

### Archivos modificados

- `lib/data/repositories/session_repository.dart` - Método `downloadSessionsFromFirebase`
- `lib/providers/session_provider.dart` - Método `pullFromFirebase`
- `lib/providers/user_profile_provider.dart` - Llamada a `pullFromFirebase` en login
- `lib/ui/screens/historial_screen.dart` - Botón de depuración para limpiar Hive

## Criterios de Éxito

✅ Al iniciar sesión con usuario que tiene datos en Firebase, las sesiones aparecen en HistorialScreen.
✅ No se crean duplicados al hacer logout/login múltiples veces.
✅ Los logs muestran el flujo completo de descarga.
✅ Las sesiones descargadas tienen `isSynced = true`.

## Troubleshooting

**No aparecen sesiones después del login:**
- Verifica que el usuario tenga documentos en la colección `sessions` con el campo `user_id` correcto.
- Revisa los logs de error (deberían mostrar `❌ Error descargando sesiones`).
- Verifica que Firebase esté correctamente configurado y la app tenga permisos de lectura.

**Las sesiones aparecen pero no están ordenadas:**
- El orden es por fecha descendente (más reciente primero). Verifica que el campo `fecha` esté en formato ISO (yyyy-MM-dd) en Firestore.

**Los logs no aparecen:**
- Asegúrate de ejecutar la app en modo debug (`flutter run --debug`).
- En VSCode, revisa la pestaña "Debug Console" o "Run".
