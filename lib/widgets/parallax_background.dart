import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screens/focus_moment/animated_character.dart';

class ParallaxBackground extends StatefulWidget {
  final bool isRunning;

  const ParallaxBackground({super.key, required this.isRunning});

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _lastTick = Duration.zero;
  bool _isRunning = false;

  static const double _groundSpeed = 60.0;
  static const double _bgSpeedFactor = 1 / 3;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isRunning;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (_isRunning) {
      setState(() => _elapsed += delta);
    }
  }

  @override
  void didUpdateWidget(covariant ParallaxBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isRunning = widget.isRunning;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Widget _buildInfiniteLayer({
    required String asset,
    required double screenWidth,
    required double screenHeight,
    required double offset,
  }) {
    final tileIndex = (offset / screenWidth).floor();
    final localOffset = offset - tileIndex * screenWidth;

    Widget tile(int index) {
      Widget img = Image.asset(
        asset,
        fit: BoxFit.cover,
        width: screenWidth,
        height: screenHeight,
      );
      if (index.isOdd) {
        img = Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(-1, 1, 1),
          child: img,
        );
      }
      return img;
    }

    return Stack(
      children: [
        Positioned(
          left: -localOffset,
          top: 0,
          width: screenWidth,
          height: screenHeight,
          child: tile(tileIndex),
        ),
        Positioned(
          left: screenWidth - localOffset,
          top: 0,
          width: screenWidth,
          height: screenHeight,
          child: tile(tileIndex + 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final seconds = _elapsed.inMilliseconds / 1000.0;

    final groundOffset = seconds * _groundSpeed;
    final bgOffset = groundOffset * _bgSpeedFactor;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildInfiniteLayer(
              asset: 'assets/fond_lointain.png',
              screenWidth: size.width,
              screenHeight: size.height,
              offset: bgOffset,
            ),
          ),
          Positioned.fill(
            child: _buildInfiniteLayer(
              asset: 'assets/sol_proche.png',
              screenWidth: size.width,
              screenHeight: size.height,
              offset: groundOffset,
            ),
          ),
          Positioned(
            bottom: 80, 
            left: (size.width / 2) - 280, 
            child: AnimatedCharacter(
              size: 420,
              isWalking: widget.isRunning,
              frames: List.generate(16, (i) => 'assets/PersonnageAnimation/Nuit/Marche/${i + 1}.png'),
            ),     
          ),
        ],
      ),
    );
  }
}