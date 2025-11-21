class ProtocolUtils {
  static String? getFirstNonEmptyValue(
    Map<String, dynamic> params,
    List<String> keys, {
    String? defaultValue,
  }) {
    for (String key in keys) {
      if (params.containsKey(key)) {
        var value = params[key];
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is bool || value is num) {
          return value.toString();
        } else if (value != null) {
          return value.toString();
        }
      }
    }
    return defaultValue;
  }

  static bool parseBooleanValue(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value == 1;
    }
    if (value is String) {
      String lowercased = value.toLowerCase();
      return lowercased == 'true' || lowercased == '1' || lowercased == 'yes';
    }
    return false;
  }
}
