import 'package:bookswap/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateUniversityEmail', () {
    test('accepts agu.edu.tr and ogr.agu.edu.tr', () {
      expect(validateUniversityEmail('ali.veli@agu.edu.tr'), isNull);
      expect(validateUniversityEmail('ali@ogr.agu.edu.tr'), isNull);
      expect(validateUniversityEmail('  Ali@AGU.EDU.TR '), isNull);
    });

    test('rejects other domains and look-alikes', () {
      expect(validateUniversityEmail('ali@gmail.com'), isNotNull);
      expect(validateUniversityEmail('ali@agu.edu.tr.evil.com'), isNotNull);
      expect(validateUniversityEmail(''), isNotNull);
      expect(validateUniversityEmail(null), isNotNull);
    });
  });

  group('validateIsbn', () {
    test('accepts 10 and 13 digit ISBNs with hyphens', () {
      expect(validateIsbn('978-0-262-04630-5'), isNull);
      expect(validateIsbn('080442957X'), isNull);
    });

    test('rejects wrong length and letters', () {
      expect(validateIsbn('12345'), isNotNull);
      expect(validateIsbn('97802620463AB'), isNotNull);
    });
  });

  group('validatePriceTry', () {
    test('accepts whole positive prices', () => expect(validatePriceTry('170'), isNull));

    test('rejects zero, negative, text and huge values', () {
      expect(validatePriceTry('0'), isNotNull);
      expect(validatePriceTry('-5'), isNotNull);
      expect(validatePriceTry('abc'), isNotNull);
      expect(validatePriceTry('100000'), isNotNull);
    });
  });
}
