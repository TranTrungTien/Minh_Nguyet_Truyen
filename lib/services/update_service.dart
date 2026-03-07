import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateType { none, soft, force }

class UpdateInfo {
  final UpdateType type;
  final String currentVersion;
  final String? requiredVersion;
  final String? latestVersion;
  final String title;
  final String message;

  UpdateInfo({
    required this.type,
    required this.currentVersion,
    this.requiredVersion,
    this.latestVersion,
    required this.title,
    required this.message,
  });
}

class UpdateService {
  static final _remoteConfig = FirebaseRemoteConfig.instance;
  static const _ignoredSoftVersionKey = 'ignored_soft_version';

  static Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
  }

  static Future<UpdateInfo> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      await _remoteConfig.fetchAndActivate();

      final minRequired =
          _remoteConfig.getString('minimum_required_version').trim();
      final latest = _remoteConfig.getString('latest_version').trim();
      final compareMin = _compareVersions(currentVersion, minRequired);
      final compareLatest = _compareVersions(currentVersion, latest);
      if (compareMin < 0) {
        // Force update
        return UpdateInfo(
          type: UpdateType.force,
          currentVersion: currentVersion,
          requiredVersion: minRequired,
          title: _remoteConfig.getString('force_update_title'),
          message: _remoteConfig.getString('force_update_message'),
        );
      } else if (compareLatest < 0) {
        // Soft update
        final prefs = await SharedPreferences.getInstance();
        final ignoredVersion = prefs.getString(_ignoredSoftVersionKey) ?? '';
        if (ignoredVersion == latest) {
          return UpdateInfo(
            type: UpdateType.none,
            currentVersion: currentVersion,
            title: '',
            message: '',
          );
        }

        return UpdateInfo(
          type: UpdateType.soft,
          currentVersion: currentVersion,
          latestVersion: latest,
          title: _remoteConfig.getString('soft_update_title'),
          message: _remoteConfig.getString('soft_update_message'),
        );
      } else {
        return UpdateInfo(
          type: UpdateType.none,
          currentVersion: currentVersion,
          title: '',
          message: '',
        );
      }
    } catch (e) {
      return UpdateInfo(
          type: UpdateType.none,
          currentVersion: 'unknown',
          title: '',
          message: '');
    }
  }

  static Future<void> ignoreSoftUpdate(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredSoftVersionKey, version);
  }

  static int _compareVersions(String a, String b) {
    final List<int> partsA = a.split('.').map(int.parse).toList();
    final List<int> partsB = b.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final int partA = i < partsA.length ? partsA[i] : 0;
      final int partB = i < partsB.length ? partsB[i] : 0;
      if (partA < partB) return -1;
      if (partA > partB) return 1;
    }
    return 0;
  }

  static Future<void> launchStore() async {
    String urlString;
    if (Platform.isAndroid) {
      urlString = _remoteConfig.getString('store_url_android').trim();
      if (urlString.isEmpty) {
        urlString =
            'https://play.google.com/store/apps/details?id=com.minhnguyet.truyen';
      }
    } else {
      urlString = _remoteConfig.getString('store_url_ios').trim();
      if (urlString.isEmpty) return;
    }
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
