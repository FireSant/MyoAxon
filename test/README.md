# Test Suite - MyoAxon

Tests unitarios para modelos de datos de la aplicación MyoAxon.

## 📁 Estructura Actual

```
test/
├── models/                    # Tests de modelos de datos
│   ├── session_model_test.dart
│   ├── gym_exercise_model_test.dart
│   ├── tech_exercise_model_test.dart
│   └── exercise_record_test.dart
└── README.md                  # Este archivo
```

## 🚀 Ejecutar Tests

```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/models/session_model_test.dart

# Con cobertura
flutter test --coverage

# Ver reporte de cobertura (si está disponible)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📋 Tests Incluidos

### Modelos de Datos

1. **`session_model_test.dart`**
   - Creación de sesiones de Gimnasio y Técnica
   - Serialización para Firebase
   - Manejo de listas vacías
   - Valores por defecto

2. **`gym_exercise_model_test.dart`**
   - Creación con todos los campos
   - Serialización/deserialización Firebase
   - Manejo de valores nulos
   - Cálculo de volumen

3. **`tech_exercise_model_test.dart`**
   - Creación con todos los campos
   - Serialización/deserialización Firebase
   - Manejo de valores nulos
   - Ejercicios con múltiples series

4. **`exercise_record_test.dart`**
   - Creación de registros
   - Cálculo de volumen (peso × reps)
   - Serialización JSON
   - Método copyWith
   - Manejo de valores por defecto

## 🎯 Cobertura Objetivo

- **Modelos**: 100% (constructores, getters, serialización)
- Tests simples y rápidos sin dependencias externas
- Fáciles de mantener y extender

## 📦 Dependencias

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

No se requieren dependencias adicionales para estos tests unitarios.

## 🔧 Notas

- Todos los tests son **unitarios puros** (no requieren Hive, Firebase ni Flutter framework)
- Se ejecutan rápidamente en cualquier entorno
- Fáciles de extender con nuevos casos de prueba
- Ideal para CI/CD pipelines