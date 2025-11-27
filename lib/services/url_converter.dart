import 'dart:convert';
import 'dart:io';
import 'dart:math';
//import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'protocols/protocol_manager.dart';
import 'protocols/proxy_url.dart';
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

      // Check if this is a local file path
      bool isLocalFile =
          scriptionUrl.trim().startsWith('/') ||
          (scriptionUrl.trim().length >= 3 && scriptionUrl.trim()[1] == ':');

      String content = '';

      if (isLocalFile) {
        // Handle local file path
        try {
          final file = File(scriptionUrl.trim());
          if (await file.exists()) {
            content = await file.readAsString();
            fileName = path.basename(scriptionUrl.trim());
          } else {
            throw Exception('File not found: $scriptionUrl');
          }
        } catch (e) {
          throw Exception('Error reading local file: $e');
        }
      } else {
        // Handle URLs
        Uri uri = Uri.parse(scriptionUrl);
        switch (uri.scheme) {
          case 'http':
          case 'https':
            content = await http_client.request(scriptionUrl);
            break;
          case 'ss':
          case 'ssr':
          case 'vmess':
          case 'vless':
          case 'trojan':
          case 'hysteria2': // hysteria v2
          case 'hy2': // short alias for hysteria2
            // Don't need to fetch the content
            content = scriptionUrl;
          default:
            throw Exception('Unsupported URL scheme: ${uri.scheme}');
        }
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
        Map<String, dynamic> serverConfig = ProtocolManager.parse(line);

        // Only add valid configs (those without errors)
        if (!serverConfig.containsKey('error')) {
          // Add a unique name to each server config
          // Keep track of unique names
          String name = serverConfig['name'];
          if (name.isEmpty) {
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

    return clashConfig;
  }
}
