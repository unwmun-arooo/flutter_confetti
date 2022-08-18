import 'dart:math';

import 'package:confetti/src/particle.dart';
import 'package:flutter/material.dart';

import 'confetti_controller.dart';
import 'enums/blast_directionality.dart';
import 'enums/confetti_controller_state.dart';

class TextConfettiWidget extends StatefulWidget {
  const TextConfettiWidget({
    Key? key,
    required this.confettiController,
    this.emissionFrequency = 0.02,
    this.numberOfParticles = 10,
    this.maxBlastForce = 20,
    this.minBlastForce = 5,
    this.blastDirectionality = BlastDirectionality.directional,
    this.blastDirection = pi,
    this.gravity = 0.2,
    this.shouldLoop = false,
    this.displayTarget = false,
    this.colors,
    this.minimumSize = const Size(20, 10),
    this.maximumSize = const Size(30, 15),
    this.particleDrag = 0.05,
    this.canvas,
    this.child,
    required this.text,
    this.textStyle = const TextStyle(fontSize: 10),
    this.textDirection = TextDirection.ltr,
  })  : assert(
          emissionFrequency >= 0 &&
              emissionFrequency <= 1 &&
              numberOfParticles > 0 &&
              maxBlastForce > 0 &&
              minBlastForce > 0 &&
              maxBlastForce > minBlastForce,
        ),
        assert(gravity >= 0 && gravity <= 1,
            '`gravity` needs to be between 0 and 1'),
        super(key: key);

  /// Controls the animation.
  final ConfettiController confettiController;

  /// The [maxBlastForce] and [minBlastForce] will determine the maximum and
  /// minimum blast force applied to  a particle within it's first 5 frames of
  /// life. The default [maxBlastForce] is set to `20`
  final double maxBlastForce;

  /// The [maxBlastForce] and [minBlastForce] will determine the maximum and
  /// minimum blast force applied to a particle within it's first 5 frames of
  /// life. The default [minBlastForce] is set to `5`
  final double minBlastForce;

  /// The [blastDirectionality] is an enum that takes one of two
  /// values - directional or explosive.
  ///
  /// The default is set to directional
  final BlastDirectionality blastDirectionality;

  /// The [blastDirection] is a radial value to determine the direction of the
  /// particle emission.
  ///
  /// The default is set to `PI` (180 degrees).
  /// A value of `PI` will emit to the left of the canvas/screen.
  final double blastDirection;

  /// The [gravity] is the speed at which the confetti will fall.
  /// The higher the [gravity] the faster it will fall.
  ///
  /// It can be set to a value between `0` and `1`
  /// Default value is `0.1`
  final double gravity;

  /// The [emissionFrequency] should be a value between 0 and 1.
  /// The higher the value the higher the likelihood that particles will be
  /// emitted on a single frame.
  ///
  /// Default is set to `0.02` (2% chance).
  final double emissionFrequency;

  /// The [numberOfParticles] to be emitted per emission.
  ///
  /// Default is set to `10`.
  final int numberOfParticles;

  /// The [shouldLoop] attribute determines if the animation will
  /// reset once it completes, resulting in a continuous particle emission.
  final bool shouldLoop;

  /// The [displayTarget] attribute determines if a crosshair will be displayed
  /// to show the location of the particle emitter.
  final bool displayTarget;

  /// List of Colors to iterate over - if null then random values will be chosen
  final List<Color>? colors;

  /// An optional parameter to set the minimum size potential size for
  /// the confetti.
  ///
  /// Must be smaller than the [maximumSize] attribute.
  final Size minimumSize;

  /// An optional parameter to set the maximum potential size for the confetti.
  /// Must be bigger than the [minimumSize] attribute.
  final Size maximumSize;

  /// An optional parameter to specify drag force, effecting the movement
  /// of the confetti.
  ///
  /// Using `1.0` will give no drag at all, while, for example, using `0.1`
  /// will give a lot of drag. Default is set to `0.05`.
  final double particleDrag;

  /// An optional parameter to specify the area size where the confetti will
  /// be thrown.
  ///
  /// By default this is set to then screen size.
  final Size? canvas;

  /// Child widget to display
  final Widget? child;

  /// 보여줄 문자
  final String text;

  /// 문자의 스타일
  final TextStyle textStyle;

  /// 문자 방향
  final TextDirection? textDirection;

  @override
  _ConfettiWidgetState createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<TextConfettiWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _particleSystemKey = GlobalKey();

  late AnimationController _animController;
  late Animation<double> _animation;
  late ParticleSystem _particleSystem;

  /// Keeps track of emition position on screen layout changes
  Offset? _emitterPosition;

  /// Keeps track of the screen size on layout changes
  /// Controls the sizing restrictions for when confetti should be vissible
  Size _screenSize = const Size(0, 0);

