import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';

/// Drop-in text widget that applies the centralized RU/KK catalogue to
/// literal and rich text. Dynamic server content is left unchanged.
class LocalizedText extends StatelessWidget {
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
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const LocalizedText.rich(
    this.textSpan, {
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
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  static const Map<String, String> _kkCompatibilityCatalogue = {
    // Compatibility entries for the fixed-city delivery-address flow. Keep
    // this tiny: the main source of translations remains AppStrings. These
    // entries can be removed once the generated/central catalogue contains
    // the same keys.
    'Город': 'Қала',
    'Укажите улицу и дом': 'Көше мен үй нөмірін көрсетіңіз',
    'Адрес слишком длинный': 'Мекенжай тым ұзын',
    'Доставка пока доступна только в Щучинске':
        'Жеткізу әзірге тек Щучинск қаласында қолжетімді',
  };

  String _translate(
    String source,
    String Function(String) catalogueTranslate,
    AppLanguage language,
  ) {
    final translated = catalogueTranslate(source);
    if (language != AppLanguage.kk || translated != source) {
      return translated;
    }

    return _kkCompatibilityCatalogue[source] ?? source;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppLocalizationScope.of(context);
    final strings = scope.strings;
    final source = data;
    String translate(String value) =>
        _translate(value, strings.localize, scope.language);

    if (source != null) {
      return Text(
        translate(source),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel:
            semanticsLabel == null ? null : translate(semanticsLabel!),
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return Text.rich(
      _localizeSpan(textSpan!, translate),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel:
          semanticsLabel == null ? null : translate(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  InlineSpan _localizeSpan(
    InlineSpan span,
    String Function(String) translate,
  ) {
    if (span is WidgetSpan) return span;
    if (span is! TextSpan) return span;

    return TextSpan(
      text: span.text == null ? null : translate(span.text!),
      children: span.children
          ?.map((child) => _localizeSpan(child, translate))
          .toList(growable: false),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}
