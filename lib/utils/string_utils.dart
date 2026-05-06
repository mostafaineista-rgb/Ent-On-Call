class StringUtils {
  /// Strips the Arabic doctor prefix "د." or "د " from a name.
  static String stripDrPrefix(String name) {
    if (name.isEmpty) return name;
    
    // Regular expression to match "د." or "د" at the beginning, 
    // optionally followed by a dot and/or space.
    // Handles: "د. احمد", "د احمد", "د.احمد"
    final regExp = RegExp(r'^(د\.?|د)\s*', caseSensitive: false);
    
    return name.replaceFirst(regExp, '').trim();
  }

  /// Normalizes a name for comparison during login.
  static String normalizeName(String name) {
    return stripDrPrefix(name.trim()).toLowerCase();
  }
}
