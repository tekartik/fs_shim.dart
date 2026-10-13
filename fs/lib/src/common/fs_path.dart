library;

/// True if the path [segments] start with all the segments of [prefix].
bool pathSegmentsStartWith(List<String> segments, List<String> prefix) {
  if (segments.length < prefix.length) {
    return false;
  }
  for (var i = 0; i < prefix.length; i++) {
    if (segments[i] != prefix[i]) {
      return false;
    }
  }
  return true;
}

/// True if the path [segments] and [other] are the same.
bool pathSegmentsEqual(List<String> segments, List<String> other) =>
    segments.length == other.length && pathSegmentsStartWith(segments, other);
