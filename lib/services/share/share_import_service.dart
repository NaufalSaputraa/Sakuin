import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/utils/result.dart';

/// Share Import: receives plain text shared into Sakuin from other apps
/// (banking / e-wallet such as BCA, GoPay, OVO, Dana).
///
/// Wraps the `receive_sharing_intent` plugin:
/// - [getInitialSharedText] covers **cold start** (app launched by a
///   SHARE intent while it was closed).
/// - [watchSharedText] covers **warm start** (share received while the
///   app is alive in background / foreground).
/// - [reset] clears the stored native intent once it has been handled so
///   it is not re-delivered on the next launch.
///
/// All public members return structured types ([String] / [Result]),
/// never raw maps (AGENTS.md rule).
class ShareImportService {
  /// Cold start: returns the text shared into Sakuin when it was launched,
  /// or `null` when this was a normal launch without a SHARE intent.
  ///
  /// Expected platform/plugin failures are wrapped in [Failure] with
  /// [ParseError]; unexpected errors rethrow (bug).
  Future<Result<String?, AppError>> getInitialSharedText() async {
    try {
      final media = await ReceiveSharingIntent.instance.getInitialMedia();
      return Success(_extractText(media));
    } on Exception catch (e) {
      debugPrint('[ShareImportService] getInitialMedia failed: $e');
      return const Failure(ParseError('Failed to read shared intent'));
    }
  }

  /// Warm start: stream of texts shared while the app is running.
  /// Empty payloads (media-only shares) are filtered out.
  Stream<String> watchSharedText() {
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(_extractText)
        .where((text) => text.isNotEmpty);
  }

  /// Clears the stored share intent after it has been handled.
  void reset() {
    try {
      ReceiveSharingIntent.instance.reset();
    } on Exception catch (e) {
      debugPrint('[ShareImportService] reset failed: $e');
    }
  }

  /// Converts a [SharedMediaFile] list into a single trimmed text payload.
  ///
  /// Note (plugin >=1.9.0): shared plain text is delivered inside
  /// [SharedMediaFile.path] with [SharedMediaType.text] — there is no
  /// dedicated `.text` field anymore. Returns an empty string when the
  /// share contains no usable text.
  String _extractText(List<SharedMediaFile> media) {
    for (final file in media) {
      if (file.type != SharedMediaType.text) continue;
      final text = file.path.trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

final shareImportServiceProvider = Provider<ShareImportService>((ref) {
  return ShareImportService();
});
