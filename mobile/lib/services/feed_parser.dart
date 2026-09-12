import 'package:dart_rss/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;

class ParsedFeedItem {
  const ParsedFeedItem({
    required this.title,
    required this.link,
    required this.guid,
    required this.snippet,
    required this.publishedAt,
  });

  final String title;
  final String link;
  final String guid;
  final String snippet;
  final DateTime publishedAt;
}

class ParsedFeed {
  const ParsedFeed({required this.title, required this.items});

  final String title;
  final List<ParsedFeedItem> items;
}

class FeedParseException implements Exception {
  FeedParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parse un contenu de flux RSS 2.0 / RSS 1.0 ou Atom. Lance
/// [FeedParseException] si le contenu n'est ni l'un ni l'autre (validé
/// empiriquement : RssFeed.parse / AtomFeed.parse lancent bien une exception
/// sur un contenu qui n'est pas le leur, plutôt que de renvoyer un résultat
/// vide silencieusement).
ParsedFeed parseFeedContent(String body) {
  try {
    final rss = RssFeed.parse(body);
    return ParsedFeed(
      title: (rss.title ?? '').trim(),
      items: rss.items
          .map((item) {
            final link = (item.link ?? '').trim();
            final rawGuid = (item.guid ?? '').trim();
            return ParsedFeedItem(
              title: (item.title ?? '(sans titre)').trim(),
              link: link,
              guid: rawGuid.isNotEmpty ? rawGuid : link,
              snippet: stripHtml(item.description ?? ''),
              publishedAt: parseRfc822Date(item.pubDate ?? '') ?? DateTime.now(),
            );
          })
          .where((i) => i.link.isNotEmpty)
          .toList(),
    );
  } catch (_) {
    // Pas un flux RSS : on tente Atom avant d'abandonner.
  }

  try {
    final atom = AtomFeed.parse(body);
    return ParsedFeed(
      title: (atom.title ?? '').trim(),
      items: atom.items
          .map((item) {
            final href = item.links.isNotEmpty
                ? (item.links.firstWhere(
                      (l) => l.rel == 'alternate',
                      orElse: () => item.links.first,
                    ).href ??
                    '')
                : '';
            final rawId = (item.id ?? '').trim();
            final dateStr = item.published ?? item.updated ?? '';
            return ParsedFeedItem(
              title: (item.title ?? '(sans titre)').trim(),
              link: href.trim(),
              guid: rawId.isNotEmpty ? rawId : href.trim(),
              snippet: stripHtml(item.summary ?? item.content ?? ''),
              publishedAt: DateTime.tryParse(dateStr) ?? DateTime.now(),
            );
          })
          .where((i) => i.link.isNotEmpty)
          .toList(),
    );
  } catch (_) {
    throw FeedParseException("Le contenu récupéré n'est pas un flux RSS ou Atom valide.");
  }
}

/// Retire les balises HTML tout en préservant les sauts de paragraphe, pour
/// un affichage lisible du résumé fourni par le flux.
String stripHtml(String raw) {
  if (raw.trim().isEmpty) return '';
  final withBreaks = raw.replaceAllMapped(
    RegExp(r'</p\s*>|<br\s*/?>|</div\s*>', caseSensitive: false),
    (m) => '\n',
  );
  final text = html_parser.parse(withBreaks).body?.text ?? withBreaks;
  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n\n');
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Parseur RFC 822 permissif (format `pubDate` des flux RSS) : gère les
/// fuseaux nommés (GMT/UTC) et les offsets numériques (+0000, -0500...).
/// `DateTime.tryParse` ne comprend que l'ISO 8601, et `HttpDate.parse` de
/// dart:io rejette les offsets numériques — validé empiriquement, d'où ce
/// parseur maison.
DateTime? parseRfc822Date(String raw) {
  final match = RegExp(
    r'^(?:\w{3},\s*)?(\d{1,2})\s+(\w{3})\w*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(\S+)?$',
  ).firstMatch(raw.trim());
  if (match == null) return null;

  final day = int.parse(match.group(1)!);
  final month = _months[match.group(2)!.toLowerCase()];
  if (month == null) return null;
  var year = int.parse(match.group(3)!);
  if (year < 100) year += year < 70 ? 2000 : 1900;
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6) ?? '0');
  final tz = match.group(7) ?? 'GMT';

  var offsetMinutes = 0;
  final tzMatch = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(tz);
  if (tzMatch != null) {
    final sign = tzMatch.group(1) == '-' ? -1 : 1;
    offsetMinutes = sign * (int.parse(tzMatch.group(2)!) * 60 + int.parse(tzMatch.group(3)!));
  }

  final utcDate = DateTime.utc(year, month, day, hour, minute, second);
  return utcDate.subtract(Duration(minutes: offsetMinutes));
}
