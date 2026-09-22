import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/shared/theme.dart';

/// Standard WCAG 2.1 relative luminance calculation
double _calculateRelativeLuminance(Color color) {
  double transformChannel(double c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transformChannel(color.red / 255.0);
  final g = transformChannel(color.green / 255.0);
  final b = transformChannel(color.blue / 255.0);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Standard WCAG 2.1 contrast ratio calculation: (L1 + 0.05) / (L2 + 0.05)
double calculateContrastRatio(Color color1, Color color2) {
  final l1 = _calculateRelativeLuminance(color1);
  final l2 = _calculateRelativeLuminance(color2);

  final lighter = max(l1, l2);
  final darker = min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.1 Accessibility & Color Contrast Tests', () {
    test('Primary body text on background satisfies WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(AppTheme.text, AppTheme.background);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Primary text on background ratio is ${ratio.toStringAsFixed(2)}:1');
    });

    test('Primary body text on surface satisfies WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(AppTheme.text, AppTheme.surface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Primary text on surface ratio is ${ratio.toStringAsFixed(2)}:1');
    });

    test('White text over ProviderDetail header dark overlay satisfies WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(Colors.white, AppTheme.headerOverlayColor);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'White text on header dark overlay ratio is ${ratio.toStringAsFixed(2)}:1');
    });

    test('Success state text on success background satisfies WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(AppTheme.success, AppTheme.successBg);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Success text on success background ratio is ${ratio.toStringAsFixed(2)}:1');
    });

    test('Error state text on error background satisfies WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(AppTheme.error, AppTheme.errorBg);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Error text on error background ratio is ${ratio.toStringAsFixed(2)}:1');
    });

    test('Warning state text on warning background satisfies comfortable margin (>= 4.8:1)', () {
      final ratio = calculateContrastRatio(AppTheme.warning, AppTheme.warningBg);
      expect(ratio, greaterThanOrEqualTo(4.8),
          reason: 'Warning text on warning background ratio is ${ratio.toStringAsFixed(2)}:1');
    });
  });
}
