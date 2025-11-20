import 'dart:convert';
import 'dart:io';
import 'dart:math';
//import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'protocols.dart';
import 'dns.dart';
import 'http_client.dart' as http_client;
import 'loginfo.dart';

class UrlConverter {
  // List to store logs
  final List<LogInfo> _logsList = [];
  bool _needResolveDns = false;
  String _dnsProvider = '';

  void _addLog(String log, LogLevel level) {
    _logsList.add(LogInfo(message: log, level: level));
  }

  void _clearLogs() {
    _logsList.clear();
  }

  set needResolveDns(bool value) {
    _needResolveDns = value;
  }

  set dnsProvider(String value) {
    _dnsProvider = value;
  }

  Future<List<LogInfo>> processSubscription(
    String scriptionUrl,
    String targetFolder,
    String template,
  ) async {
    try {
      // Clear logs
      _clearLogs();

      // Extract the filename from the URL
      String fileName = extractFileNameFromUrlEx(scriptionUrl);

      Uri uri = Uri.parse(scriptionUrl);
      String content = '';
      switch (uri.scheme) {
        case 'http':
        case 'https':
          // 1. Fetch the content from the URL
          /*
          final response = await http.get(Uri.parse(scriptionUrl));
          if (response.statusCode != 200) {
            throw Exception('Failed to load URL: ${response.statusCode}');
          }
          */
          content = await http_client.request(scriptionUrl);
          break;
        case 'ss':
        case 'vmess':
        case 'vless':
        case 'trojan':
        case 'hysteria2': // hysteria v2
          // Don't need to fetch the content
          content = scriptionUrl;
        default:
          throw Exception('Unsupported URL scheme: ${uri.scheme}');
      }

      _addLog('Start processing... [$scriptionUrl]', LogLevel.start);
      Map<String, dynamic> processedContent;
      // 2. Determine the format by examining the content
      if (ProxyUrl.checkBase64(content)) {
        // Decode first
        processedContent = await _processBase64Content(content);
      } else if (_isLineByLineText(content)) {
        // Line by line text to process
        processedContent = await _processLineByLineText(content);
      } else if (_isValidUrl(content)) {
        // Single url as one line to process
        processedContent = await _processLineByLineText(content);
      } else {
        // Try JSON or other formats
        throw Exception('Unsupported format');
      }

      // 3. Write the processed content to a file
      String filePath = await _getSavedFilePath(targetFolder, fileName);
      _addLog('Saved at: $filePath', LogLevel.file);
      // Don't need to await the save operation
      _saveToFile(processedContent, template, filePath);
      // Finish processing(even though it's async)
      _addLog('Finished. [$scriptionUrl]', LogLevel.success);
      return _logsList;
    } catch (e) {
      throw Exception('Error processing URL: $e');
    }
  }

