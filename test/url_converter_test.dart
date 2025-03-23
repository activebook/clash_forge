import 'package:clash_forge/services/loginfo.dart';
import 'package:clash_forge/services/url_converter.dart';
import 'dart:io';

void test() async {
  
  //String scriptionUrl = 'https://raw.githubusercontent.com/barry-far/V2ray-Configs/main/Sub4.txt';
  //String scriptionUrl = 'ss://cmM0LW1kNTplZmFuY2N5dW4@cn01.efan8867801.xyz:8773/?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3D202503170996717-MVQjjXvt4R.download.microsoft.com#%F0%9F%87%BA%F0%9F%87%B8%20%E7%BE%8E%E5%9B%BD2%7C%40ripaojiedian';
  String scriptionUrl = 'https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/sub.txt';
  String targetFolder = '/Users/mac/.config/clash.meta/';
  String templatePath = './config/template.yaml';
  final file = File(templatePath);
  
  try {
    final template = file.readAsStringSync();
    var converter = UrlConverter();
    converter.needResolveDns = false;
    List<LogInfo> logs = await converter.processSubscription(scriptionUrl, targetFolder, template);
    for (var log in logs) {
      print(log);
    }
  } catch (e) {
    print('Error: $e');
  }
}

void main() {
  test();
}