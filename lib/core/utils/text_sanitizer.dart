String cleanGarbledText(String? input) {
  if (input == null || input.isEmpty) return '';
  String text = input
      .replaceAll(RegExp(r'[ðâ][\u0080-\u00FF\uFFFD\u0100-\uFFFF]*'), '')
      .replaceAll(RegExp(r'[\uFFFD\uFFFE]'), '')
      .replaceAll('â€¢', '•')
      .replaceAll('â€”', '—')
      .replaceAll('â€“', '-')
      .replaceAll(RegExp(r'^\s*[:,-]\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text;
}