  Future<String> _getSavedFilePath(String folder, String fileName) async {
    try {
      // Determine the base directory for resolving relative paths
      String resolvedBaseDir = Directory.current.path;

      // Resolve the folder path (handle relative paths)
      String absoluteFolderPath =
          path.isAbsolute(folder)
              ? folder
              : path.normalize(path.join(resolvedBaseDir, folder));

      // Create the directory if it doesn't exist
      Directory directory = Directory(absoluteFolderPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Construct the full file path
      String absoluteFilePath = path.normalize(
        path.join(absoluteFolderPath, fileName),
      );
      return absoluteFilePath;
    } catch (e) {
      // Handle exception
      throw Exception('Not a valid path to save file: $e');
    }
  }

  Future<void> _saveToFile(
    Map<String, dynamic> content,
    String template,
    String filePath,
  ) async {
    try {
      var yaml = loadYaml(template);
      // Convert YamlMap to regular Dart Map (to make it mutable)
      Map<String, dynamic> config = Map<String, dynamic>.from(yaml);

      // Ensure proxies is a list and make a copy we can modify
      config['proxies'] = List<dynamic>.from(content['proxies']);

      // Create a mutable copy of the proxy-groups list first
      config['proxy-groups'] = List<dynamic>.from(config['proxy-groups']);

      for (int i = 0; i < 2; i++) {
        // Create mutable copy of each group
        config['proxy-groups'][i] = Map<String, dynamic>.from(
          config['proxy-groups'][i],
        );

        // Check if proxies exists and initialize if needed
        if (!config['proxy-groups'][i].containsKey('proxies') ||
            config['proxy-groups'][i]['proxies'] == null) {
          config['proxy-groups'][i]['proxies'] = [];
        } else {
          // Make existing list mutable
          config['proxy-groups'][i]['proxies'] = List<dynamic>.from(
            config['proxy-groups'][i]['proxies'],
          );
        }

        // Now add the proxy names
        config['proxy-groups'][i]['proxies'].addAll(
          content['proxies'].map((proxy) => proxy['name']).toList(),
        );
      }
      // Write the content to the file
      final yamlWriter = YamlWriter();
      final yamlString = yamlWriter.write(config);
      //print(yamlString);
      await File(filePath).writeAsString(yamlString);
    } catch (e) {
      throw Exception('Error saving to file: $e');
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(
        length,
        (index) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  String? _getFileNameFromUrl(String url, {String defaultExtension = '.yaml'}) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // If path is empty or ends with a slash, it's not a file
      if (path.isEmpty || path.endsWith('/')) {
        return null;
      }

      // Get the last segment of the path
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) {
        return null;
      }

      final lastSegment = segments.last;

      // Check if the last segment has a dot and something after it (extension)
      final lastDotIndex = lastSegment.lastIndexOf('.');
      if (lastDotIndex > 0 && lastDotIndex < lastSegment.length - 1) {
        // Remove .suffix
        String fileName = lastSegment.split('.').first;
        fileName = '$fileName$defaultExtension';
        fileName = fileName.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
        return fileName;
      }

      return null;
    } catch (e) {
      // Handle invalid URLs
      return null;
    }
  }

  String extractFileNameFromUrlEx(
    String url, {
    String defaultExtension = '.yaml',
  }) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();

      // Rule 0: Check for key query parameters first (priority for URLs like example 4)
      if (uri.queryParameters.isNotEmpty) {
        final paramKeys = ['key', 'id', 'name', 'token'];
        for (final key in paramKeys) {
          if (uri.queryParameters.containsKey(key)) {
            final value = uri.queryParameters[key]!;
            if (value.isNotEmpty) {
              return _sanitizeFileName(value) + defaultExtension;
            }
          }
        }
      }

      // Rule 1: Special handling for GitHub/GitHubusercontent URLs
      if ((uri.host.contains('github') ||
              uri.host.contains('githubusercontent')) &&
          segments.length > 1) {
        final repoOwner = segments[0];
        final lastSegment = segments.last;
        final lastDotIndex = lastSegment.lastIndexOf('.');
        String filenameWithoutExtension = lastSegment;
        if (lastDotIndex > 0) {
          filenameWithoutExtension = lastSegment.substring(0, lastDotIndex);
        }
        return _sanitizeFileName('${repoOwner}_$filenameWithoutExtension') +
            defaultExtension;
      }

      // Rule 2: Check for filenames in the URL
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        final lastDotIndex = lastSegment.lastIndexOf('.');
        if (lastDotIndex > 0 && lastDotIndex < lastSegment.length - 1) {
          final filenameWithoutExtension = lastSegment.substring(
            0,
            lastDotIndex,
          );
          return _sanitizeFileName(filenameWithoutExtension) + defaultExtension;
        }
        final systemPaths = ['refs', 'heads', 'main', 'master'];
        if (!systemPaths.contains(lastSegment) && !lastSegment.endsWith('/')) {
          if (lastSegment.length > 2) {
            return _sanitizeFileName(lastSegment) + defaultExtension;
          }
        }
      }

      // Rule 3: Check for fragment identifiers
      if (uri.fragment.isNotEmpty) {
        return _sanitizeFileName(uri.fragment) + defaultExtension;
      }

      // Rule 4: Handle URLs with @ symbols
      if (url.contains('@')) {
        final uriParts = url.split('@');
        if (uriParts.length > 1) {
          final hostPart = uriParts[1].split('?').first.split('/').first;
          final host = hostPart.split(':').first;
          return _sanitizeFileName(host) + defaultExtension;
        }
      }

      // Rule 5: Fallback to domain
      if (uri.host.isNotEmpty) {
        final host = uri.host.split('.').first;
        return _sanitizeFileName(host) + defaultExtension;
      }

