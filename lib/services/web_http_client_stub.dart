/// Stub for non-web platforms. This file is never actually used at runtime
/// on native platforms, but it must exist to satisfy the conditional import.
library;

Future<String> webFetchGet(String url, {String? userAgent}) {
  throw UnsupportedError('webFetchGet is only available on web.');
}

Future<String> webFetchPost(String url, Map<String, String> formData, {String? userAgent}) {
  throw UnsupportedError('webFetchPost is only available on web.');
}
