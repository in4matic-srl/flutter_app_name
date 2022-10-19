import "package:xml/xml.dart";

import "common.dart" as common;
import "context.dart";

String replaceBundleName(
    Context context, String plistFileData, String desiredBundleName) {
  final parsed = XmlDocument.parse(plistFileData.trim());
  final dict = parsed.findElements("plist").first.findElements("dict").first;
  bool found = false;
  for (var element in dict.childElements) {
    if (element.name.toString() == "key" &&
        (element.text == "CFBundleName" ||
            element.text == "CFBundleDisplayName")) {
      element.nextElementSibling!.innerText = desiredBundleName;
      found = true;
    }
  }

  if (!found) {
    throw Exception("Bundle name not found in ${context.infoPlistPath}");
  }
  return common.format(parsed);
}

String replaceDeepLinkFilterData(
    Context context, String plistFileData, Map<String, String?> desiredFilter) {
  final parsed = XmlDocument.parse(plistFileData.trim());
  final dict = parsed.findElements("plist").first.findElements("dict").first;
  for (var element in dict.childElements) {
    if (element.name.toString() == "key" &&
        element.text == "CFBundleURLTypes") {
      final urlTypesArray = element.nextElementSibling;
      if (urlTypesArray!.childElements.isEmpty) {
        throw Exception(
            "CFBundleURLTypes is empty in ${context.infoPlistPath}");
      }
      if (urlTypesArray.childElements.length > 1) {
        throw Exception(
            "CFBundleURLTypes has more than one element in ${context.infoPlistPath}");
      }
      final urlTypeDict = urlTypesArray.childElements.first;
      for (var urlTypeDictElement in urlTypeDict.childElements) {
        if (desiredFilter["scheme"] != null &&
            urlTypeDictElement.name.toString() == "key" &&
            urlTypeDictElement.text == "CFBundleURLSchemes") {
          final urlSchemesArray = urlTypeDictElement.nextElementSibling;
          if (urlSchemesArray!.childElements.isEmpty) {
            throw Exception(
                "CFBundleURLSchemes is empty in ${context.infoPlistPath}");
          }
          if (urlSchemesArray.childElements.length > 1) {
            throw Exception(
                "CFBundleURLSchemes has more than one element in ${context.infoPlistPath}");
          }
          final urlScheme = urlSchemesArray.childElements.first;
          urlScheme.innerText = desiredFilter["scheme"]!;
        }
        if (desiredFilter["host"] != null &&
            urlTypeDictElement.name.toString() == "key" &&
            urlTypeDictElement.text == "CFBundleURLName") {
          final urlName = urlTypeDictElement.nextElementSibling;
          urlName!.innerText = desiredFilter["host"]!;
        }
      }
    }
  }
  return common.format(parsed);
}

void updateLauncherName(Context context) {
  String plist = common.readFile(context.infoPlistPath);
  final String desiredBundleName = common.fetchLauncherName(context);
  plist = replaceBundleName(context, plist, desiredBundleName);
  final desiredFilter = common.fetchDeepLinkFilter(context);
  plist = replaceDeepLinkFilterData(context, plist, desiredFilter);
  common.overwriteFile(context.infoPlistPath, plist);
}
