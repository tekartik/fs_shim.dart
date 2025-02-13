/// Debug only.
///
/// Warning this is mutable.
class AccessStatIdb {
  /// Read count
  int getCount = 0;

  /// Put count
  int putCount = 0;

  /// Clone current value.
  AccessStatIdb clone() =>
      AccessStatIdb()
        ..getCount = getCount
        ..putCount = putCount;

  @override
  String toString() => {'get': getCount, 'put': putCount}.toString();
}
