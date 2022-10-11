import "package:xml/xml.dart";

import "common.dart" as common;
import "context.dart";

String fetchCurrentBundleName(Context context, String manifestFileData) {
  final parsed = XmlDocument.parse(manifestFileData);

  final application = parsed.findAllElements("application").toList()[0];

  final List<String> label = application.attributes
      .where((attrib) => attrib.toString().contains("android:label"))
      .map((i) => i.toString())
      .toList();

  if (label.isEmpty) {
    throw Exception(
        "Could not find android:label in ${context.androidManifestPath}");
  }

  return label[0];
}

String replaceDeepLinkFilterData(
    Context context, String manifestFileData, Map<String, String?> filter) {
  final parsed = XmlDocument.parse(manifestFileData);

  final application = parsed.findAllElements("application").toList()[0];
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
  return parsed.toString();
}

String setNewBundleName(Context context, String manifestFileData,
    String currentBundleName, String desiredBundleName) {
  return manifestFileData.replaceAll(
      currentBundleName, 'android:label="${desiredBundleName}"');
}

void updateLauncherName(Context context) {
  final String manifestFileData = common.readFile(context.androidManifestPath);
  final String desiredBundleName = common.fetchLauncherName(context);
  final String currentBundleName =
      fetchCurrentBundleName(context, manifestFileData);
  String updatedManifestData = setNewBundleName(
      context, manifestFileData, currentBundleName, desiredBundleName);
  final desiredFilter = {
    "scheme": common.fetchDeepLinkScheme(context),
    "host": common.fetchDeepLinkHost(context),
    "pathPrefix": common.fetchDeepLinkPathPrefix(context),
    "pathPattern": common.fetchDeepLinkPathPattern(context),
    "port": common.fetchDeepLinkPort(context),
    "path": common.fetchDeepLinkPath(context),
    "mimeType": common.fetchDeepLinkMimeType(context)
  };
  updatedManifestData =
      replaceDeepLinkFilterData(context, updatedManifestData, desiredFilter);

  common.overwriteFile(context.androidManifestPath, updatedManifestData);
}
