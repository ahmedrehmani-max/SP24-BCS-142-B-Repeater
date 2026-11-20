/// A glass tube holding liquid layers.
///
/// [layers] is bottom-first: index 0 is the bottom of the tube, the last
/// element is the topmost liquid. Each value is a colour index into
/// [LiquidPalette].
class Tube {
  final List<int> layers;
  final int capacity;

  Tube({List<int>? layers, this.capacity = 4})
      : layers = layers == null ? <int>[] : List<int>.from(layers);

  Tube copy() => Tube(layers: layers, capacity: capacity);

  bool get isEmpty => layers.isEmpty;
  bool get isFull => layers.length == capacity;
  int get freeSpace => capacity - layers.length;

  /// Colour of the topmost liquid, or null when the tube is empty.
  int? get topColor => layers.isEmpty ? null : layers.last;

  /// How many units of the same colour sit on top, as one pourable group.
  int get topGroupSize {
    if (layers.isEmpty) return 0;
    final color = layers.last;
    var count = 0;
    for (var i = layers.length - 1; i >= 0 && layers[i] == color; i--) {
      count++;
    }
    return count;
  }

  /// A tube is done when it is empty, or full of a single colour.
  bool get isComplete {
    if (layers.isEmpty) return true;
    if (layers.length != capacity) return false;
    return layers.every((color) => color == layers.first);
  }

  /// True when the tube is full of one colour — used for the "tube solved"
  /// feedback, which an empty tube should not trigger.
  bool get isSolvedStack =>
      layers.length == capacity && layers.every((c) => c == layers.first);

  @override
  String toString() => layers.join(',');
}
