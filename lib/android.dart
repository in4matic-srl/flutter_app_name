import "package:xml/xml.dart";

import "common.dart" as common;
import "context.dart";

String replaceBundleName(
    Context context, String manifestFileData, String desiredBundleName) {
  final parsed = XmlDocument.parse(manifestFileData.trim());

  final application =
      parsed.findElements("manifest").first.findElements("application").first;
  var applicationLabel = application.attributes
      .where((attrib) => attrib.name.toString() == "android:label");
  if (applicationLabel.isEmpty) {
    throw Exception(
        "Could not find android:label in ${context.androidManifestPath}");
  }
  applicationLabel.first.value = desiredBundleName;
  return common.format(parsed);
}

String replaceDeepLinkFilterData(
    Context context, String manifestFileData, Map<String, String?> filter) {
  final parsed = XmlDocument.parse(manifestFileData.trim());

  final application =
      parsed.findElements("manifest").first.findElements("application").first;
  final intentFilters = application.findAllElements("intent-filter").toList();
  final deepLinkFilters = intentFilters.where((intentFilter) => intentFilter
      .findAllElements("action")
      .where((action) => action.attributes
          .where((attrib) =>
              attrib.name.toString() == "android:name" &&
              attrib.value == "android.intent.action.VIEW")
          .isNotEmpty)
      .isNotEmpty);
  if (deepLinkFilters.isEmpty) {
    throw Exception(
        "Could not find deep-link intent-filter in ${context.androidManifestPath}");
  }
  if (deepLinkFilters.length > 1) {
    throw Exception(
        "Found more than one deep-link intent-filter in ${context.androidManifestPath}");
  }
  var deepLinkFilterData = deepLinkFilters.first.findAllElements("data");
  if (deepLinkFilterData.isEmpty) {
    throw Exception(
        "Could not find deep-link data in ${context.androidManifestPath}");
  }

  for (var newAttr in filter.entries.where((x) => x.value != null)) {
    try {
      deepLinkFilterData.first.attributes
          .where((attr) => attr.name.toString() == "android:${newAttr.key}")
          .first
          .value = newAttr.value!;
    } catch (_) {
      throw Exception(
          "Could not find deep-link data attribute android:${newAttr.key} in ${context.androidManifestPath}");
    }
  }
  return common.format(parsed);
}

void updateLauncherName(Context context) {
  String manifest = common.readFile(context.androidManifestPath);
  final String desiredBundleName = common.fetchLauncherName(context);
  manifest = replaceBundleName(context, manifest, desiredBundleName);
  final desiredFilter = common.fetchDeepLinkFilter(context);
  manifest = replaceDeepLinkFilterData(context, manifest, desiredFilter);
  common.overwriteFile(context.androidManifestPath, manifest);
}
