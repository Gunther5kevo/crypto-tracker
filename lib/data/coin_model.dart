class Coin {
  final String id;
  final String name;
  final String symbol;
  final double price;
  final double change;
  final List<double> spark;
  final bool starred;

  Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.change,
    required this.spark,
    required this.starred,
  });

  Coin copyWith({bool? starred}) {
    return Coin(
      id: id,
      name: name,
      symbol: symbol,
      price: price,
      change: change,
      spark: spark,
      starred: starred ?? this.starred,
    );
  }
}