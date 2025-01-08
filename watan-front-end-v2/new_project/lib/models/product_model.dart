class Product {
  final String id;
  final String name;
  final String description;
  final double? price;
  final bool occasion;
  final String ownerId;
  final List<String> images;
  final String categoryName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.occasion,
    required this.ownerId,
    required this.images,
    required this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      ownerId: json['user']['_id'],
      price: json['price'] != null ? json['price'].toDouble() : null,
      occasion: json['occasion'],
      images: List<String>.from(json['images']),
      categoryName: json['category']['name'],
    );
  }
}
