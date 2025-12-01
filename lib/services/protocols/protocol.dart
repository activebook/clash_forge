import 'proxy_url.dart';

abstract class Protocol {
  String get name;

  /// Returns true if this protocol handler can handle the given URL or ProxyUrl.
  bool canHandle(String url, ProxyUrl? parsed);

  /// Parse the URL and return the Clash proxy configuration map.
  /// Throws FormatException or ArgumentError if parsing fails.
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed});
}
