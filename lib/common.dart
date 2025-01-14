import "dart:io";

import 'package:xml/xml.dart';
import "package:yaml/yaml.dart";

import "context.dart";

String readFile(String filePath) {
  final File fileObj = File(filePath);
  return fileObj.readAsStringSync();
}

void overwriteFile(String filePath, String fileData) {
  final File fileObj = File(filePath);
  fileObj.writeAsString(fileData);
}

Map readYamlFile(String yamlFilePath) {
  final File yamlFile = File(yamlFilePath);
  final Map yamlData = loadYaml(yamlFile.readAsStringSync());

  return yamlData;
}

Map? _yamlKeyData; // cached

Map getYamlKeyData(Context context) {
  if (_yamlKeyData == null) {
    final String yamlFilePath = context.pubspecPath;
    final String yamlKeyName = context.yamlKeyName;

    final Map yamlData = readYamlFile(yamlFilePath);
    _yamlKeyData = yamlData[yamlKeyName];

    if (_yamlKeyData == null) {
      throw Exception(
          "Your pubspec.yaml file must have a key ${yamlKeyName} in it.");
    }
  }
  return _yamlKeyData!;
}

void cleanCache() {
  _yamlKeyData = null;
}

String fetchLauncherName(Context context) {
  final String? launcherName = getYamlKeyData(context)["name"];
  if (launcherName == null) {
    throw Exception(
        "You must set the launcher name under the '${context.yamlKeyName}' section of your pubspec.yaml file.");
  }
  return launcherName;
}

String? fetchId(Context context) {
  return getYamlKeyData(context)["id"];
}

String? fetchDeepLinkScheme(Context context) {
  return getYamlKeyData(context)["deep_link_scheme"];
}

String? fetchDeepLinkHost(Context context) {
  return getYamlKeyData(context)["deep_link_host"] ?? fetchId(context);
}

String? fetchDeepLinkPath(Context context) {
  return getYamlKeyData(context)["deep_link_path"];
}

String? fetchDeepLinkPathPattern(Context context) {
  return getYamlKeyData(context)["deep_link_path_pattern"];
}

String? fetchDeepLinkPathPrefix(Context context) {
  return getYamlKeyData(context)["deep_link_path_prefix"];
}

String? fetchDeepLinkPort(Context context) {
  return getYamlKeyData(context)["deep_link_port"];
}

String? fetchDeepLinkMimeType(Context context) {
  return getYamlKeyData(context)["deep_link_mime_type"];
}

Map<String, String?> fetchDeepLinkFilter(Context context) {
  return {
    "scheme": fetchDeepLinkScheme(context),
    "host": fetchDeepLinkHost(context),
    "pathPrefix": fetchDeepLinkPathPrefix(context),
    "pathPattern": fetchDeepLinkPathPattern(context),
    "port": fetchDeepLinkPort(context),
    "path": fetchDeepLinkPath(context),
    "mimeType": fetchDeepLinkMimeType(context),
  };
}

String format(XmlDocument xmlDocument) =>
    xmlDocument.toXmlString(pretty: true, indent: "  ");
