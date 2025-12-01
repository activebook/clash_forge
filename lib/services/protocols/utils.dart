import 'dart:convert';

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

// ============================================================================
// Base64 utilities - shared across protocols
// ============================================================================
class Base64Utils {
  static String fixPadding(String input) {
    // Convert URL-safe base64 to standard base64
    input = input.replaceAll('-', '+').replaceAll('_', '/');
    // Remove any non-base64 characters
    input = input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
    switch (input.length % 4) {
      case 1:
        input = input.substring(0, input.length - 1);
        break;
      case 2:
        input += '==';
        break;
      case 3:
        input += '=';
        break;
    }
    return input;
  }

  static String decodeToUtf8(String input) {
    try {
      return utf8.decode(base64.decode(Base64Utils.fixPadding(input)));
    } catch (e) {
      throw FormatException('Invalid Base64 string');
    }
  }

  static bool isValid(String content) {
    if (content.isEmpty) return false;

    // Exclude UUIDs
    if (content.contains('-') &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(content)) {
      return false;
    }

    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(content.trim())) {
      return false;
    }

    try {
      String trimmed = fixPadding(content.trim());
      var decoded = base64.decode(trimmed);
      utf8.decode(decoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<int> decodeToBytes(String keyStr) {
    try {
      return base64.decode(Base64Utils.fixPadding(keyStr));
    } catch (e) {
      throw FormatException('Invalid Base64 string');
    }
  }
}

class UUIDUtils {
  /*
Protocol, UUID Requirement, Primary Authentication Method
VLESS, Yes, UUID
VMESS, Yes, UUID (and time check)
TUIC, Yes, UUID + Password (Token derived from both)
Anytls, Yes (Unique ID), Unique ID (often UUID) + Password
Trojan, No, Password / Key (Hashed)
SS / SSR, No, Password
Hysteria2, No, Password / Token
  */
  static bool isValid(String str) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(str);
  }
}
