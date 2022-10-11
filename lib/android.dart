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

String fetchCurrentDeepLinkFilterData(
    Context context, String manifestFileData) {
  final parsed = XmlDocument.parse(manifestFileData);

  final application = parsed.findAllElements("application").toList()[0];
  final intentFilters = application.findAllElements("intent-filter").toList();
  final deepLinkFilters = intentFilters.where((intentFilter) => intentFilter
      .findAllElements("action")
      .where((action) => action.attributes
          .where((attrib) =>
              attrib.toString() == "android:name" && attrib.value == "VIEW")
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
  return deepLinkFilterData.toString();
}

String setNewBundleName(Context context, String manifestFileData,
    String currentBundleName, String desiredBundleName) {
  return manifestFileData.replaceAll(
      currentBundleName, 'android:label="${desiredBundleName}"');
}

String setNewDeepLinkFilterData(
    Context context,
    String updatedManifestData,
    String currentDeepLinkFilter,
    String? desiredDeepLinkScheme,
    String? desiredDeepLinkHost) {
  String updatedDeepLinkFilter = currentDeepLinkFilter;
  if (desiredDeepLinkScheme != null) {
    updatedDeepLinkFilter = updatedDeepLinkFilter.replaceAll(
        RegExp(r'android:scheme=".*?"'),
        'android:scheme="$desiredDeepLinkScheme"');
  }
  if (desiredDeepLinkHost != null) {
    updatedDeepLinkFilter = updatedDeepLinkFilter.replaceAll(
        RegExp(r'android:host=".*?"'), 'android:host="$desiredDeepLinkHost"');
  }
  return updatedManifestData.replaceAll(
      currentDeepLinkFilter, updatedDeepLinkFilter);
}

void updateLauncherName(Context context) {
  final String manifestFileData = common.readFile(context.androidManifestPath);
  final String desiredBundleName = common.fetchLauncherName(context);
  final String currentBundleName =
      fetchCurrentBundleName(context, manifestFileData);
  String updatedManifestData = setNewBundleName(
      context, manifestFileData, currentBundleName, desiredBundleName);
  final String? desiredDeepLinkScheme = common.fetchDeepLinkScheme(context);
  final String? desiredDeepLinkHost = common.fetchDeepLinkHost(context);
  final String currentDeepLinkFilter =
      fetchCurrentDeepLinkFilterData(context, manifestFileData);
  updatedManifestData = setNewDeepLinkFilterData(context, updatedManifestData,
      currentDeepLinkFilter, desiredDeepLinkScheme, desiredDeepLinkHost);

  common.overwriteFile(context.androidManifestPath, updatedManifestData);
}
