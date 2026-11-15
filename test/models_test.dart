import 'package:bookswap/models/listing.dart';
import 'package:bookswap/models/price_guide.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('Listing', () {
    test('toMap/fromMap round trip keeps the fields', () {
      final original = sampleListing();
      final map = {...original.toMap(), 'createdAt': original.createdAt};
      final back = Listing.fromMap('l1', map);
      expect(back.title, original.title);
      expect(back.isbn, original.isbn);
      expect(back.priceTry, 170);
      expect(back.isDemo, false);
      expect(back.createdAt, original.createdAt);
    });

    test('toMap does not contain createdAt (server time is added by the repository)', () {
      expect(sampleListing().toMap().containsKey('createdAt'), isFalse);
    });

    test('fromMap survives missing fields', () {
      final l = Listing.fromMap('x', {});
      expect(l.status, 'active');
      expect(l.priceTry, 0);
    });
  });

  group('PriceGuide', () {
    test('parses an estimate with explanation and sources', () {
      final g = PriceGuide.fromMap({
        'estimate': {'low': 150, 'high': 190, 'median': 170, 'currency': 'TRY'},
        'offersUsed': 5,
        'explanation': {'summary': 'Prices are stable.', 'caveats': ['Condition matters.']},
        'sources': [
          {'listingId': 'a', 'priceTry': 150, 'date': '2026-11-02T10:00:00.000Z'},
        ],
      });
      expect(g.hasEstimate, isTrue);
      expect(g.low, 150);
      expect(g.offersUsed, 5);
      expect(g.summary, 'Prices are stable.');
      expect(g.sources.single.priceTry, 150);
    });

    test('no estimate when there is not enough evidence', () {
      final g = PriceGuide.fromMap({'estimate': null, 'reason': 'not_enough_offers', 'offersFound': 2, 'sources': []});
      expect(g.hasEstimate, isFalse);
      expect(g.reason, 'not_enough_offers');
      expect(g.offersUsed, 2);
    });

    test('estimate without explanation still works (Gemini failed, plan B)', () {
      final g = PriceGuide.fromMap({
        'estimate': {'low': 100, 'high': 120, 'median': 110},
        'offersUsed': 3,
        'explanation': null,
        'sources': [],
      });
      expect(g.hasEstimate, isTrue);
      expect(g.summary, isNull);
    });
  });
}
