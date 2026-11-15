class PriceSource {
  const PriceSource({required this.listingId, required this.priceTry, this.date});

  final String listingId;
  final int priceTry;
  final String? date;
}

/// Answer of the getPriceGuide Cloud Function.
/// [low] and [high] are null when there was not enough evidence: we never invent a range.
class PriceGuide {
  const PriceGuide({
    this.low,
    this.high,
    this.median,
    this.offersUsed = 0,
    this.reason,
    this.summary,
    this.caveats = const [],
    this.sources = const [],
  });

  final int? low;
  final int? high;
  final int? median;
  final int offersUsed;
  final String? reason; // e.g. 'not_enough_offers', 'edition_required'
  final String? summary; // Gemini explanation; null if Gemini failed (plan B)
  final List<String> caveats;
  final List<PriceSource> sources;

  bool get hasEstimate => low != null && high != null;

  factory PriceGuide.fromMap(Map<String, dynamic> map) {
    final estimate = map['estimate'] as Map?;
    final explanation = map['explanation'] as Map?;
    final sources = (map['sources'] as List? ?? const [])
        .whereType<Map>()
        .map((s) => PriceSource(
              listingId: s['listingId'] as String? ?? '',
              priceTry: (s['priceTry'] as num?)?.toInt() ?? 0,
              date: s['date'] as String?,
            ))
        .toList();
    return PriceGuide(
      low: (estimate?['low'] as num?)?.toInt(),
      high: (estimate?['high'] as num?)?.toInt(),
      median: (estimate?['median'] as num?)?.toInt(),
      offersUsed: (map['offersUsed'] as num? ?? map['offersFound'] as num? ?? 0).toInt(),
      reason: map['reason'] as String?,
      summary: explanation?['summary'] as String?,
      caveats: (explanation?['caveats'] as List? ?? const []).whereType<String>().toList(),
      sources: sources,
    );
  }
}
