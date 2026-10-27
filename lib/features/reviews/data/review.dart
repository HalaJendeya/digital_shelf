import '../../../core/utils/json.dart';

class Review {
  const Review({
    required this.id,
    required this.rating,
    this.comment,
    this.customerName,
    this.initials,
    this.createdAt,
  });

  factory Review.fromJson(Json json) {
    final customer = asJson(json['customer']);
    return Review(
      id: readInt(json['id']) ?? 0,
      rating: readInt(json['rating']) ?? 0,
      comment: readString(json['comment']),
      customerName: readString(customer['name']) ?? readString(json['customer_name']),
      initials: readString(customer['initials']),
      createdAt: readDate(json['created_at']),
    );
  }

  final int id;
  final int rating;
  final String? comment;
  final String? customerName;
  final String? initials;
  final DateTime? createdAt;
}

class ReviewsSummary {
  const ReviewsSummary({
    this.average = 0,
    this.count = 0,
    this.distribution = const {},
    this.latest = const [],
  });

  factory ReviewsSummary.fromJson(Json json) {
    final dist = asJson(json['distribution']);
    return ReviewsSummary(
      average: readDouble(json['average']) ?? 0,
      count: readInt(json['count']) ?? 0,
      distribution: {
        for (final e in dist.entries)
          if (readInt(e.key) != null) readInt(e.key)!: readInt(e.value) ?? 0,
      },
      latest: asJsonList(json['latest']).map(Review.fromJson).toList(),
    );
  }

  final double average;
  final int count;
  final Map<int, int> distribution;
  final List<Review> latest;
}
