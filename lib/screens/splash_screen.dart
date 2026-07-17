import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final String appName;
  final String tagline;
  final List<String> taskLabels;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.appName = 'TaskFlow',
    this.tagline = 'Plan less. Flow more.',
    this.taskLabels = const [
      'Plan your day',
      'Focus on what matters',
      'Get it done',
    ],
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _Particle {
  final double dx, dy, size, speed, phase;
  _Particle(this.dx, this.dy, this.size, this.speed, this.phase);
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2500);

  late final AnimationController _seq;
  late final AnimationController _ambient;
  bool _navigated = false;

  late final List<_Particle> _particles;

  static const double _rowStagger = 0.075;
  static const double _appearStart = 0.02;
  static const double _appearDur = 0.20;
  static const double _checkStart = 0.20;
  static const double _checkDur = 0.16;
  static const double _exitStart = 0.53;
  static const double _exitEnd = 0.66;
  static const double _logoStart = 0.58;
  static const double _logoEnd = 0.78;
  static const double _wordStart = 0.62;
  static const double _letterStep = 0.018;
  static const double _letterDur = 0.11;
  static const double _tagStart = 0.87;
  static const double _tagEnd = 1.0;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(16, (i) {
      final rnd = Random(i * 91 + 7);
      return _Particle(
        rnd.nextDouble(),
        rnd.nextDouble(),
        3 + rnd.nextDouble() * 4,
        0.4 + rnd.nextDouble() * 0.6,
        rnd.nextDouble() * 2 * pi,
      );
    });

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _seq = AnimationController(vsync: this, duration: _totalDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      })
      ..forward();
  }

  @override
  void dispose() {
    _seq.dispose();
    _ambient.dispose();
    super.dispose();
  }

  double _t(double start, double end, double value, {Curve curve = Curves.linear}) {
    if (end <= start) return value >= end ? 1 : 0;
    final raw = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  void _goNext() async {
    if (_navigated) return;
    _navigated = true;
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([_seq, _ambient]),
        builder: (context, _) {
          final t = _seq.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(theme, primary),
              ..._buildParticles(primary),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 220,
                        width: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildChecklist(theme, primary, t),
                            _buildLogoMark(primary, t),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildWordmark(theme, t),
                      const SizedBox(height: 10),
                      _buildTagline(theme, t),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(ThemeData theme, Color primary) {
    final a = _ambient.value;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1 + sin(a * 2 * pi) * 0.3, -1),
          end: Alignment(1, 1 + cos(a * 2 * pi) * 0.3),
          colors: [
            primary.withValues(alpha: 0.14),
            theme.colorScheme.surface,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles(Color primary) {
    final a = _ambient.value;
    return _particles.map((p) {
      final y = (p.dy - a * p.speed) % 1.0;
      final wrappedY = y < 0 ? y + 1 : y;
      final opacity = (0.10 + 0.18 * (0.5 + 0.5 * sin(2 * pi * (a + p.phase))))
          .clamp(0.0, 0.28);
      return Align(
        alignment: Alignment(p.dx * 2 - 1, wrappedY * 2 - 1),
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: opacity),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildChecklist(ThemeData theme, Color primary, double t) {
    final exit = _t(_exitStart, _exitEnd, t);
    final exitScale = 1 - (0.3 * exit);
    final exitOpacity = 1 - exit;

    if (exitOpacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: exitOpacity,
      child: Transform.scale(
        scale: exitScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(widget.taskLabels.length, (i) {
            final appearStart = _appearStart + i * _rowStagger;
            final appearEnd = appearStart + _appearDur;
            final appear = _t(appearStart, appearEnd, t, curve: Curves.easeOutCubic);

            final checkStart = _checkStart + i * _rowStagger;
            final checkEnd = checkStart + _checkDur;
            final check = _t(checkStart, checkEnd, t);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Opacity(
                opacity: appear,
                child: Transform.translate(
                  offset: Offset((1 - appear) * -28, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CheckCircle(progress: check, color: primary),
                      const SizedBox(width: 12),
                      Container(
                        height: 10,
                        width: 130 - (i * 18),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                            check,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogoMark(Color primary, double t) {
    final v = _t(_logoStart, _logoEnd, t, curve: Curves.elasticOut);
    if (v <= 0) return const SizedBox.shrink();
    final glow = 0.4 + 0.25 * (0.5 + 0.5 * sin(_ambient.value * 2 * pi));

    return Transform.scale(
      scale: v,
      child: Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, Color.lerp(primary, Colors.black, 0.3)!],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: glow),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark(ThemeData theme, double t) {
    final chars = widget.appName.characters.toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(chars.length, (i) {
        final start = _wordStart + i * _letterStep;
        final end = start + _letterDur;
        final v = _t(start, end, t, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 14),
            child: Text(
              chars[i],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTagline(ThemeData theme, double t) {
    final v = _t(_tagStart, _tagEnd, t, curve: Curves.easeOut);
    return Opacity(
      opacity: v,
      child: Text(
        widget.tagline,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final double progress;
  final Color color;

  const _CheckCircle({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(Colors.transparent, color, progress),
        border: Border.all(
          color: Color.lerp(color.withValues(alpha: 0.5), color, progress)!,
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: _CheckPainter(progress: progress, color: Colors.white),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.75)
      ..lineTo(size.width * 0.80, size.height * 0.28);

    final metrics = path.computeMetrics().toList();
    final totalLength =
        metrics.fold<double>(0, (sum, m) => sum + m.length);
    double remaining = totalLength * progress;

    final extracted = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final len = min(metric.length, remaining);
      extracted.addPath(metric.extractPath(0, len), Offset.zero);
      remaining -= len;
    }

    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
