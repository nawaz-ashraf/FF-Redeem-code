// lib/core/utils/version_utils.dart
//
// Pure version comparison helpers used by the app-update flow.
// Avoids string comparison (e.g. "1.2.10" < "1.2.9" as strings) and
// does not require the pub_semver package.

class VersionUtils {
  VersionUtils._();

  /// Compare two semantic version strings segment by segment.
  ///
  /// Returns -1 if [a] < [b], 0 if equal, 1 if [a] > [b].
  ///
  /// Example: compareVersions('1.2.9', '1.2.10') → -1 (update available).
  static int compareVersions(String a, String b) {
    final segmentsA = _parseSegments(a);
    final segmentsB = _parseSegments(b);
    final maxLen = segmentsA.length > segmentsB.length
        ? segmentsA.length
        : segmentsB.length;

    for (var i = 0; i < maxLen; i++) {
      final segA = i < segmentsA.length ? segmentsA[i] : 0;
      final segB = i < segmentsB.length ? segmentsB[i] : 0;
      if (segA < segB) return -1;
      if (segA > segB) return 1;
    }
    return 0;
  }

  /// Returns true when [latest] is newer than [current].
  ///
  /// Used by [SettingsRepository.checkAppVersion] to decide whether
  /// to show the update dialog on splash.
  static bool isUpdateAvailable({
    required String current,
    required String latest,
  }) {
    return compareVersions(current, latest) < 0;
  }

  /// Normalizes a version string into numeric segments for comparison.
  ///
  /// Handles:
  /// - Leading "v" prefix (v1.0.0 → 1.0.0)
  /// - Build metadata after "+" (1.0.0+42 → 1.0.0)
  /// - Missing segments padded with 0 at compare time
  /// - Non-numeric segments treated as 0
  static List<int> _parseSegments(String version) {
    var v = version.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }

    // pubspec build number (e.g. 1.0.0+5) is not part of semver compare.
    final plusIndex = v.indexOf('+');
    if (plusIndex >= 0) {
      v = v.substring(0, plusIndex);
    }

    if (v.isEmpty) return [0];

    return v.split('.').map((segment) {
      return int.tryParse(segment.trim()) ?? 0;
    }).toList();
  }
}
