class AppConfig {
  static const bool isDevelopment = true; // CAMBIA A FALSE si es producción

  static String get baseUrl {
    if (isDevelopment) {
      return "http://localhost:8080";  // Local
    } else {
      return "https://clias.ucuenca.edu.ec"; // Producción
    }
  }
}