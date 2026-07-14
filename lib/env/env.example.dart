class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'NHAP_API_KEY_CUA_BAN_VAO_DAY',
  );
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );
}
