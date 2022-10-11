import "dart:io";

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
