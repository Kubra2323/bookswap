import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/listing_repository.dart';
import '../models/listing.dart';

class ListingsViewModel extends ChangeNotifier {
  ListingsViewModel(this._repo);

  final ListingRepository _repo;
  StreamSubscription<List<Listing>>? _sub;

  List<Listing> _all = const [];
  String _query = '';
  bool _loading = true;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Listings that match the search text (title or ISBN).
  List<Listing> get visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((l) => l.title.toLowerCase().contains(q) || l.isbn.contains(q))
        .toList();
  }

  void start() {
    _sub?.cancel();
    _sub = _repo.watchActive().listen(
      (items) {
        _all = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object _) {
        _loading = false;
        _error = 'Could not load listings.';
        notifyListeners();
      },
    );
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> markSold(String listingId) async {
    try {
      await _repo.markSold(listingId);
    } catch (_) {
      _error = 'Could not mark as sold.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
