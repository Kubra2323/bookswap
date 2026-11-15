import 'package:cloud_functions/cloud_functions.dart';

import '../models/price_guide.dart';

/// Must match setGlobalOptions({ region }) in functions/index.js.
const String functionsRegion = 'europe-west1';

class BookLookupFailure implements Exception {
  const BookLookupFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class BookRepository {
  Future<PriceGuide> getPriceGuide({
    required String isbn,
    required String edition,
    required String condition,
  });
}

/// Talks to Cloud Functions only. Gemini and book API keys never reach the app.
class FunctionsBookRepository implements BookRepository {
  FunctionsBookRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  final FirebaseFunctions _functions;

  @override
  Future<PriceGuide> getPriceGuide({
    required String isbn,
    required String edition,
    required String condition,
  }) async {
    try {
      final result = await _functions.httpsCallable('getPriceGuide').call<Map<Object?, Object?>>({
        'isbn': isbn,
        'edition': edition,
        'condition': condition,
      });
      return PriceGuide.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      throw BookLookupFailure(
        e.code == 'invalid-argument'
            ? 'That ISBN is not valid.'
            : 'Price guide is not available. You can still enter a price yourself.',
      );
    }
  }
}
