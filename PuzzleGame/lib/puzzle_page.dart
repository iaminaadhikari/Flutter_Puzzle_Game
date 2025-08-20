import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'tile.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with TickerProviderStateMixin {
  int _gridSize = 3;
  List<Tile> _tiles = [];
  int _moveCount = 0;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  late AnimationController _slideController;
  late AnimationController _solveController;
  late Animation<double> _solveAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _solveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _solveAnimation = CurvedAnimation(
      parent: _solveController,
      curve: Curves.elasticOut,
    );
    _initializePuzzle();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _solveController.dispose();
    super.dispose();
  }

  void _initializePuzzle() {
    _tiles = List.generate(_gridSize * _gridSize, (i) => Tile(i));
    _moveCount = 0;
    _startTime = null;
    _elapsedTime = Duration.zero;
    _shuffle();
  }

  void _shuffle() {
    do {
      _tiles.shuffle();
    } while (!_isSolvable() || _isSolved());

    _moveCount = 0;
    _startTime = DateTime.now();
    setState(() {});
  }

  bool _isSolvable() {
    final flat = _tiles.map((t) => t.value).toList();
    int inversions = 0;

    for (int i = 0; i < flat.length - 1; i++) {
      if (flat[i] == 0) continue;
      for (int j = i + 1; j < flat.length; j++) {
        if (flat[j] != 0 && flat[i] > flat[j]) inversions++;
      }
    }

    if (_gridSize.isOdd) {
      return inversions.isEven;
    } else {
      final emptyRowFromBottom = _gridSize - (flat.indexOf(0) ~/ _gridSize);
      return (inversions + emptyRowFromBottom).isOdd;
    }
  }

  bool _isSolved() {
    for (int i = 0; i < _gridSize * _gridSize - 1; i++) {
      if (_tiles[i].value != i + 1) return false;
    }
    return _tiles.last.value == 0;
  }

  void _onTap(int index) async {
    if (_isAnimating || _isSolved()) return;

    final emptyIndex = _tiles.indexWhere((t) => t.isEmpty);
    if (!_canMove(index, emptyIndex)) return;

    _isAnimating = true;
    await _slideController.forward();

    setState(() {
      final temp = _tiles[index];
      _tiles[index] = _tiles[emptyIndex];
      _tiles[emptyIndex] = temp;
      _moveCount++;

      if (_startTime != null) {
        _elapsedTime = DateTime.now().difference(_startTime!);
      }
    });

    _slideController.reset();
    _isAnimating = false;

    if (_isSolved()) {
      HapticFeedback.heavyImpact();
      _solveController.forward();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  bool _canMove(int index, int emptyIndex) {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final emptyRow = emptyIndex ~/ _gridSize;
    final emptyCol = emptyIndex % _gridSize;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void _changeGridSize(int newSize) {
    setState(() {
      _gridSize = newSize;
      _solveController.reset();
    });
    _initializePuzzle();
  }

  Color _getTileColor(int value, BuildContext context) {
    if (value == 0) return Colors.transparent;

    final theme = Theme.of(context);
    final hue = (value * 360 / (_gridSize * _gridSize)).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.3, 0.9).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final puzzleSize = math.min(screenWidth * 0.9, 400.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Enhanced Slide Puzzle'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_3x3),
            onSelected: _changeGridSize,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 3, child: Text('3×3 Grid')),
              const PopupMenuItem(value: 4, child: Text('4×4 Grid')),
              const PopupMenuItem(value: 5, child: Text('5×5 Grid')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    icon: Icons.touch_app,
                    label: 'Moves',
                    value: _moveCount.toString(),
                  ),
                  _StatCard(
                    icon: Icons.timer,
                    label: 'Time',
                    value: _formatTime(_elapsedTime),
                  ),
                  _StatCard(
                    icon: Icons.grid_on,
                    label: 'Size',
                    value: '${_gridSize}×$_gridSize',
                  ),
                ],
              ),
            ),

            // Puzzle Grid
            Expanded(
              child: Center(
                child: Container(
                  width: puzzleSize,
                  height: puzzleSize,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (context, index) {
                      final tile = _tiles[index];
                      return AnimatedBuilder(
                        animation: _solveAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isSolved()
                                ? 1.0 + (_solveAnimation.value * 0.1)
                                : 1.0,
                            child: _TileWidget(
                              tile: tile,
                              onTap: () => _onTap(index),
                              color: _getTileColor(tile.value, context),
                              gridSize: _gridSize,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _isSolved() || _isAnimating ? null : _shuffle,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _initializePuzzle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Game'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSolved()) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.celebration,
                                  color: Colors.green, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'Puzzle Solved!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completed in $_moveCount moves • ${_formatTime(_elapsedTime)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TileWidget extends StatelessWidget {
  final Tile tile;
  final VoidCallback onTap;
  final Color color;
  final int gridSize;

  const _TileWidget({
    required this.tile,
    required this.onTap,
    required this.color,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withOpacity(0.1),
        ),
      );
    }

    final fontSize = gridSize <= 3
        ? 28.0
        : gridSize == 4
            ? 24.0
            : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${tile.value}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
