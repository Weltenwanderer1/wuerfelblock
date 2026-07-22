import 'package:flutter/material.dart' as material;

import 'app_localizations.dart';
import 'translations.g.dart';

String localizeText(material.BuildContext context, String source) {
  final appLocale = material.Localizations.of<AppLocalizations>(
    context,
    AppLocalizations,
  );
  if (appLocale?.localeName != 'en') {
    return source;
  }
  final exact = englishCatalog[source];
  if (exact != null) return exact;

  for (final template in _templateEntries) {
    final translated = template.translate(source);
    if (translated != null) return translated;
  }

  var translated = source;
  for (final entry in _longEntries) {
    if (translated.contains(entry.key)) {
      translated = translated.replaceAll(entry.key, entry.value);
    }
  }
  return translated;
}

final _placeholderPattern = RegExp(r'\$\{[^}]+\}|\$[A-Za-z_]\w*');

final List<_TemplateTranslation> _templateEntries =
    englishCatalog.entries
        .where((entry) => _placeholderPattern.hasMatch(entry.key))
        .map(_TemplateTranslation.new)
        .where((entry) => entry.literalLength >= 3)
        .toList()
      ..sort((a, b) => b.literalLength.compareTo(a.literalLength));

class _TemplateTranslation {
  _TemplateTranslation(MapEntry<String, String> entry)
    : target = entry.value,
      placeholders = _placeholderPattern
          .allMatches(entry.key)
          .map((match) => match.group(0)!)
          .toList(),
      literalLength = entry.key.replaceAll(_placeholderPattern, '').length,
      pattern = RegExp('^${_patternSource(entry.key)}\$', dotAll: true);

  final String target;
  final List<String> placeholders;
  final int literalLength;
  final RegExp pattern;

  static String _patternSource(String source) {
    final buffer = StringBuffer();
    var offset = 0;
    for (final match in _placeholderPattern.allMatches(source)) {
      buffer.write(RegExp.escape(source.substring(offset, match.start)));
      buffer.write('(.*?)');
      offset = match.end;
    }
    buffer.write(RegExp.escape(source.substring(offset)));
    return buffer.toString();
  }

  String? translate(String source) {
    final match = pattern.firstMatch(source);
    if (match == null) return null;
    var result = target;
    for (var index = 0; index < placeholders.length; index++) {
      final placeholder = placeholders[index];
      final captured = match.group(index + 1)!;
      final translatedCapture = placeholder.toLowerCase().contains('name')
          ? captured
          : englishCatalog[captured] ?? captured;
      result = result.replaceAll(placeholder, translatedCapture);
    }
    return result;
  }
}

final List<MapEntry<String, String>> _longEntries =
    englishCatalog.entries
        .where((entry) => entry.key.length >= 12 && !entry.key.contains(r'$'))
        .toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

class LocalizedText extends material.StatelessWidget {
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) => material.Text(
    localizeText(context, data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null
        ? null
        : localizeText(context, semanticsLabel!),
    semanticsIdentifier: semanticsIdentifier,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
