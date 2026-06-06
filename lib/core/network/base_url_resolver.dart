import '../constants/api_constants.dart';

/// Decides which API base URL to use, preferring the DNS endpoint and falling
/// back to the direct IP only when the DNS host can't be resolved/reached.
///
/// Behaviour:
///  * New requests use [activeUrl] — the primary (DNS) endpoint by default.
///  * When a request fails with a connection/DNS error, [ApiService] retries it
///    against the next [nextUntried] endpoint and calls [markActive] on success,
///    so subsequent requests skip the dead endpoint instead of timing out on it.
///  * After [_recheckPrimaryAfter] on a fallback endpoint, [activeUrl] reverts
///    to the primary so a recovered DNS host is picked up again.
class BaseUrlResolver {
  BaseUrlResolver._();

  static final BaseUrlResolver instance = BaseUrlResolver._();

  /// Endpoints in preference order (DNS first, IP fallback second).
  final List<String> urls = ApiConstants.baseUrls;

  /// How long to stay on a fallback endpoint before re-trying the primary.
  static const Duration _recheckPrimaryAfter = Duration(minutes: 5);

  int _activeIndex = 0;
  DateTime? _failedOverAt;

  /// The endpoint new requests should use right now.
  String get activeUrl {
    // If we've been on a fallback for a while, drop back to the primary so a
    // recovered DNS host is used again.
    if (_activeIndex != 0 &&
        _failedOverAt != null &&
        DateTime.now().difference(_failedOverAt!) > _recheckPrimaryAfter) {
      _activeIndex = 0;
      _failedOverAt = null;
    }
    return urls[_activeIndex];
  }

  /// The next endpoint not in [tried], or `null` when all have been tried.
  String? nextUntried(Set<String> tried) {
    for (final url in urls) {
      if (!tried.contains(url)) return url;
    }
    return null;
  }

  /// Record that [url] is the endpoint currently working, so future requests
  /// go straight to it.
  void markActive(String url) {
    final index = urls.indexOf(url);
    if (index == -1) return;
    _activeIndex = index;
    _failedOverAt = index == 0 ? null : (_failedOverAt ?? DateTime.now());
  }
}
