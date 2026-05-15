import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String apkUrl;
  final String changelog;

  UpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.apkUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        latestVersion: json['latestVersion'] as String,
        latestBuildNumber: json['latestBuildNumber'] as int,
        apkUrl: json['apkUrl'] as String,
        changelog: json['changelog'] as String? ?? '',
      );
}

class UpdateService {
  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/shelad3/tournaments-app/main/version.json';

  Future<PackageInfo> _getPackageInfo() => PackageInfo.fromPlatform();

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(versionCheckUrl),
        headers: {'Cache-Control': 'no-cache'},
      );
      if (response.statusCode != 200) return null;

      final remote = UpdateInfo.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final local = await _getPackageInfo();
      final localBuild = int.tryParse(local.buildNumber) ?? 0;

      if (remote.latestBuildNumber > localBuild) return remote;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/update.apk');

      final response = await http.Client().send(
        http.Request('GET', Uri.parse(url)),
      );

      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? -1;
      int received = 0;

      final sink = file.openWrite(mode: FileMode.write);
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      }
      await sink.flush();
      await sink.close();

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }
}
