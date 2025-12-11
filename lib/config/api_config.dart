class ApiConfig {
  // CHANGE THIS to your stable server domain or new ngrok URL
  static const String baseUrl =
      "https://divisionary-projective-linh.ngrok-free.dev";

  static String get recognize => "$baseUrl/api/v1/faces/recognize";
  static String get enroll => "$baseUrl/api/v1/faces/enroll";
}
