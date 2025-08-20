class Tile {
  final int value; // 0 = empty
  final int id; // unique identifier for animations

  Tile(this.value) : id = value;

  bool get isEmpty => value == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          id == other.id;

  @override
  int get hashCode => value.hashCode ^ id.hashCode;

  @override
  String toString() => 'Tile(value: $value, id: $id)';
}
