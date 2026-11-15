import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';

abstract class ListingRepository {
  /// Newest first, active listings only.
  Stream<List<Listing>> watchActive();
  Future<void> create(Listing listing);
  Future<void> markSold(String listingId);
}

class FirestoreListingRepository implements ListingRepository {
  FirestoreListingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('listings');

  @override
  Stream<List<Listing>> watchActive() {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              final ts = data['createdAt'];
              // A just-written listing has no server time yet; show it as "now".
              data['createdAt'] = ts is Timestamp ? ts.toDate() : DateTime.now();
              return Listing.fromMap(doc.id, data);
            }).toList());
  }

  @override
  Future<void> create(Listing listing) {
    // firestore.rules require createdAt == request.time, so we use the server timestamp.
    return _col.add({...listing.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> markSold(String listingId) => _col.doc(listingId).update({'status': 'sold'});
}
