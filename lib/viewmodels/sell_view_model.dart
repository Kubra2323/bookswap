import 'package:flutter/foundation.dart';

import '../data/book_repository.dart';
import '../data/listing_repository.dart';
import '../models/listing.dart';
import '../models/price_guide.dart';

class SellViewModel extends ChangeNotifier {
  SellViewModel({
    required BookRepository books,
    required ListingRepository listings,
    required this.ownerId,
  })  : _books = books,
        _listings = listings;

  final BookRepository _books;
  final ListingRepository _listings;
  final String ownerId;

  PriceGuide? _guide;
  bool _loadingGuide = false;
  bool _publishing = false;
  String? _error;

  PriceGuide? get guide => _guide;
  bool get loadingGuide => _loadingGuide;
  bool get publishing => _publishing;
  String? get error => _error;

  /// Asks the Cloud Function for a sourced price guide. A failure never blocks the seller:
  /// they can always type a price themselves (P0 plan B).
  Future<void> loadGuide({
    required String isbn,
    required String edition,
    required String condition,
  }) async {
    _loadingGuide = true;
    _error = null;
    notifyListeners();
    try {
      _guide = await _books.getPriceGuide(
        isbn: isbn.replaceAll(RegExp(r'[\s-]'), ''),
        edition: edition.trim(),
        condition: condition,
      );
    } on BookLookupFailure catch (e) {
      _guide = null;
      _error = e.message;
    } finally {
      _loadingGuide = false;
      notifyListeners();
    }
  }

  Future<bool> publish({
    required String title,
    required String isbn,
    required String edition,
    required String condition,
    required int priceTry,
  }) async {
    _publishing = true;
    _error = null;
    notifyListeners();
    try {
      await _listings.create(Listing(
        id: '',
        ownerId: ownerId,
        title: title.trim(),
        isbn: isbn.replaceAll(RegExp(r'[\s-]'), ''),
        edition: edition.trim(),
        condition: condition,
        priceTry: priceTry,
        createdAt: DateTime.now(),
      ));
      return true;
    } catch (_) {
      _error = 'Could not publish the listing. Check your connection and try again.';
      return false;
    } finally {
      _publishing = false;
      notifyListeners();
    }
  }
}
