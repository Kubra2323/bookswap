/// Allowed conditions. firestore.rules uses the same list.
const List<String> listingConditions = ['Like new', 'Good', 'Fair', 'Worn'];

class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.isbn,
    required this.edition,
    required this.condition,
    required this.priceTry,
    required this.createdAt,
    this.status = 'active',
    this.isDemo = false,
  });

  final String id;
  final String ownerId;
  final String title;
  final String isbn;
  final String edition;
  final String condition;
  final int priceTry;
  final DateTime createdAt;
  final String status; // 'active' | 'sold'
  final bool isDemo; // demo listings never feed price calculations

  bool get isSold => status == 'sold';

  /// Fields sent to Firestore. createdAt is added by the repository (server time).
  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        'isbn': isbn,
        'edition': edition,
        'condition': condition,
        'priceTry': priceTry,
        'status': status,
        'isDemo': isDemo,
      };

  /// [map]['createdAt'] must already be a DateTime (the repository converts Timestamp).
  factory Listing.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return Listing(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isbn: map['isbn'] as String? ?? '',
      edition: map['edition'] as String? ?? '',
      condition: map['condition'] as String? ?? 'Good',
      priceTry: (map['priceTry'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
      isDemo: map['isDemo'] as bool? ?? false,
      createdAt: created is DateTime ? created : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
