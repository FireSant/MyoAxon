import 'dart:math' as math;

class AppConfig {
  // --- INFORMACIÓN DE VERSIÓN ---
  static const String version = '0.6.6';
  static const String build = '1';
  static const String fullVersion = 'v$version+$build';

  // --- BRANDING ---
  static const String appName = 'MyoAxon';
  static const String reportFooter = 'Generado con Axon VBT - Análisis cinemático';

  // --- CONSTANTES FÍSICAS ---
  static const double gravity = 9.80665;

  // --- MOTOR DE CÁLCULO CIENTÍFICO (1RM) ---
  
  /// Estima el % de 1RM basado en la velocidad media concéntrica (VMC)
  /// utilizando fórmulas polinómicas específicas por zona corporal.
  static double estimatePctRMFromVMC(double velocity, bool isLowerBody) {
    if (velocity <= 0) return 0.0;
    
    double pct;
    if (isLowerBody) {
      // Polinómica Tren Inferior: -1.133x² - 42.171x + 103.38
      pct = (-1.133 * math.pow(velocity, 2)) - (42.171 * velocity) + 103.38;
    } else {
      // Polinómica Tren Superior: -5.961x² - 56.485x + 117.09
      pct = (-5.961 * math.pow(velocity, 2)) - (56.485 * velocity) + 117.09;
    }

    // Seguridad: Limitar entre 10% y 100%
    return pct.clamp(10.0, 100.0);
  }

  /// Calcula el 1RM estimado usando la fórmula de Brzycki
  static double calculate1RMBrzycki(double weight, int reps) {
    if (reps <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight / (1.0278 - (0.0278 * reps));
  }

  /// Calcula la potencia mecánica en Watts
  static double calculatePower(double weightKg, double velocityMs) {
    return weightKg * gravity * velocityMs;
  }
}
