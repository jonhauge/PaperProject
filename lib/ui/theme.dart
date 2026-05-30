import 'package:flutter/material.dart';

import '../models/enums.dart';

/// App-wide theme. A calm, paper-like palette suited to long reading/writing
/// sessions on both mobile and web.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3A5A82),
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F6F2),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}

/// Visual styling for a paper status chip.
Color statusColor(PaperStatus status, ColorScheme scheme) {
  switch (status) {
    case PaperStatus.draft:
      return scheme.outline;
    case PaperStatus.submitted:
    case PaperStatus.resubmitted:
      return Colors.indigo;
    case PaperStatus.underReview:
      return Colors.orange.shade800;
    case PaperStatus.revisionRequested:
      return Colors.deepOrange;
    case PaperStatus.accepted:
      return Colors.green.shade700;
    case PaperStatus.rejected:
      return Colors.red.shade700;
  }
}
