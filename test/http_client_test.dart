import 'package:flutter/material.dart';
import 'package:clash_forge/services/http_client.dart' as http_client;

/// This test cannot solely execute
/// because it needs swift code
/// so i must build first to run
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String body = '';
  try {
    body = await http_client.request('https://www.google.com');
    if (!body.isEmpty) {
      print("Body length: ${body.length}");
    } else {
      print("No connection!");
    }
  } catch (e) {
    print("Cannot connect: $e");
  }
}
