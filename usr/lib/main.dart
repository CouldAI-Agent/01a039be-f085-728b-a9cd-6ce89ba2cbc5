import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SnakeGameScreen(),
      },
    );
  }
}

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  // Game Constants mirroring the Python version
  static const int gridSize = 20;
  static const int boardWidth = 600;
  static const int boardHeight = 400;

  List<Point<int>> snake = [];
  Point<int> direction = const Point(gridSize, 0);
  Point<int>? food;
  int score = 0;
  bool gameOver = false;
  Timer? timer;

  final Random random = Random();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    setState(() {
      snake = [const Point(boardWidth ~/ 2, boardHeight ~/ 2)];
      direction = const Point(gridSize, 0);
      score = 0;
      gameOver = false;
      spawnFood();
    });

    timer?.cancel();
    // 10 FPS (100ms per tick)
    timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      updateGame();
    });
  }

  void spawnFood() {
    while (true) {
      int x = random.nextInt(boardWidth ~/ gridSize) * gridSize;
      int y = random.nextInt(boardHeight ~/ gridSize) * gridSize;
      Point<int> newFood = Point(x, y);
      if (!snake.contains(newFood)) {
        food = newFood;
        break;
      }
    }
  }

  void updateGame() {
    if (gameOver) return;

    setState(() {
      Point<int> newHead = Point(
        snake.first.x + direction.x,
        snake.first.y + direction.y,
      );

      // Check Collisions with Wall
      if (newHead.x < 0 ||
          newHead.x >= boardWidth ||
          newHead.y < 0 ||
          newHead.y >= boardHeight) {
        gameOver = true;
        timer?.cancel();
        return;
      }

      // Check Collisions with Self
      if (snake.contains(newHead)) {
        gameOver = true;
        timer?.cancel();
        return;
      }

      snake.insert(0, newHead);

      // Check if Snake ate the Food
      if (newHead == food) {
        score++;
        spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp && direction.y != gridSize) {
        direction = const Point(0, -gridSize);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && direction.y != -gridSize) {
        direction = const Point(0, gridSize);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && direction.x != gridSize) {
        direction = const Point(-gridSize, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && direction.x != -gridSize) {
        direction = const Point(gridSize, 0);
      }
    }
  }

  void handleSwipe(DragEndDetails details) {
    final double dx = details.velocity.pixelsPerSecond.dx;
    final double dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0 && direction.x != -gridSize) {
        direction = const Point(gridSize, 0);
      } else if (dx < 0 && direction.x != gridSize) {
        direction = const Point(-gridSize, 0);
      }
    } else {
      if (dy > 0 && direction.y != -gridSize) {
        direction = const Point(0, gridSize);
      } else if (dy < 0 && direction.y != gridSize) {
        direction = const Point(0, -gridSize);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(focusNode);
    }

    return Scaffold(
      body: SafeArea(
        child: KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: handleKey,
          child: GestureDetector(
            onPanEnd: handleSwipe,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Container(
                          width: boardWidth.toDouble(),
                          height: boardHeight.toDouble(),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: Stack(
                            children: [
                              if (food != null)
                                Positioned(
                                  left: food!.x.toDouble(),
                                  top: food!.y.toDouble(),
                                  child: Container(
                                    width: gridSize.toDouble() - 2,
                                    height: gridSize.toDouble() - 2,
                                    color: Colors.red,
                                  ),
                                ),
                              for (var segment in snake)
                                Positioned(
                                  left: segment.x.toDouble(),
                                  top: segment.y.toDouble(),
                                  child: Container(
                                    width: gridSize.toDouble() - 2,
                                    height: gridSize.toDouble() - 2,
                                    color: Colors.green,
                                  ),
                                ),
                              if (gameOver)
                                Container(
                                  color: Colors.black87,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Game Over!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                            textStyle: const TextStyle(fontSize: 24),
                                          ),
                                          onPressed: startGame,
                                          child: const Text('Play Again'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Use arrow keys or swipe to move',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}