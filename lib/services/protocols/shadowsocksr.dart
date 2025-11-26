import 'dart:convert';
import 'protocol.dart';
import 'proxy_url.dart';

class ShadowsocksRProtocol implements Protocol {
  @override
  String get name => 'ssr';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    return url.toLowerCase().startsWith('ssr://');
  }

  String _fixBase64Padding(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        // Be lenient
        return input;
    }
    return output;
  }

  String _decodeBase64(String input) {
    try {
      return utf8.decode(base64.decode(_fixBase64Padding(input)));
    } catch (e) {
      // Return original if fail? Or throw?
      // In context of parsing, maybe return empty or original
      return input;
    }
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    if (!url.startsWith('ssr://')) {
      throw FormatException('Not a ShadowsocksR URL');
    }

    String base64Part = url.substring(6);
    String decoded;
    try {
      decoded = _decodeBase64(base64Part);
    } catch (e) {
      return {'type': 'ssr', 'error': 'Invalid Base64 in SSR URL'};
    }

    // Format: server:port:protocol:method:obfs:password_base64/?params

    int queryIndex = decoded.indexOf('/?');
    String mainPart;
    String queryPart = '';

    if (queryIndex != -1) {
      mainPart = decoded.substring(0, queryIndex);
      queryPart = decoded.substring(queryIndex + 2);
    } else {
      mainPart = decoded;
    }

    List<String> parts = mainPart.split(':');
    if (parts.length < 6) {
      return {'type': 'ssr', 'error': 'Invalid SSR format: insufficient parts'};
    }

    String server = parts[0];
    int port = int.tryParse(parts[1]) ?? 0;
    String protocol = parts[2];
    String method = parts[3];
    String obfs = parts[4];
    String passwordBase64 = parts[5];
    String password = _decodeBase64(passwordBase64);

    Map<String, String> params = {};
    if (queryPart.isNotEmpty) {
      List<String> queryParams = queryPart.split('&');
      for (var param in queryParams) {
        int eqIndex = param.indexOf('=');
        if (eqIndex != -1) {
          String key = param.substring(0, eqIndex);
          String value = param.substring(eqIndex + 1);
          params[key] = value;
        }
      }
    }

    String name = server;
    if (params.containsKey('remarks')) {
      name = _decodeBase64(params['remarks']!);
    }

    String protocolParam = '';
    if (params.containsKey('protoparam')) {
      protocolParam = _decodeBase64(params['protoparam']!);
    }

    String obfsParam = '';
    if (params.containsKey('obfsparam')) {
      obfsParam = _decodeBase64(params['obfsparam']!);
    }

    return {
      'name': name,
      'type': 'ssr',
      'server': server,
      'port': port,
      'cipher': method,
      'password': password,
      'protocol': protocol,
      'obfs': obfs,
      'protocol-param': protocolParam,
      'obfs-param': obfsParam,
      'udp': true,
    };
  }
}
