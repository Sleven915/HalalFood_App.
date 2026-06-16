class Restaurant {
  final String name;
  final String location;
  final String rating;
  final String distance;
  final String imageUrl;
  final String category;

  Restaurant({
    required this.name,
    required this.location,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.category,
  });

  // Static lists to replace global variables
  static List<Restaurant> favorites = [];
  static List<Restaurant> all = [];
}
