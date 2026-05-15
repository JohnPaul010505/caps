import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── BG slide + fade ────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;
  late final Animation<Offset> _bgSlide;

  // ── T.png (slides from left) ───────────────────────────────────────────
  late final AnimationController _tCtrl;
  late final Animation<Offset> _tSlide;
  late final Animation<double> _tFade;

  // ── J.png (slides from right) ─────────────────────────────────────────
  late final AnimationController _jCtrl;
  late final Animation<Offset> _jSlide;
  late final Animation<double> _jFade;

  // ── Bomb explosion merge ───────────────────────────────────────────────
  late final AnimationController _mergeCtrl;
  late final Animation<double> _flashOpacity;    // red-orange radial blast
  late final Animation<double> _logoScale;        // explosive overshoot
  late final Animation<double> _logoOpacity;
  late final Animation<double> _tJFade;           // fade T & J out instantly
  late final Animation<double> _shockwave1;       // expanding ring 1
  late final Animation<double> _shockwave2;       // expanding ring 2
  late final Animation<double> _particleProgress; // spark particles

  // ── Text ───────────────────────────────────────────────────────────────
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // ── Button ─────────────────────────────────────────────────────────────
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  // ── Fire & flakes (loop after button appears) ─────────────────────────
  late final AnimationController _fireCtrl;
  late final Animation<double> _fireFade;
  bool _showFire = false;

  bool _showCombined = false;

  @override
  void initState() {
    super.initState();

    // 1. Background slide-from-right + fade (0 → 900 ms)
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _bgSlide = Tween<Offset>(
        begin: const Offset(0.18, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutCubic));

    // 2. T slides in from left (400 → 1100 ms)
    _tCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _tSlide = Tween<Offset>(
        begin: const Offset(-1.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tCtrl, curve: Curves.easeOutCubic));
    _tFade = CurvedAnimation(parent: _tCtrl, curve: Curves.easeIn);

    // 3. J slides in from right (500 → 1200 ms)
    _jCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _jSlide = Tween<Offset>(
        begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _jCtrl, curve: Curves.easeOutCubic));
    _jFade = CurvedAnimation(parent: _jCtrl, curve: Curves.easeIn);

    // 4. BOMB EXPLOSION (1300 → 2200 ms — 900 ms total)
    _mergeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    // T & J vanish instantly on impact
    _tJFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _mergeCtrl,
            curve: const Interval(0.0, 0.18, curve: Curves.easeIn)));

    // Red-orange radial blast: peak early then fade
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 88),
    ]).animate(_mergeCtrl);

    // Logo: explosive scale — shoots out large then snaps back
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.65)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 32),
      TweenSequenceItem(
          tween: Tween(begin: 1.65, end: 0.88)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 28),
      TweenSequenceItem(
          tween: Tween(begin: 0.88, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
    ]).animate(_mergeCtrl);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _mergeCtrl,
            curve: const Interval(0.0, 0.28, curve: Curves.easeIn)));

    // Shockwave ring 1 — first ring expands fast
    _shockwave1 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _mergeCtrl,
            curve: const Interval(0.0, 0.58, curve: Curves.easeOut)));

    // Shockwave ring 2 — slightly delayed, smaller
    _shockwave2 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _mergeCtrl,
            curve: const Interval(0.12, 0.72, curve: Curves.easeOut)));

    // Spark particles fly outward
    _particleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _mergeCtrl,
            curve: const Interval(0.0, 0.90, curve: Curves.easeOut)));

    // 5. Text fade + slide up (2200 → 2800 ms)
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
        begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // 6. Button slide up (2600 → 3200 ms)
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn);
    _btnSlide = Tween<Offset>(
        begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOutCubic));

    // 7. Fire loop — repeats forever once button appears
    _fireCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _fireFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl, curve: const Interval(0.5, 1.0)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // BG
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // T & J slide in
    _tCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _jCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 750));

    // BOOM
    setState(() => _showCombined = true);
    _mergeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 860));

    // Text
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 380));

    // Button
    _btnCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showFire = true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _tCtrl.dispose();
    _jCtrl.dispose();
    _mergeCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    _fireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ────────────────────────────────────────────────
          FadeTransition(
            opacity: _bgFade,
            child: SlideTransition(
              position: _bgSlide,
              child: Image.asset(
                'assets/images/triplejBG.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Centered logo + text column ───────────────────────────────
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo stack (T, J, explosion effects, combined logo)
                SizedBox(
                  width: 400,
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // T.png — slides from left, instantly fades on impact
                      FadeTransition(
                        opacity: _showCombined ? _tJFade : _tFade,
                        child: SlideTransition(
                          position: _tSlide,
                          child: Image.asset(
                            'assets/images/T.png',
                            width: 380,
                            height: 380,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // J.png — slides from right, instantly fades on impact
                      FadeTransition(
                        opacity: _showCombined ? _tJFade : _jFade,
                        child: SlideTransition(
                          position: _jSlide,
                          child: Image.asset(
                            'assets/images/J.png',
                            width: 360,
                            height: 360,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // ── Explosion: shockwave rings + spark particles ──
                      if (_showCombined)
                        AnimatedBuilder(
                          animation: _mergeCtrl,
                          builder: (_, __) => CustomPaint(
                            size: const Size(400, 400),
                            painter: _ExplosionPainter(
                              shockwave1: _shockwave1.value,
                              shockwave2: _shockwave2.value,
                              particleProgress: _particleProgress.value,
                            ),
                          ),
                        ),

                      // Combined logo — explosive scale-in
                      if (_showCombined)
                        AnimatedBuilder(
                          animation: _mergeCtrl,
                          builder: (_, child) => FadeTransition(
                            opacity: _logoOpacity,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: child,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/triplej_logo.png',
                            width: 820,
                            height: 820,
                            fit: BoxFit.contain,
                          ),
                        ),

                      // Red-orange radial blast flash
                      if (_showCombined)
                        AnimatedBuilder(
                          animation: _flashOpacity,
                          builder: (_, __) => Opacity(
                            opacity: _flashOpacity.value,
                            child: Container(
                              width: 360,
                              height: 360,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white,
                                    const Color(0xFFFF6600).withOpacity(0.95),
                                    const Color(0xFFCC0000).withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.22, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 0),

                // ── Text directly under the logo ─────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TRIPLE J — bigger metallic silver
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFCCCCCC),
                              Color(0xFF999999),
                              Color(0xFFCCCCCC),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            'TRIPLE J',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.85),
                                  blurRadius: 10,
                                  offset: const Offset(2, 3),
                                ),
                                const Shadow(
                                  color: Colors.white24,
                                  blurRadius: 5,
                                  offset: Offset(-1, -1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // FITNESS CENTER — bigger spaced subtitle
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFCCCCCC),
                              Color(0xFF888888),
                              Color(0xFFCCCCCC),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'FITNESS CENTER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 10,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.75),
                                  blurRadius: 6,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fire flakes scattered across screen ───────────────────────
          if (_showFire)
            FadeTransition(
              opacity: _fireFade,
              child: AnimatedBuilder(
                animation: _fireCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _FireFlakesPainter(progress: _fireCtrl.value),
                ),
              ),
            ),

          // ── Continue button ───────────────────────────────────────────
          Positioned(
            left: 32,
            right: 32,
            bottom: 48,
            child: FadeTransition(
              opacity: _btnFade,
              child: SlideTransition(
                position: _btnSlide,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAA0000),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'C O N T I N U E',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Explosion CustomPainter: shockwave rings + spark particles ────────────

class _ExplosionPainter extends CustomPainter {
  final double shockwave1;
  final double shockwave2;
  final double particleProgress;

  // Seeded so sparks are consistent every run
  static final _rng = Random(42);
  static final List<_Particle> _particles = List.generate(28, (i) {
    final angle = (i / 28) * 2 * pi + _rng.nextDouble() * 0.22;
    final speed = 68.0 + _rng.nextDouble() * 120.0;
    final size  = 2.5 + _rng.nextDouble() * 4.0;
    // 0=white 1=orange 2=deep-red 3=yellow
    final colorIdx = _rng.nextInt(4);
    return _Particle(angle: angle, speed: speed, size: size, colorIdx: colorIdx);
  });

  static const List<Color> _sparkColors = [
    Colors.white,
    Color(0xFFFF8C00),
    Color(0xFFDD1100),
    Color(0xFFFFDD00),
  ];

  _ExplosionPainter({
    required this.shockwave1,
    required this.shockwave2,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center   = Offset(size.width / 2, size.height / 2);
    final maxR     = size.width * 0.56;

    // ── Shockwave ring 1 — thick red-orange, fades as it expands ─────
    if (shockwave1 > 0 && shockwave1 < 1) {
      final opacity   = (1.0 - shockwave1).clamp(0.0, 1.0) * 0.95;
      final thickness = (1.0 - shockwave1) * 6.0 + 1.5;
      canvas.drawCircle(
        center,
        shockwave1 * maxR,
        Paint()
          ..color      = const Color(0xFFFF3300).withOpacity(opacity)
          ..style      = PaintingStyle.stroke
          ..strokeWidth = thickness,
      );
    }

    // ── Shockwave ring 2 — thinner orange, slightly smaller ──────────
    if (shockwave2 > 0 && shockwave2 < 1) {
      final opacity = (1.0 - shockwave2).clamp(0.0, 1.0) * 0.7;
      canvas.drawCircle(
        center,
        shockwave2 * maxR * 0.78,
        Paint()
          ..color      = const Color(0xFFFF9900).withOpacity(opacity)
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ── Spark particles with trailing streaks ────────────────────────
    if (particleProgress > 0) {
      for (final p in _particles) {
        final dist    = p.speed * particleProgress;
        final opacity = (1.0 - particleProgress * 1.05).clamp(0.0, 1.0);
        if (opacity <= 0) continue;

        final color   = _sparkColors[p.colorIdx];
        final tip     = center + Offset(cos(p.angle) * dist, sin(p.angle) * dist);
        final radius  = (p.size * (1.0 - particleProgress * 0.55)).clamp(0.5, 8.0);

        // Glow dot at tip
        canvas.drawCircle(tip, radius, Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.fill);

        // Trail streak back toward center
        final trailFraction = 0.60;
        final tail = center + Offset(
          cos(p.angle) * dist * trailFraction,
          sin(p.angle) * dist * trailFraction,
        );
        canvas.drawLine(
          tail,
          tip,
          Paint()
            ..color     = color.withOpacity(opacity * 0.45)
            ..strokeWidth = radius * 0.65
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) =>
      shockwave1        != old.shockwave1        ||
          shockwave2        != old.shockwave2        ||
          particleProgress  != old.particleProgress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final int    colorIdx;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.colorIdx,
  });
}

// ── Floating fire flakes across the full screen ───────────────────────────

class _FireFlakesPainter extends CustomPainter {
  final double progress;

  static final _rng = Random(13);
  static final List<_FireFlake> _flakes = List.generate(40, (i) => _FireFlake(
    xFrac:    _rng.nextDouble(),
    yStart:   _rng.nextDouble(),
    speed:    0.3 + _rng.nextDouble() * 0.6,
    size:     2.0 + _rng.nextDouble() * 5.0,
    drift:    (_rng.nextDouble() - 0.5) * 0.04,
    phase:    _rng.nextDouble() * 2 * pi,
    colorIdx: _rng.nextInt(4),
  ));

  static const List<Color> _colors = [
    Color(0xFFFF8C00),
    Color(0xFFFFDD00),
    Color(0xFFFF3300),
    Color(0xFFFFBB00),
  ];

  _FireFlakesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in _flakes) {
      final t = (progress * f.speed + f.yStart) % 1.0;
      // rise from bottom 80% up and fade
      final y = size.height * (1.0 - t * 0.85);
      final x = f.xFrac * size.width + sin(progress * 2 * pi + f.phase) * size.width * 0.03 + t * f.drift * size.width;
      final opacity = (sin(t * pi)).clamp(0.0, 0.85) as double;
      final r = f.size * (1.0 - t * 0.6);

      if (r < 0.5 || opacity < 0.05) continue;

      final color = _colors[f.colorIdx].withOpacity(opacity);

      // glow halo
      canvas.drawCircle(Offset(x, y), r * 2.2, Paint()
        ..color = color.withOpacity(opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // solid core
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FireFlakesPainter old) => old.progress != progress;
}

class _FireFlake {
  final double xFrac, yStart, speed, size, drift, phase;
  final int colorIdx;
  const _FireFlake({
    required this.xFrac,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.drift,
    required this.phase,
    required this.colorIdx,
  });
}