/// Centralized, swappable configuration for the on-device LLM model.
///
/// The model is NOT bundled in `assets/` (keeps APK < 100 MB). It is
/// downloaded at runtime to external app files. To swap the model
/// (e.g. Qwen2.5-1.5B -> Gemma 4 E2B), only the fields below need to
/// change — no inference or repository code changes required, because
/// both are `.litertlm` files consumed by the same LiteRT `Engine`.
class ModelDownloadConfig {
  const ModelDownloadConfig._();

  /// Direct download URL (Cloudflare R2, PennywiseAI pattern).
  static const String modelUrl =
      'https://pub-fcfb3ffddb184540a758a7fe68249908.r2.dev/models/v1/Qwen2.5-1.5B-Instruct-q8-ekv4096.litertlm';

  /// SHA-256 of the model file. Pinned for integrity verification.
  /// TODO: Replace with the real hash from Pennywise Constants.kt once available.
  /// While this placeholder is present, [ModelRepository.verifyModelIntegrity]
  /// accepts the download (dev mode) but still performs size/existence checks.
  static const String modelSha256 =
      'PLACEHOLDER_REPLACE_WITH_REAL_SHA256_QWEN2_5_1_5B_INSTRUCT';

  /// Storage guard: require at least 2x the model size before downloading
  /// (~1.5 GB model -> 3 GB free recommended).
  static const int requiredSpaceBytes = 3 * 1024 * 1024 * 1024;

  /// File name used on device (under `<externalFiles>/models/`).
  static const String modelFileName =
      'Qwen2.5-1.5B-Instruct-q8-ekv4096.litertlm';

  /// Human-readable name shown in the UI.
  static const String displayName = 'Qwen2.5-1.5B-Instruct (On-Device)';

  /// Approximate download size shown to the user.
  static const String displaySize = '~1.5 GB';
}
