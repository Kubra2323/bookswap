import 'package:bookswap/data/book_repository.dart';
import 'package:bookswap/models/price_guide.dart';
import 'package:bookswap/viewmodels/sell_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _FakeBooks implements BookRepository {
  _FakeBooks({this.guide, this.failure});

  final PriceGuide? guide;
  final BookLookupFailure? failure;
  String? lastIsbn;

  @override
  Future<PriceGuide> getPriceGuide({
    required String isbn,
    required String edition,
    required String condition,
  }) async {
    lastIsbn = isbn;
    if (failure != null) throw failure!;
    return guide!;
  }
}

void main() {
  test('loadGuide strips hyphens and stores the guide', () async {
    final books = _FakeBooks(guide: const PriceGuide(low: 100, high: 120, median: 110, offersUsed: 3));
    final vm = SellViewModel(books: books, listings: FakeListingRepository(), ownerId: 'u1');
    await vm.loadGuide(isbn: '978-0-262-04630-5', edition: '4th', condition: 'Good');
    expect(books.lastIsbn, '9780262046305');
    expect(vm.guide?.hasEstimate, isTrue);
    expect(vm.loadingGuide, isFalse);
  });

  test('a failed guide does not block the seller', () async {
    final books = _FakeBooks(failure: const BookLookupFailure('Price guide is not available.'));
    final repo = FakeListingRepository();
    final vm = SellViewModel(books: books, listings: repo, ownerId: 'u1');

    await vm.loadGuide(isbn: '9780262046305', edition: '4th', condition: 'Good');
    expect(vm.guide, isNull);
    expect(vm.error, contains('not available'));

    final ok = await vm.publish(
      title: 'Introduction to Algorithms',
      isbn: '9780262046305',
      edition: '4th',
      condition: 'Good',
      priceTry: 170,
    );
    expect(ok, isTrue);
    expect(repo.created.single.priceTry, 170);
    expect(repo.created.single.ownerId, 'u1');
    expect(repo.created.single.isDemo, isFalse);
  });
}
