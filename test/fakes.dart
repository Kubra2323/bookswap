import 'dart:async';

import 'package:bookswap/data/auth_repository.dart';
import 'package:bookswap/data/listing_repository.dart';
import 'package:bookswap/models/listing.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
  String? failWith;
  int registerCalls = 0;

  void emit(AppUser? user) => _controller.add(user);

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (failWith != null) throw AuthFailure(failWith!);
    emit(AppUser(uid: 'u1', email: email, emailVerified: true));
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls++;
    emit(AppUser(uid: 'u1', email: email, emailVerified: false));
  }

  @override
  Future<void> resendVerification() async {}

  @override
  Future<AppUser?> reload() async => const AppUser(uid: 'u1', email: 'a@agu.edu.tr', emailVerified: true);

  @override
  Future<void> signOut() async => emit(null);
}

class FakeListingRepository implements ListingRepository {
  final StreamController<List<Listing>> controller = StreamController<List<Listing>>();
  final List<String> soldIds = [];
  final List<Listing> created = [];

  @override
  Stream<List<Listing>> watchActive() => controller.stream;

  @override
  Future<void> create(Listing listing) async => created.add(listing);

  @override
  Future<void> markSold(String listingId) async => soldIds.add(listingId);
}

Listing sampleListing({String id = 'l1', String title = 'Introduction to Algorithms', String isbn = '9780262046305'}) {
  return Listing(
    id: id,
    ownerId: 'u1',
    title: title,
    isbn: isbn,
    edition: '4th',
    condition: 'Good',
    priceTry: 170,
    createdAt: DateTime(2026, 11, 9),
  );
}
