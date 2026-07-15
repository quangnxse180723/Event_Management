class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );
}