      // Final fallback
      return _generateRandomString(8) + defaultExtension;
    } catch (e) {
      return '${_generateRandomString(8)}$defaultExtension';
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  }

  // Check if content is line-by-line text format
  bool _isLineByLineText(String content) {
    final lines = content.split('\n');
    // If multiple lines and doesn't look binary
    return lines.length > 1 &&
        !content.contains(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'));
  }

  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Process base64 content
  Future<Map<String, dynamic>> _processBase64Content(String content) async {
    // Remove whitespace
    String trimmed = content.trim().replaceAll(RegExp(r'\s'), '');

    // Decode base64
    List<int> decoded = base64.decode(trimmed);
    String decodedText = utf8.decode(decoded);

    // Process the decoded text (implement your business logic here)
    Map<String, dynamic> processedText = await _processLineByLineText(
      decodedText,
    );

    return processedText;
  }

  // Process line-by-line text with proxy URLs
  // Process line-by-line text with proxy URLs - improved error handling
  Future<Map<String, dynamic>> _processLineByLineText(String content) async {
    List<String> lines = content.split('\n');
    List<Map<String, dynamic>> processedServers = [];
    int totalLines = 0;
    int processedLines = 0;
    int errorLines = 0;
    List<String> namesList = [];

    for (String line in lines) {
      // Skip empty lines and comments (lines starting with #)
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      totalLines++;
      try {
        Map<String, dynamic> serverConfig;

        line = _sanitizeUri(line);

        final parsedUrl = parseProxyUrl(line);
        if (parsedUrl == null) {
          continue;
        }
        String url = parsedUrl.toRevisedUrl();
        // vless, vmess, trojan, ss
        String protocol = parsedUrl.getCorrectProtocol();
        if (protocol == "ss") {
          serverConfig = _processSsUrl(url);
        } else if (protocol == "vmess") {
          serverConfig = _processVmessUrl(url);
        } else if (protocol == "vless") {
          serverConfig = _processVlessUrl(url);
        } else if (protocol == "trojan") {
          serverConfig = _processTrojanUrl(url);
        } else if (protocol == "hysteria2") {
          serverConfig = _processHysteria2Url(url);
        } else {
          _addLog('Not a supported protocol($protocol): $line', LogLevel.error);
          continue;
        }

        // Only add valid configs (those without errors)
        if (!serverConfig.containsKey('error')) {
          // Add a unique name to each server config
          // Keep track of unique names
          String name = serverConfig['name'];
          if (name.isEmpty) {
            // Generate a random name if the url didn't provide one
            // aka there is no '#'remarks in the url to provide a name
            name = _generateRandomString(8);
          }
          String uniqueName = name;
          final random = Random();
          while (namesList.contains(uniqueName)) {
            // If name exists, add a random number
            int randomNumber = random.nextInt(1000);
            uniqueName = '$name$randomNumber';
          }
          serverConfig['name'] = uniqueName;
          // Add the unique name to the list
          namesList.add(uniqueName);

          // Add the processed server config to the list
          processedServers.add(serverConfig);
          processedLines++;
        } else {
          errorLines++;
          _addLog(
            'Skipped line due to error: ${serverConfig['error']}',
            LogLevel.warning,
          );
        }
      } catch (e) {
        errorLines++;
        _addLog('Error processing line: $e', LogLevel.error);
        // Continue processing other lines
      }
    }

    _addLog(
      'Processed $processedLines/$totalLines lines with $errorLines errors',
      LogLevel.info,
    );

    // Format the processed servers into Clash configuration
    final yaml = await _formatToClashConfig(processedServers);
    return yaml;
  }

  String _sanitizeUri(String uri) {
    // Keep only valid URI characters
    // This includes alphanumeric, and special chars used in URIs
    return uri.replaceAll(
      RegExp(r"[^\w\-\.\~\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\%]"),
      '',
    );
  }

  /// Get the first non-empty value from a map of strings.
  String? _getFirstNonEmptyValue(
    Map<String, dynamic> params,
    List<String> keys, {
    String? defaultValue,
  }) {
    for (String key in keys) {
      if (params.containsKey(key)) {
        var value = params[key];

        // Handle different types properly
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is bool || value is num) {
          // Convert boolean or number to string
          return value.toString();
        } else if (value != null) {
          return value.toString();
        }
      }
    }
    return defaultValue;
  }

  bool _parseBooleanValue(dynamic value) {
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

  // Process SS URL (shadowsocks)
  // Legacy: ss://BASE64(method:password)@server:port#remark
  // SIP002: ss://BASE64(method:password@server:port)#remark
  // URL encoded: ss://method:password@server:port#remark
  /*
  Map<String, dynamic> _processSsUrl(String url) {
    try {
      if (!url.toLowerCase().startsWith('ss://')) {
        throw FormatException('URL scheme is not ss');
      }
      // Remove "ss://" prefix
      String content = url.substring(5);
      String name = '';
      // Extract the name if present (after #)
      if (content.contains('#')) {
        final parts = content.split('#');
        content = parts[0];
        name = Uri.decodeComponent(parts[1]);
      }

      Map<String, dynamic> serverInfo;
      if (ProxyUrl.checkBase64(content)) {
        // Fix padding issues in base64 string
        content = ProxyUrl.fixBase64Padding(content);
        String decodedContent;
        try {
          decodedContent = utf8.decode(base64.decode(content));
        } catch (e) {
          print('Failed to decode base64: $e');
          return {'type': 'ss', 'error': 'Invalid base64 encoding in SS URL'};
        }
        // Check whether it's a valid SS URL
        try {
          // Parse as JSON
          Map<String, dynamic> jsonConfig = jsonDecode(decodedContent);
          url = "vmess://" + url.substring(5);

          // This appears to be VMess data mistakenly labeled as SS
          return _processVmessUrl(url);
        } catch (jsonError) {
          // Not valid JSON, continue with regular SS parsing
        }

        // Expected format: method:password@server:port
        final atSplit = decodedContent.split('@');
        if (atSplit.length != 2) {
          throw FormatException(
            'Decoded SS URL does not contain "@" separator',
          );
        }
        final credentials = atSplit[0].split(':');
        if (credentials.length < 2) {
          throw FormatException('Invalid credentials format in SS URL');
        }
        final hostPort = atSplit[1].split(':');
        if (hostPort.length < 2) {
          throw FormatException('Invalid host:port format in SS URL');
        }
        serverInfo = {
          'type': 'ss',
          'name': name,
          'server': hostPort[0],
          'port': int.parse(hostPort[1]),
          'cipher': credentials[0],
          // In case the password contains colons, join remaining parts
          'password': credentials.sublist(1).join(':'),
        };
      } else {
        // First, check whether it's a valid Vless
        if (content.contains('@') && content.contains('type=')) {
          // This is likely a misidentified VLESS URL
          url = "vless://" + url.substring(5);
          return _processVlessUrl(url);
        }
        // Plain format: method:password@server:port
        final parts = content.split('@');
        if (parts.length != 2) {
          throw FormatException('SS URL format error, missing "@"');
        }

        // Decode the first part if it's base64
        String firstPart = parts[0];
        if (ProxyUrl.checkBase64(firstPart)) {
          // Fix padding issues in base64 string
          firstPart = ProxyUrl.fixBase64Padding(firstPart);
          String decoded;
          try {
            decoded = utf8.decode(base64.decode(firstPart));
          } catch (e) {
            print('Failed to decode base64 in SS credentials: $e');
            return {'type': 'ss', 'error': 'Invalid base64 encoding in SS URL'};
          }
          parts[0] = decoded;
        }

        List<String> credentials = parts[0].split(':');
        if (credentials.length < 2) {
          throw FormatException('Invalid credentials in SS URL');
        }
        final hostPort = parts[1].split(':');
        if (hostPort.length < 2) {
          throw FormatException('Invalid host:port in SS URL');
        }
        serverInfo = {
          'type': 'ss',
          'name': name,
          'server': hostPort[0],
          'port': int.parse(hostPort[1]),
          'cipher': credentials[0],
          'password': credentials.sublist(1).join(':'),
        };
      }
      // Check if the cipher is valid (only VMess and Shadowsocks (SS) explicitly contain cipher parameters)
      if (!ProxyUrl.isValidCipher(serverInfo['cipher'])) {
        return {
          'type': 'ss',
          'error': 'Invalid SS cipher method: ${serverInfo['cipher']}',
        };
      }

      return serverInfo;
    } catch (e) {
      print('Error processing SS URL: $e');
      return {'type': 'ss', 'error': 'Invalid SS URL format: $e'};
    }
  }
  */

  /// Process a Shadowsocks URL.(new version)
  static Map<String, dynamic> _processSsUrl(String url) {
    try {
      if (!url.startsWith('ss://')) {
        throw FormatException('Not a Shadowsocks URL');
      }

      String ssUrl = url;
      String remark = '';

      // Handle fragment (#remark)
      if (ssUrl.contains('#')) {
        final parts = ssUrl.split('#');
        ssUrl = parts[0];
        try {
          remark = Uri.decodeComponent(parts[1]);
        } catch (e) {
          remark = parts[1];
        }
      }

      Uri uri;
      String method = '';
      String password = '';

      // --- 1. Parse UserInfo (3 formats) ---
      if (!ssUrl.contains('@')) {
        // Format: ss://BASE64(...)
        final base64Part = ssUrl.substring(5);
        try {
          final decoded = utf8.decode(
            base64.decode(
              base64Part.padRight((base64Part.length + 3) & ~3, '='),
            ),
          );
          uri = Uri.parse('ss://$decoded');
          final userInfoParts = uri.userInfo.split(':');
          if (userInfoParts.length >= 2) {
            method = userInfoParts[0];
            password = userInfoParts.sublist(1).join(':');
          }
        } catch (e) {
          return {'type': 'ss', 'error': 'Invalid Base64 in SS URL'};
        }
      } else {
        uri = Uri.parse(ssUrl);
        final userInfoParts = uri.userInfo.split(':');
        if (userInfoParts.length >= 2) {
          // Format: ss://method:pass@server:port
          method = userInfoParts[0];
          password = userInfoParts.sublist(1).join(':');
        } else {
          // Format: ss://BASE64(method:pass)@server:port
          final userInfo = uri.userInfo;
          if (ProxyUrl.checkBase64(userInfo)) {
            try {
              final decoded = utf8.decode(
                base64.decode(
                  userInfo.padRight((userInfo.length + 3) & ~3, '='),
                ),
              );
              final parts = decoded.split(':');
              if (parts.length >= 2) {
                method = parts[0];
                password = parts.sublist(1).join(':');
              }
            } catch (e) {
              // Ignore decode errors, treat as raw
            }
          }
        }
      }

      // Normalize method
      method = method.toLowerCase();

      // --- 2. Validate Cipher Method (RESTORED) ---
      // This will now reject 'chacha20-poly1305' because it is not in your list
      if (!ProxyUrl.isValidCipher(method)) {
        return {
          'type': 'ss',
          'error': 'Unsupported or Legacy cipher detected: $method',
        };
      }

      // --- 3. Validate Key Length (SS-2022 Only) ---
      int? expectedKeyLength = ProxyUrl.getKeyLengthForCipher(method);

      if (method.startsWith('2022-blake3') && expectedKeyLength != null) {
        List<String> keysToCheck =
            password.contains(':') ? password.split(':') : [password];

        for (String keyStr in keysToCheck) {
          try {
            List<int> keyBytes = base64.decode(keyStr);
            if (keyBytes.length != expectedKeyLength) {
              return {
                'type': 'ss',
                'error':
                    'Key length mismatch for $method. Expected $expectedKeyLength bytes, but got ${keyBytes.length}.',
              };
            }
          } catch (e) {
            return {
              'type': 'ss',
              'error': 'Invalid Base64 key in SS-2022 config.',
            };
          }
        }
      }

      // --- 4. Handle Plugin (Fix for ": true") ---
      String plugin = '';
      Map<String, dynamic> pluginOpts = {};

      if (uri.queryParameters.containsKey('plugin')) {
        String pluginInfo = Uri.decodeComponent(uri.queryParameters['plugin']!);

        if (pluginInfo.contains(';')) {
          final pluginParts = pluginInfo.split(';');
          plugin = pluginParts[0];

          for (var opt in pluginParts.sublist(1)) {
            opt = opt.trim();
            if (opt.isEmpty) continue; // Skip empty options

            if (opt.contains('=')) {
              final keyValue = opt.split('=');
              if (keyValue.length == 2) {
                // For mihoyo
                // pluginOpts[keyValue[0]] = keyValue[1];

                String key = keyValue[0].toLowerCase();
                String val = keyValue[1];

                // --- TYPE CONVERSION FIX ---
                // Clash requires specific types for these keys:
                if (key == 'tls' || key == 'skip-cert-verify') {
                  pluginOpts[key] = val == 'true' || val == '1';
                } else if (key == 'mux') {
                  // URL uses mux=4 (int), but Clash Meta expects mux: boolean.
                  // Logic: If it's not "0" and not "false", it's True.
                  pluginOpts[key] =
                      (val != '0' && val != 'false' && val.isNotEmpty);
                } else if (key == 'port') {
                  // Some plugins might use port as Int
                  pluginOpts[key] = int.tryParse(val) ?? val;
                } else {
                  // Default to String
                  pluginOpts[key] = val;
                }
              }
            } else {
              pluginOpts[opt] = true;
            }
          }
        } else {
          plugin = pluginInfo;
        }
      }

      // --- 5. Return Final Map ---
      Map<String, dynamic> serverInfo = {
        'type': 'ss',
        'name': remark.isNotEmpty ? remark : uri.host,
        'server': uri.host,
        'port': uri.port,
        'password': password,
        'cipher': method,
        'udp': true,
        'tls': false,
      };

      if (plugin.isNotEmpty) {
        serverInfo['plugin'] = plugin;
        serverInfo['plugin-opts'] = pluginOpts;
      }

      return serverInfo;
    } catch (e) {
      return {'type': 'ss', 'error': 'Parse error: $e'};
    }
  }

  // Process VMess URL
  Map<String, dynamic> _processVmessUrl(String url) {
    // VMess format: vmess://BASE64(JSON)
    try {
      // Remove the "vmess://" prefix
      String content = url.substring(8);

      // Fix padding issues in base64 string
      content = ProxyUrl.fixBase64Padding(content);

      // Decode the base64 content
      String decodedContent;
      try {
        decodedContent = utf8.decode(base64.decode(content));
      } catch (e) {
        return {
          'type': 'vmess',
          'error': 'Invalid base64 encoding in VMess URL',
        };
      }

      // Parse the JSON content
      Map<String, dynamic> params;
      try {
        params = jsonDecode(decodedContent);
      } catch (e) {
        return {'type': 'vmess', 'error': 'Invalid JSON in VMess URL'};
      }

      // Check if the cipher is valid (only VMess and Shadowsocks (SS) explicitly contain cipher parameters)
      String cipher =
          _getFirstNonEmptyValue(params, [
            'security',
            'scy',
          ], defaultValue: 'auto')!;
      if (!ProxyUrl.isValidCipher(cipher)) {
        return {
          'type': 'vmess',
          'error': 'Invalid VMess cipher method: $cipher',
        };
      }

      // Initialize serverInfo with default values
      Map<String, dynamic> serverInfo = {
        'type': 'vmess',
        'name': params['ps'] ?? params['name'] ?? '',
        'server': params['add'] ?? '',
        'port': int.parse(params['port']?.toString() ?? '0'),
        'uuid': params['id'] ?? '',
        'alterId': int.parse(params['aid']?.toString() ?? '0'),
        'cipher': cipher,
      };

      /**
       * Security Part (including: security, servername, fingerprint, tls, skip-cert-verify)
       */
      final security = params['security'];
      if (security == 'reality') {
        final publicKey = _getFirstNonEmptyValue(params, [
          'pbk',
          'public-key',
        ], defaultValue: '');
        final shortId = _getFirstNonEmptyValue(params, [
          'sid',
          'short-id',
        ], defaultValue: '');
        // Check if the public key is valid
        bool valid = ProxyUrl.isValidPublicKey(publicKey);
        if (!valid) {
          return {
            'type': 'vmess',
            'error': 'Vmess security Invalidpublic key: $publicKey',
          };
        }
        serverInfo['reality-opts'] = {
          'public-key': publicKey,
          'short-id': shortId,
        };
      }
      // write servername
      final serverName = _getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'server-name',
        'spx',
      ], defaultValue: null);
      if (serverName != null) {
        serverInfo['servername'] = serverName;
        serverInfo['sni'] = serverName;
      }
      // write fingerprint
      final fingerPrint = _getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ], defaultValue: null);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      // write skip-cert-verify
      serverInfo['skip-cert-verify'] = _parseBooleanValue(
        _getFirstNonEmptyValue(params, [
          'skip-cert-verify',
          'allowInsecure',
        ], defaultValue: 'true'),
      );

      // write tls
      bool tlsEnabled = false;
      // Check explicit security parameter
      if (params.containsKey('security')) {
        String security = params['security']?.toLowerCase() ?? '';
        tlsEnabled = (security == 'tls' || security == 'reality');
      }
      // Or check for explicit tls parameter
      else if (params.containsKey('tls')) {
        tlsEnabled = _parseBooleanValue(params['tls']);
      }
      // For other protocols, common port conventions
      else if (serverInfo['port'] == 443) {
        tlsEnabled = true; // Usually TLS on port 443
      }
      serverInfo['tls'] = tlsEnabled;

      /**
       * Network Part (including: network, path, host, serviceName, udp)
       * Remember vmess type(http header) is not the same as vless type(which is actually network)
       */
      final network = _getFirstNonEmptyValue(params, [
        'network',
        'net',
      ], defaultValue: 'tcp');
      if (network == 'ws' || network == 'h2') {
        final path = _getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '');
        final host = _getFirstNonEmptyValue(params, [
          'host',
          'hostname',
          'hostname',
        ], defaultValue: '');
        if (network == 'ws') {
          serverInfo['ws-opts'] = {
            'path': path,
            'headers': {'host': host},
          };
        } else {
          if (path != null && path.isNotEmpty) {
            serverInfo['h2-opts'] = {'path': path, 'host': host};
          }
        }
      } else if (network == 'http') {
        final httpPath = _getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '/');
        final httpHost = _getFirstNonEmptyValue(params, [
          'host',
          'hostname',
        ], defaultValue: '');
        final httpMethod = _getFirstNonEmptyValue(params, [
          'method',
        ], defaultValue: 'GET');
        serverInfo['http-opts'] = {
          'method': httpMethod,
          'path': [httpPath],
          'headers': {
            'Host': [httpHost],
          },
        };
      } else if (network == 'grpc') {
        final serviceName = _getFirstNonEmptyValue(params, [
          'serviceName',
          'service-name',
          'grpc-service-name',
        ], defaultValue: '');
        serverInfo['grpc-opts'] = {'grpc-service-name': serviceName};
      } else if (network == 'tcp') {
        final headerType = _getFirstNonEmptyValue(params, [
          'type',
          'headerType',
        ], defaultValue: 'none');
        serverInfo['tcp-opts'] = {'type': headerType};
      }
      serverInfo['network'] = network ?? 'tcp';
      serverInfo['udp'] = _parseBooleanValue(params['udp']);

      /**
       * Other Part (including: ip-version, alpn)
       */
      serverInfo['ip-version'] = params['ip-version'] ?? '';
      serverInfo['flow'] = params['flow'] ?? '';
      // Handle ALPN from URI parameters
      if (params.containsKey('alpn')) {
        // If alpn comes as comma-separated string
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }
      return serverInfo;
    } catch (e) {
      rethrow;
    }
  }

  // Process VLESS URL: expects vless://uuid@server:port?encryption=none&type=tcp&security=tls#name
  Map<String, dynamic> _processVlessUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme.toLowerCase() != 'vless') {
        throw FormatException('URL scheme is not vless');
      }
      if (uri.userInfo.isEmpty) {
        throw FormatException('Missing UUID in vless URL');
      }
      final params = uri.queryParameters;

      // Initialize serverInfo with default values
      Map<String, dynamic> serverInfo = {
        'type': 'vless',
        'name': Uri.decodeComponent(uri.fragment),
        'server': uri.host,
        'port': uri.port,
        'uuid': Uri.decodeComponent(uri.userInfo),
      };

      /**
       * Security Part (including: security, servername, fingerprint, tls, skip-cert-verify)
       */
      final security = params['security'];
      if (security == 'reality') {
        final publicKey = _getFirstNonEmptyValue(params, [
          'pbk',
          'public-key',
        ], defaultValue: '');
        final shortId = _getFirstNonEmptyValue(params, [
          'sid',
          'short-id',
        ], defaultValue: '');
        // Check if the public key is valid
        bool valid = ProxyUrl.isValidPublicKey(publicKey);
        if (!valid) {
          return {
            'type': 'vless',
            'error': 'Vless security Invalidpublic key: $publicKey',
          };
        }
        serverInfo['reality-opts'] = {
          'public-key': publicKey,
          'short-id': shortId,
        };
      }
      // write servername
      final serverName = _getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'server-name',
        'spx',
      ], defaultValue: null);
      if (serverName != null) {
        serverInfo['servername'] = serverName;
        serverInfo['sni'] = serverName;
      }
      // write fingerprint
      final fingerPrint = _getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ], defaultValue: null);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      // write skip-cert-verify
      serverInfo['skip-cert-verify'] = _parseBooleanValue(
        _getFirstNonEmptyValue(params, [
          'skip-cert-verify',
          'allowInsecure',
        ], defaultValue: 'true'),
      );

      // write tls
      bool tlsEnabled = false;
      // Check explicit security parameter
      if (params.containsKey('security')) {
        String security = params['security']?.toLowerCase() ?? '';
        tlsEnabled = (security == 'tls' || security == 'reality');
      }
      // Or check for explicit tls parameter
      else if (params.containsKey('tls')) {
        tlsEnabled = _parseBooleanValue(params['tls']);
      }
      // For other protocols, common port conventions
      else if (uri.port == 443) {
        tlsEnabled = true; // Usually TLS on port 443
      }
      serverInfo['tls'] = tlsEnabled;

      /**
       * Network Part (including: network, path, host, serviceName, udp)
       */
      final network = _getFirstNonEmptyValue(params, [
        'network',
        'type',
        'net',
      ], defaultValue: 'tcp');
      if (network == 'ws' || network == 'h2') {
        final path = _getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '');
        final host = _getFirstNonEmptyValue(params, [
          'host',
          'hostname',
          'hostname',
        ], defaultValue: '');
        if (network == 'ws') {
          serverInfo['ws-opts'] = {
            'path': path,
            'headers': {'host': host},
          };
        } else {
          if (path != null && path.isNotEmpty) {
            serverInfo['h2-opts'] = {'path': path, 'host': host};
          }
        }
      } else if (network == 'http') {
        final httpPath = _getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '/');
        final httpHost = _getFirstNonEmptyValue(params, [
          'host',
          'hostname',
        ], defaultValue: '');
        final httpMethod = _getFirstNonEmptyValue(params, [
          'method',
        ], defaultValue: 'GET');
        serverInfo['http-opts'] = {
          'method': httpMethod,
          'path': [httpPath],
          'headers': {
            'Host': [httpHost],
          },
        };
      } else if (network == 'grpc') {
        final serviceName = _getFirstNonEmptyValue(params, [
          'serviceName',
          'service-name',
          'grpc-service-name',
        ], defaultValue: '');
        serverInfo['grpc-opts'] = {'grpc-service-name': serviceName};
      }
      serverInfo['network'] = network ?? 'tcp';
      serverInfo['udp'] = _parseBooleanValue(params['udp']);

      /**
       * Other Part (including: ip-version, alpn)
       */
      serverInfo['ip-version'] = params['ip-version'] ?? '';
      if (params['flow'] != null && params['flow'].toString().isNotEmpty) {
        final flow = params['flow'].toString();
        //Only Vless has flow
        //xtls: It stands for eXtra Transport Layer Security — Xray's custom TLS implementation that allows better performance and flexibility.
        //rprx: Stands for ReProxy, indicating the use of proxy-side TLS handling.
        if (flow.startsWith("xtls-rprx-")) {
          serverInfo['flow'] = flow;
        }
      }
      // Handle ALPN from URI parameters
      if (params.containsKey('alpn')) {
        // If alpn comes as comma-separated string
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }

      return serverInfo;
    } catch (e) {
      rethrow;
    }
  }

  // Process Trojan URL: expects trojan://password@server:port?…#name
  Map<String, dynamic> _processTrojanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme.toLowerCase() != 'trojan') {
        throw FormatException('URL scheme is not trojan');
      }
      if (uri.userInfo.isEmpty) {
        throw FormatException('Missing password in trojan URL');
      }
      final params = uri.queryParameters;
      // Initialize serverInfo with default values
      Map<String, dynamic> serverInfo = {
        'type': 'trojan',
        'name': Uri.decodeComponent(uri.fragment),
        'server': uri.host,
        'port': uri.port,
        'password': Uri.decodeComponent(uri.userInfo),
        'tls': true, // Trojan typically always uses TLS
      };

      /**
       * Security Part (including: security, servername, fingerprint, tls, skip-cert-verify)
       */
      final security = params['security'];
      if (security == 'reality') {
        final publicKey = _getFirstNonEmptyValue(params, [
          'pbk',
          'public-key',
        ], defaultValue: '');
        final shortId = _getFirstNonEmptyValue(params, [
          'sid',
          'short-id',
        ], defaultValue: '');
        // Check if the public key is valid
        bool valid = ProxyUrl.isValidPublicKey(publicKey);
        if (!valid) {
          return {
            'type': 'trojan',
            'error': 'Trojan security Invalidpublic key: $publicKey',
          };
        }
        serverInfo['reality-opts'] = {
          'public-key': publicKey,
          'short-id': shortId,
        };
      }
      // write servername
      final serverName = _getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'server-name',
        'spx',
      ], defaultValue: null);
      if (serverName != null) {
        serverInfo['servername'] = serverName;
        serverInfo['sni'] = serverName;
      }
      // write fingerprint
      final fingerPrint = _getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ], defaultValue: null);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      // write skip-cert-verify
      serverInfo['skip-cert-verify'] = _parseBooleanValue(
        _getFirstNonEmptyValue(params, [
          'skip-cert-verify',
          'allowInsecure',
        ], defaultValue: 'true'),
      );

      /**
       * Network Part (including: network, path, host, serviceName, udp)
       */
      final network = _getFirstNonEmptyValue(params, [
        'network',
        'type',
        'net',
      ], defaultValue: 'tcp');
      if (network == 'ws' || network == 'h2') {
        final path = _getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '');
        final host = _getFirstNonEmptyValue(params, [
          'host',
          'hostname',
          'hostname',
        ], defaultValue: '');
        if (network == 'ws') {
          serverInfo['ws-opts'] = {
            'path': path,
            'headers': {'host': host},
          };
        } else {
          if (path != null && path.isNotEmpty) {
            serverInfo['h2-opts'] = {'path': path, 'host': host};
          }
        }
      } else if (network == 'grpc') {
        final serviceName = _getFirstNonEmptyValue(params, [
          'serviceName',
          'service-name',
          'grpc-service-name',
        ], defaultValue: '');
        serverInfo['grpc-opts'] = {'grpc-service-name': serviceName};
      }
      serverInfo['network'] = network ?? 'tcp';
      serverInfo['udp'] = _parseBooleanValue(params['udp']);

      /**
       * Other Part (including: ip-version, alpn)
       */
      serverInfo['ip-version'] = params['ip-version'] ?? '';
      serverInfo['flow'] = params['flow'] ?? '';
      // Handle ALPN from URI parameters
      if (params.containsKey('alpn')) {
        // If alpn comes as comma-separated string
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }
      return serverInfo;
    } catch (e) {
      rethrow;
    }
  }

  // Process Hysteria v2 URL: hysteria2://password@server:port?parameters#name
  Map<String, dynamic> _processHysteria2Url(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme.toLowerCase() != 'hysteria2') {
        throw FormatException('URL scheme is not hysteria2');
      }
      if (uri.userInfo.isEmpty) {
        throw FormatException('Missing password in hysteria2 URL');
      }

      final params = uri.queryParameters;

      // Initialize serverInfo with default values
      Map<String, dynamic> serverInfo = {
        'type': 'hysteria2',
        'name':
            uri.fragment.isNotEmpty
                ? Uri.decodeComponent(uri.fragment)
                : uri.host,
        'server': uri.host,
        'port': uri.port,
        'password': Uri.decodeComponent(uri.userInfo),
      };

      /**
     * Security Part (including: sni, skip-cert-verify, fingerprint)
     */

      // SNI (Server Name Indication)
      final serverName = _getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'peer',
      ], defaultValue: null);
      if (serverName != null) {
        serverInfo['sni'] = serverName;
      }

      // Skip certificate verification
      final insecure = _getFirstNonEmptyValue(params, [
        'insecure',
        'skip-cert-verify',
        'allowInsecure',
      ], defaultValue: '0');
      serverInfo['skip-cert-verify'] = _parseBooleanValue(insecure);

      // Client fingerprint
      final fingerPrint = _getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ], defaultValue: null);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      /**
     * Obfuscation Part
     */
      final obfs = _getFirstNonEmptyValue(params, [
        'obfs',
        'obfsParam',
      ], defaultValue: null);
      if (obfs != null && obfs.isNotEmpty) {
        serverInfo['obfs'] = obfs;

        final obfsPassword = _getFirstNonEmptyValue(params, [
          'obfs-password',
          'obfsPassword',
        ], defaultValue: null);
        if (obfsPassword != null) {
          serverInfo['obfs-password'] = obfsPassword;
        }
      }

      /**
     * Network Part
     */

      // Multi-port support (mport parameter like "30000-60000")
      final mport = _getFirstNonEmptyValue(params, [
        'mport',
        'mports',
      ], defaultValue: null);
      if (mport != null && mport.isNotEmpty) {
        serverInfo['ports'] = mport;
      }

      // UDP support (Hysteria2 uses UDP by default)
      serverInfo['udp'] = true;

      /**
     * Additional Hysteria2 specific parameters
     */

      // Upload/Download bandwidth
      final up = _getFirstNonEmptyValue(params, [
        'up',
        'upmbps',
      ], defaultValue: null);
      if (up != null) {
        serverInfo['up'] = up;
      }

      final down = _getFirstNonEmptyValue(params, [
        'down',
        'downmbps',
      ], defaultValue: null);
      if (down != null) {
        serverInfo['down'] = down;
      }

      // ALPN
      if (params.containsKey('alpn')) {
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }

      // CA certificate
      final ca = _getFirstNonEmptyValue(params, [
        'ca',
        'ca-str',
      ], defaultValue: null);
      if (ca != null) {
        serverInfo['ca'] = ca;
      }

      // CA certificate path
      final caStr = _getFirstNonEmptyValue(params, [
        'ca-path',
      ], defaultValue: null);
      if (caStr != null) {
        serverInfo['ca-str'] = caStr;
      }

      return serverInfo;
    } catch (e) {
      return {
        'type': 'hysteria2',
        'error': 'Failed to parse Hysteria2 URL: $e',
      };
    }
  }

  // Format processed servers to Clash config
  Future<Map<String, dynamic>> _formatToClashConfig(
    List<Map<String, dynamic>> servers,
  ) async {
    // Create a basic Clash config template
    Map<String, dynamic> clashConfig = {'proxies': []};

    // Add each server to the proxies list
    for (var server in servers) {
      if (server.containsKey('error')) continue;

      if (_needResolveDns) {
        final hostname = server['server'];
        if (!isIpAddressFast(hostname)) {
          // If not IP address
          final ipAddresses = await getDnsIpAddresses(
            hostname,
            firstChoice: _dnsProvider,
          );
          if (ipAddresses.isNotEmpty) {
            server['server'] = ipAddresses.first;
          }
        }
      }

      Map<String, dynamic> proxyConfig = Map<String, dynamic>.fromEntries(
        server.entries.where((entry) => entry.value != ''),
      );

      clashConfig['proxies'].add(proxyConfig);
    }

    // Convert the config to YAML
    // This requires a YAML package - you'll need to add yaml: ^3.1.0 to pubspec.yaml
    // For now, just return JSON string
    return clashConfig;
  }
}
