import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen camera screen with a focused cropping overlay.
/// Returns the captured image file path when the user takes a photo.
class ScanQuoteCameraScreen extends StatefulWidget {
  const ScanQuoteCameraScreen({super.key});

  @override
  State<ScanQuoteCameraScreen> createState() => _ScanQuoteCameraScreenState();
}

class _ScanQuoteCameraScreenState extends State<ScanQuoteCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Flash mode
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras found on this device.';
        });
        return;
      }

      // Use the back camera
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _toggleFlash() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch;
      } else {
        _flashMode = FlashMode.off;
      }
    });
    _controller?.setFlashMode(_flashMode);
  }

  Future<void> _captureImage() async {
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);

    try {
      final file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    if (_hasError) {
      final padH = (32 * scale).clamp(24.0, 32.0);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padH),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Color(0xFFD97A73), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD97A73)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview — fills the screen
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Semi-transparent overlay with clear center (crop area)
          Positioned.fill(
            child: CustomPaint(
              painter: _CropOverlayPainter(cropRect: _getCropRect(context)),
            ),
          ),

          // Crop border
          Positioned.fill(
            child: Center(
              child: Container(
                width: _getCropRect(context).width,
                height: _getCropRect(context).height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                _buildCircleButton(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
                // Title
                const Text(
                  'Scan Quote',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                // Flash toggle
                _buildCircleButton(
                  icon:
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),

          // Instruction text
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: const Text(
              'Position the quote within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),

          // Bottom capture button
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: Center(
              child: GestureDetector(
                onTap: _isCapturing ? null : _captureImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCapturing ? Colors.grey : Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 4,
                    ),
                  ),
                  child:
                      _isCapturing
                          ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                          : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black87,
                            size: 32,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect _getCropRect(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cropWidth = screenWidth - 48;
    final cropHeight = cropWidth * 0.65; // landscape-ish ratio for text
    final left = (screenWidth - cropWidth) / 2;
    final top = (screenHeight - cropHeight) / 2 - 40;
    return Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Paints the dark overlay with a transparent crop window
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.55)
          ..style = PaintingStyle.fill;

    // Draw overlay with hole
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(cropRect, const Radius.circular(12)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      cropRect != oldDelegate.cropRect;
}
