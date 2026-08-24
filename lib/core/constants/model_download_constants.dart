/// Centralized, swappable configuration for the on-device LLM model.
///
/// The model is NOT bundled in `assets/` (keeps APK < 100 MB). It is
/// downloaded at runtime to external app files. To swap the model
/// (e.g. Qwen2.5-1.5B -> Gemma 4 E2B), only the fields below need to
/// change — no inference or repository code changes required, because
/// both are `.litertlm` files consumed by the same LiteRT `Engine`.
class ModelDownloadConfig {
  const ModelDownloadConfig._();

  /// Direct download URL — HuggingFace (free, no card) for Gemma 4 E2B.
  /// Swappable: change only this URL + Sha256 to swap model (Qwen ↔ Gemma).
  static const String modelUrl =
      'https://huggingface.co/soniqo/Gemma-4-E2B-LiteRT-LM/resolve/main/model.litertlm';

  /// SHA-256 of the model file. Pinned for integrity verification.
  /// TODO: Replace with real SHA-256 from HuggingFace Files → model.litertlm → copy SHA256.
  /// While placeholder is present, ModelRepository.verifyModelIntegrity accepts download in dev mode.
  static const String modelSha256 =
      'PLACEHOLDER_REPLACE_WITH_REAL_SHA256_GEMMA_4_E2B_LITERTLM';

  /// Storage guard: require at least 2x the model size before downloading
  /// (~2.39 GB model -> 5 GB free recommended).
  static const int requiredSpaceBytes = 5 * 1024 * 1024 * 1024;

  /// File name used on device (under `<externalFiles>/models/`).
  static const String modelFileName = 'gemma-4-e2b.litertlm';

  /// Human-readable name shown in the UI.
  static const String displayName = 'Gemma 4 E2B (On-Device)';

  /// Approximate download size shown to the user.
  static const String displaySize = '~2.39 GB';
}
