class EnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static String get apiBaseUrl {
    switch (environment) {
      case 'prod':
        return 'https://api.altayer.com';
      case 'staging':
        return 'https://staging-api.altayer.com';
      case 'dev':
      default:
        return 'http://10.0.2.2:3000';
    }
  }

  static String get socketUrl {
    switch (environment) {
      case 'prod':
        return 'https://socket.altayer.com';
      case 'staging':
        return 'https://staging-socket.altayer.com';
      case 'dev':
      default:
        return 'http://10.0.2.2:3000';
    }
  }
}
