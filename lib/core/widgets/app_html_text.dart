import 'package:flutter/material.dart';

/// Lightweight HTML renderer for work-report content (`p`, `strong`, `em`, lists, `br`).
class AppHtmlText extends StatelessWidget {
  const AppHtmlText(this.html, {super.key, this.style});

  final String html;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final blocks = _parseBlocks(html);
    if (blocks.isEmpty) {
      return Text(html.trim().isEmpty ? 'No content' : _stripTags(html), style: base);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          blocks[i].build(context, base),
        ],
      ],
    );
  }

  static String _stripTags(String s) => s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();

  static List<_HtmlBlock> _parseBlocks(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final blocks = <_HtmlBlock>[];

    final tagRe = RegExp(r'<(p|ul|ol)(\s[^>]*)?>', caseSensitive: false);
    var index = 0;
    while (index < cleaned.length) {
      final match = tagRe.firstMatch(cleaned.substring(index));
      if (match == null) {
        final rest = cleaned.substring(index).trim();
        if (rest.isNotEmpty) blocks.add(_ParagraphBlock(rest));
        break;
      }
      final absStart = index + match.start;
      if (absStart > index) {
        final before = cleaned.substring(index, absStart).trim();
        if (before.isNotEmpty) blocks.add(_ParagraphBlock(before));
      }

      final tag = match.group(1)!.toLowerCase();
      final openEnd = index + match.end;
      final close = RegExp('</$tag>', caseSensitive: false).firstMatch(cleaned.substring(openEnd));
      if (close == null) {
        blocks.add(_ParagraphBlock(cleaned.substring(absStart)));
        break;
      }
      final inner = cleaned.substring(openEnd, openEnd + close.start);
      if (tag == 'ul' || tag == 'ol') {
        final items = RegExp(r'<li(\s[^>]*)?>(.*?)</li>', caseSensitive: false, dotAll: true)
            .allMatches(inner)
            .map((m) => m.group(2) ?? '')
            .toList();
        blocks.add(_ListBlock(items: items, ordered: tag == 'ol'));
      } else {
        blocks.add(_ParagraphBlock(inner));
      }
      index = openEnd + close.end;
    }
    return blocks;
  }
}

abstract class _HtmlBlock {
  Widget build(BuildContext context, TextStyle base);
}

class _ParagraphBlock extends _HtmlBlock {
  _ParagraphBlock(this.html);
  final String html;

  @override
  Widget build(BuildContext context, TextStyle base) {
    return Text.rich(_inlineSpan(html, base));
  }
}

class _ListBlock extends _HtmlBlock {
  _ListBlock({required this.items, required this.ordered});
  final List<String> items;
  final bool ordered;

  @override
  Widget build(BuildContext context, TextStyle base) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(ordered ? '${i + 1}.' : '•', style: base.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Text.rich(_inlineSpan(items[i], base))),
              ],
            ),
          ),
      ],
    );
  }
}

TextSpan _inlineSpan(String html, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'<(strong|b|em|i)(\s[^>]*)?>(.*?)</\1>', caseSensitive: false, dotAll: true);
  var index = 0;
  final input = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  void addText(String raw, TextStyle style) {
    final text = raw
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    if (text.isEmpty) return;
    spans.add(TextSpan(text: text, style: style));
  }

  for (final m in re.allMatches(input)) {
    if (m.start > index) addText(input.substring(index, m.start), base);
    final tag = m.group(1)!.toLowerCase();
    final inner = m.group(3) ?? '';
    final style = (tag == 'strong' || tag == 'b')
        ? base.copyWith(fontWeight: FontWeight.w700)
        : base.copyWith(fontStyle: FontStyle.italic);
    addText(inner, style);
    index = m.end;
  }
  if (index < input.length) addText(input.substring(index), base);
  if (spans.isEmpty) addText(input, base);
  return TextSpan(style: base, children: spans);
}
