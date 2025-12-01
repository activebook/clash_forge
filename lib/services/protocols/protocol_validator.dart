import 'dart:convert';

// ============================================================================
// Protocol Parser Interface
// ============================================================================
class ProtocolValidator {
  static bool isValidPublicKey(String? key) {
    if (key == null) return false;
    try {
      if (key.isEmpty || key.length < 43 || key.length > 44) return false;
      String paddedKey = key;
      while (paddedKey.length % 4 != 0) {
        paddedKey += '=';
      }
      final bytes = base64Url.decode(paddedKey);
      return bytes.length == 32;
    } catch (e) {
      return false;
    }
  }

  static bool isValidCipher(String cipher) {
    const List<String> validCiphers = [
      'aes-128-gcm',
      'aes-192-gcm',
      'aes-256-gcm',
      '2022-blake3-aes-128-gcm',
      '2022-blake3-aes-256-gcm',
      '2022-blake3-chacha20-poly1305',
      'aes-128-cfb',
      'aes-192-cfb',
      'aes-256-cfb',
      'aes-128-ctr',
      'aes-192-ctr',
      'aes-256-ctr',
      'camellia-128-cfb',
      'camellia-192-cfb',
      'camellia-256-cfb',
      'chacha20',
      'chacha20-ietf',
      'chacha20-ietf-poly1305',
      'xchacha20-ietf-poly1305',
      'rc4-md5',
      'bf-cfb',
      'salsa20',
      'auto',
      'none',
    ];
    return validCiphers.contains(cipher);
  }

  static int? getKeyLengthForCipher(String cipher) {
    switch (cipher.toLowerCase()) {
      case 'aes-128-gcm':
      case 'aes-128-cfb':
      case 'aes-128-ctr':
      case 'camellia-128-cfb':
      case '2022-blake3-aes-128-gcm':
        return 16;
      case 'aes-256-gcm':
      case 'aes-256-cfb':
      case 'aes-256-ctr':
      case 'camellia-256-cfb':
      case 'chacha20':
      case 'chacha20-ietf':
      case 'chacha20-ietf-poly1305':
      case 'xchacha20-ietf-poly1305':
      case '2022-blake3-aes-256-gcm':
      case '2022-blake3-chacha20-poly1305':
        return 32;
      case 'aes-192-gcm':
      case 'aes-192-cfb':
      case 'aes-192-ctr':
      case 'camellia-192-cfb':
        return 24;
      default:
        return null;
    }
  }
}
