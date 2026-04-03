import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A function that provides a full-screen screenshot as PNG bytes.
/// Used to capture WebView content (e.g. EPUB) that RepaintBoundary can't capture.
typedef ScreenshotProvider = Future<Uint8List?> Function();

/// Overlay that dims the screen and lets the user draw a lasso.
/// On finger-lift the bounding box is captured as a PNG and returned.
class CircleToSearchOverlay extends StatefulWidget {
  final GlobalKey readerBoundaryKey;
  final void Function(Uint8List imageBytes, Rect cropRect) onCaptured;
  final VoidCallback onDismiss;
  final bool isDarkMode;

  /// Optional: provide a custom screenshot function (e.g. WebView.takeScreenshot).
  /// When provided, this is used instead of RepaintBoundary.toImage().
  final ScreenshotProvider? screenshotProvider;

  const CircleToSearchOverlay({
    super.key,
    required this.readerBoundaryKey,
    required this.onCaptured,
    required this.onDismiss,
    required this.isDarkMode,
    this.screenshotProvider,
  });

  @override
  State<CircleToSearchOverlay> createState() => _CircleToSearchOverlayState();
}

enum _Phase { idle, drawing, captured }

class _CircleToSearchOverlayState extends State<CircleToSearchOverlay>
    with TickerProviderStateMixin {
  final List<Offset> _points = [];
  _Phase _phase = _Phase.idle;
  bool _isCapturing = false;
  Rect? _boundingRect;

  late final AnimationController _pulseCtrl;

  // Hint fade-out
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Hint fades out after 1.5 seconds
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _phase == _Phase.idle) {
        _hintCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  // ── Gesture handling ──

  void _onPanStart(DragStartDetails d) {
    _pulseCtrl.stop();
    setState(() {
      _points.clear();
      _boundingRect = null;
      _phase = _Phase.drawing;
      _points.add(d.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_phase != _Phase.drawing) return;
    setState(() => _points.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_phase != _Phase.drawing || _points.length < 8) {
      // Too few points → reset, let user try again
      setState(() {
        _points.clear();
        _phase = _Phase.idle;
      });
      return;
    }

    setState(() => _phase = _Phase.captured);

    // Bounding rect
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in _points) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
    const pad = 8.0;
    final rect = Rect.fromLTRB(
      max(0, minX - pad),
      max(0, minY - pad),
      maxX + pad,
      maxY + pad,
    );
    setState(() => _boundingRect = rect);
    _pulseCtrl.repeat(reverse: true);
    _captureAndCrop(rect);
  }

  // ── Screenshot + crop ──

  Future<void> _captureAndCrop(Rect cropRect) async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      // Use screenshotProvider if available (for WebView-based readers like EPUB)
      if (widget.screenshotProvider != null) {
        await _captureViaProvider(cropRect);
        return;
      }

      // Fallback: RepaintBoundary capture (works for Flutter-rendered widgets like PDF)
      await _captureViaBoundary(cropRect);
    } catch (e) {
      debugPrint('❌ Circle-to-search capture error: $e');
      widget.onDismiss();
    } finally {
      _isCapturing = false;
    }
  }

  /// Capture using the screenshotProvider (WebView.takeScreenshot)
  Future<void> _captureViaProvider(Rect cropRect) async {
    final fullPng = await widget.screenshotProvider!();
    if (fullPng == null || fullPng.isEmpty) {
      debugPrint('❌ screenshotProvider returned null/empty');
      widget.onDismiss();
      return;
    }

    // Decode the full screenshot to get dimensions
    final codec = await ui.instantiateImageCodec(fullPng);
    final frame = await codec.getNextFrame();
    final fullImage = frame.image;

    // The overlay and the reader share the same visible area, so
    // overlay-local coords map 1:1 to the screenshot after scaling.
    final overlayBox = context.findRenderObject() as RenderBox;
    final overlaySize = overlayBox.size;

    // Scale from overlay logical coords → screenshot pixel coords
    final scaleX = fullImage.width / overlaySize.width;
    final scaleY = fullImage.height / overlaySize.height;

    final scaled = Rect.fromLTRB(
      (cropRect.left * scaleX).clamp(0, fullImage.width.toDouble()),
      (cropRect.top * scaleY).clamp(0, fullImage.height.toDouble()),
      (cropRect.right * scaleX).clamp(0, fullImage.width.toDouble()),
      (cropRect.bottom * scaleY).clamp(0, fullImage.height.toDouble()),
    );

    if (scaled.width < 10 || scaled.height < 10) {
      fullImage.dispose();
      widget.onDismiss();
      return;
    }

    // Crop
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      fullImage,
      scaled,
      Rect.fromLTWH(0, 0, scaled.width, scaled.height),
      Paint(),
    );
    final pic = recorder.endRecording();
    final cropped = await pic.toImage(
      scaled.width.toInt(),
      scaled.height.toInt(),
    );

    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    fullImage.dispose();
    cropped.dispose();

    if (byteData == null) {
      widget.onDismiss();
      return;
    }

    widget.onCaptured(byteData.buffer.asUint8List(), cropRect);
  }

  /// Capture using RepaintBoundary (for Flutter-rendered content like PDF)
  Future<void> _captureViaBoundary(Rect cropRect) async {
    final boundary =
        widget.readerBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      widget.onDismiss();
      return;
    }

    final pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final fullImage = await boundary.toImage(pixelRatio: pixelRatio);

    // Map overlay-local crop → boundary-local
    final overlayBox = context.findRenderObject() as RenderBox;
    final boundaryBox = boundary as RenderBox;

    final gTL = overlayBox.localToGlobal(cropRect.topLeft);
    final lTL = boundaryBox.globalToLocal(gTL);
    final gBR = overlayBox.localToGlobal(cropRect.bottomRight);
    final lBR = boundaryBox.globalToLocal(gBR);

    final scaled = Rect.fromLTRB(
      (lTL.dx * pixelRatio).clamp(0, fullImage.width.toDouble()),
      (lTL.dy * pixelRatio).clamp(0, fullImage.height.toDouble()),
      (lBR.dx * pixelRatio).clamp(0, fullImage.width.toDouble()),
      (lBR.dy * pixelRatio).clamp(0, fullImage.height.toDouble()),
    );

    if (scaled.width < 10 || scaled.height < 10) {
      fullImage.dispose();
      widget.onDismiss();
      return;
    }

    // Crop
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      fullImage,
      scaled,
      Rect.fromLTWH(0, 0, scaled.width, scaled.height),
      Paint(),
    );
    final pic = recorder.endRecording();
    final cropped = await pic.toImage(
      scaled.width.toInt(),
      scaled.height.toInt(),
    );

    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    fullImage.dispose();
    cropped.dispose();

    if (byteData == null) {
      widget.onDismiss();
      return;
    }

    widget.onCaptured(byteData.buffer.asUint8List(), cropRect);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final hintPadH = (24 * scale).clamp(16.0, 24.0);
    final hintPadV = (14 * scale).clamp(11.0, 14.0);
    final hintFontSize = (15 * scale).clamp(12.0, 15.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // receive ALL touches
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onDismiss,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Dim background (always visible) ──
          Container(
            color: Colors.black.withValues(
              alpha: widget.isDarkMode ? 0.55 : 0.40,
            ),
          ),

          // ── Lasso + bounding box drawing ──
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _LassoPainter(
                  points: _points,
                  boundingRect: _boundingRect,
                  pulseValue: _pulseCtrl.value,
                  phase: _phase,
                ),
                size: Size.infinite,
              );
            },
          ),

          // ── Hint label (fades out after 1.5s) ──
          if (_phase == _Phase.idle)
            FadeTransition(
              opacity: _hintOpacity,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hintPadH,
                    vertical: hintPadV,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'Draw around content to search',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: hintFontSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF-UI-Display',
                      letterSpacing: 0.2,
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

// ──────────────────────────────────────────────
// Painter: lasso stroke + bounding box highlight
// ──────────────────────────────────────────────

class _LassoPainter extends CustomPainter {
  final List<Offset> points;
  final Rect? boundingRect;
  final double pulseValue;
  final _Phase phase;

  _LassoPainter({
    required this.points,
    required this.boundingRect,
    required this.pulseValue,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Draw bounding box when captured ──
    if (boundingRect != null && phase == _Phase.captured) {
      // Clear the inside of the bounding box (punch through the dim)
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
      // Fill everything transparent
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.transparent,
      );
      // Punch out the selected area (make it brighter)
      canvas.drawRRect(
        RRect.fromRectAndRadius(boundingRect!, const Radius.circular(8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..blendMode = BlendMode.clear,
      );
      canvas.restore();

      // Glow border
      final glow = 0.5 + pulseValue * 0.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(boundingRect!, const Radius.circular(8)),
        Paint()
          ..color = _glowColor.withValues(alpha: glow * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Crisp border
      canvas.drawRRect(
        RRect.fromRectAndRadius(boundingRect!, const Radius.circular(8)),
        Paint()
          ..color = _lineColor.withValues(alpha: 0.6 + pulseValue * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // ── Draw the lasso path ──
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth with quadratic bezier
      if (i < points.length - 1) {
        final mid = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Glow layer
    canvas.drawPath(
      path,
      Paint()
        ..color = _glowColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Main stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = _lineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  static const _lineColor = Color(0xFFD97757);
  static const _glowColor = Color(0x88D97757);

  @override
  bool shouldRepaint(covariant _LassoPainter old) {
    return old.points.length != points.length ||
        old.boundingRect != boundingRect ||
        old.pulseValue != pulseValue ||
        old.phase != phase;
  }
}
