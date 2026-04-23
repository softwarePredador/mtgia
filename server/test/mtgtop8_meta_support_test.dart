import 'package:html/parser.dart' as html_parser;
import 'package:test/test.dart';

import '../lib/meta/mtgtop8_meta_support.dart';

void main() {
  group('extractRecentMtgTop8EventPaths', () {
    test('deduplica e limita paths de evento', () {
      final document = html_parser.parse('''
        <html>
          <body>
            <a href="event?e=100">A</a>
            <a href="/event?e=200">B</a>
            <a href="event?e=100&f=EDH">C</a>
            <a href="event?e=300">D</a>
          </body>
        </html>
      ''');

      final paths = extractRecentMtgTop8EventPaths(document, limit: 2);

      expect(paths, hasLength(2));
      expect(paths, contains('event?e=100'));
      expect(paths, contains('event?e=200'));
    });
  });

  group('parseMtgTop8EventDeckRow', () {
    test('extrai placement, archetype, format e deck url da estrutura real',
        () {
      final document = html_parser.parse('''
        <div class="hover_tr" style="padding:3px 0px 3px 0px;" align="left">
          <div style="display:flex;align-items:center;">
            <div style="width:42px;" align="center" class="S14">2</div>
            <div style="width:80px;height:40px;background:black;">
              <a href="?e=83905&amp;d=837418&amp;f=EDH"><img src="/metas_thumbs/2749.jpg"></a>
            </div>
            <div style="flex:1;">
              <div class="S14" style="width:100%;padding-left:4px;margin-bottom:4px;">
                <a href="?e=83905&amp;d=837418&amp;f=EDH">Spider-man 2099</a>
              </div>
              <div style="margin-right:10px;" align="right" class="G11">
                <a class="player" href="search?player=Noham+Maubert">Noham Maubert</a>
              </div>
            </div>
          </div>
        </div>
      ''');

      final row = document.querySelector('div.hover_tr')!;
      final parsed = parseMtgTop8EventDeckRow(row);

      expect(parsed, isNotNull);
      expect(parsed!.placement, '2');
      expect(parsed.archetype, 'Spider-man 2099');
      expect(parsed.formatCode, 'EDH');
      expect(parsed.deckId, '837418');
      expect(
        parsed.deckUrl,
        'https://www.mtgtop8.com/?e=83905&d=837418&f=EDH',
      );
    });

    test('cai no defaultFormatCode quando href nao traz formato', () {
      final document = html_parser.parse('''
        <div class="hover_tr">
          <div><div class="S14">Top 8</div></div>
          <div><a href="?e=111&amp;d=222">Deck Sem Formato</a></div>
        </div>
      ''');

      final row = document.querySelector('div.hover_tr')!;
      final parsed = parseMtgTop8EventDeckRow(
        row,
        defaultFormatCode: 'cEDH',
      );

      expect(parsed, isNotNull);
      expect(parsed!.placement, 'Top 8');
      expect(parsed.formatCode, 'cEDH');
    });

    test('retorna null quando nao existe deck link valido', () {
      final document = html_parser.parse('''
        <div class="hover_tr">
          <div class="S14">1</div>
          <div><a href="search?player=abc">Player Only</a></div>
        </div>
      ''');

      final row = document.querySelector('div.hover_tr')!;
      final parsed = parseMtgTop8EventDeckRow(row);

      expect(parsed, isNull);
    });

    test('extrai mapa de deck rows por source url', () {
      final document = html_parser.parse('''
        <div class="hover_tr">
          <div style="display:flex;align-items:center;">
            <div class="S14">2</div>
            <div><a href="?e=100&d=200&f=EDH"><img src="/a.jpg"></a></div>
            <div><div class="S14"><a href="?e=100&d=200&f=EDH">Deck A</a></div></div>
          </div>
        </div>
        <div class="hover_tr">
          <div style="display:flex;align-items:center;">
            <div class="S14">3</div>
            <div><a href="?e=100&d=201&f=EDH"><img src="/b.jpg"></a></div>
            <div><div class="S14"><a href="?e=100&d=201&f=EDH">Deck B</a></div></div>
          </div>
        </div>
      ''');

      final parsed = extractMtgTop8EventDeckRowsByUrl(document);

      expect(parsed, hasLength(2));
      expect(
        parsed['https://www.mtgtop8.com/?e=100&d=200&f=EDH']?.archetype,
        'Deck A',
      );
      expect(
        parsed['https://www.mtgtop8.com/?e=100&d=201&f=EDH']?.placement,
        '3',
      );
    });
  });

  group('extractMtgTop8Placement', () {
    test('usa fallback textual quando nao acha div de rank isolado', () {
      final document = html_parser.parse('''
        <div class="hover_tr">
          Top 16 Weird Deck Player Name
        </div>
      ''');

      final row = document.querySelector('div.hover_tr')!;
      expect(extractMtgTop8Placement(row), 'Top 16');
    });
  });

  group('source url helpers', () {
    test('extrai event id e format code de source url', () {
      const sourceUrl = 'https://www.mtgtop8.com/?e=76769&d=782421&f=EDH';

      expect(extractMtgTop8EventIdFromSourceUrl(sourceUrl), '76769');
      expect(extractMtgTop8FormatCodeFromSourceUrl(sourceUrl), 'EDH');
    });
  });
}