  @override
  void initState() {
    super.initState();
    widget.confettiController.addListener(_handleChange);

    _particleSystem = ParticleSystem(
        emissionFrequency: widget.emissionFrequency,
        numberOfParticles: widget.numberOfParticles,
        maxBlastForce: widget.maxBlastForce,
        minBlastForce: widget.minBlastForce,
        gravity: widget.gravity,
        blastDirection: widget.blastDirection,
        blastDirectionality: widget.blastDirectionality,
        colors: widget.colors,
        minimumSize: widget.minimumSize,
        maximumSize: widget.maximumSize,
        particleDrag: widget.particleDrag);

    _particleSystem.addListener(_particleSystemListener);

    _initAnimation();
  }

  void _initAnimation() {
    _animController = AnimationController(
        vsync: this, duration: widget.confettiController.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animController);
    _animation
      ..addListener(_animationListener)
      ..addStatusListener(_animationStatusListener);

    if (widget.confettiController.state == ConfettiControllerState.playing) {
      _startAnimation();
      _startEmission();
    }
  }

  void _handleChange() {
    if (widget.confettiController.state == ConfettiControllerState.playing) {
      _startAnimation();
      _startEmission();
    } else if (widget.confettiController.state ==
        ConfettiControllerState.stopped) {
      _stopEmission();
    }
  }

  void _animationListener() {
    if (_particleSystem.particleSystemStatus == ParticleSystemStatus.finished) {
      _animController.stop();
      return;
    }
    _particleSystem.update();
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!widget.shouldLoop) {
        _stopEmission();
      }
      _continueAnimation();
    }
  }

  void _particleSystemListener() {
    if (_particleSystem.particleSystemStatus == ParticleSystemStatus.finished) {
      _stopAnimation();
    }
  }

  void _startEmission() {
    _particleSystem.startParticleEmission();
  }

  void _stopEmission() {
    if (_particleSystem.particleSystemStatus == ParticleSystemStatus.stopped) {
      return;
    }
    _particleSystem.stopParticleEmission();
  }

  void _startAnimation() {
    // Make sure widgets are built before setting screen size and position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setScreenSize();
        _setEmitterPosition();
        _animController.forward(from: 0);
      }
    });
  }

  void _stopAnimation() {
    _animController.stop();
    widget.confettiController.stop();
  }

  void _continueAnimation() {
    _animController.forward(from: 0);
  }

  void _setScreenSize() {
    _screenSize = _getScreenSize();
    _particleSystem.screenSize = _screenSize;
  }

  void _setEmitterPosition() {
    _emitterPosition = _getContainerPosition();
    _particleSystem.particleSystemPosition = _emitterPosition;
  }

  Offset _getContainerPosition() {
    final containerRenderBox =
        _particleSystemKey.currentContext!.findRenderObject() as RenderBox;
    return containerRenderBox.localToGlobal(Offset.zero);
  }

  Size _getScreenSize() {
    return widget.canvas ?? MediaQuery.of(context).size;
  }

  /// On layout change update the position of the emitter
  /// and the screen size.
  ///
  /// Only update the emitter if it has already been set, to avoid RenderObject
  /// issues.
  ///
  /// The emitter position is first set in the `addPostFrameCallback`
  /// in [initState].
  void _updatePositionAndSize() {
    if (_getScreenSize() != _screenSize) {
      _setScreenSize();
      if (_emitterPosition != null) {
        _setEmitterPosition();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _updatePositionAndSize();
    return RepaintBoundary(
      child: CustomPaint(
        key: _particleSystemKey,
        foregroundPainter: TextParticlePainter(
          _animController,
          particles: _particleSystem.particles,
          paintEmitterTarget: widget.displayTarget,
          text: widget.text,
          textStyle: widget.textStyle,
        ),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    widget.confettiController.stop();
    _animController.dispose();
    widget.confettiController.removeListener(_handleChange);
    _particleSystem.removeListener(_particleSystemListener);
    super.dispose();
  }
}

class TextParticlePainter extends CustomPainter {
  TextParticlePainter(Listenable? repaint,
      {required this.particles,
      bool paintEmitterTarget = true,
      Color emitterTargetColor = Colors.black,
      required String text,
      TextStyle textStyle = const TextStyle(fontSize: 10)})
      : _paintEmitterTarget = paintEmitterTarget,
        _emitterPaint = Paint()
          ..color = emitterTargetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
        _text = text,
        _textStyle = textStyle,
        super(repaint: repaint);

  final List<Particle> particles;

  final Paint _emitterPaint;
  final bool _paintEmitterTarget;
  final String _text;
  final TextStyle _textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (_paintEmitterTarget) {
      _paintEmitter(canvas);
    }
    _paintParticles(canvas, size);
  }

  // TODO: seperate this
  void _paintEmitter(Canvas canvas) {
    const radius = 10.0;
    canvas.drawCircle(Offset.zero, radius, _emitterPaint);
    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(0, radius)
      ..moveTo(-radius, 0)
      ..lineTo(radius, 0);
    canvas.drawPath(path, _emitterPaint);
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final rotationMatrix4 = Matrix4.identity()
        ..translate(particle.location.dx, particle.location.dy)
        ..rotateZ(particle.angleZ);

      final textSpan = TextSpan(text: _text, style: _textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      canvas.save();
      canvas.transform(rotationMatrix4.storage);
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
