// lib/scanner_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'invoice_model.dart';
import 'confirmation_page.dart';
import 'settings_service.dart';
import 'category_management_service.dart';
import 'account_management_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  final SettingsService _settingsService = SettingsService();

  final CategoryManagementService _categoryService =
      CategoryManagementService();
  final AccountManagementService _accountService = AccountManagementService();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Configure the animated red line.
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Keep the scan line away from the edges to prevent flickering.
    _animation = Tween<double>(begin: 0, end: 0.99).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDetection(Code result) async {
    if (_isProcessing || result.text == null) return;

    final String code = result.text!;

    // Validate Portuguese invoices (ATCUD/QR).
    if (code.contains("A:") && code.contains("F:")) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final invoice = Invoice.fromQrCodeString(code);

        // Check the user's preference.
        final isContinuous = await _settingsService.getContinuousScan();
        final categories = await _categoryService.getCategories();
        final accounts = await _accountService.getAccounts();

        if (!mounted) return;

        if (isContinuous) {
          // Keep the scanner on the stack so it can reset when returning.
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(
                invoice: invoice,
                categories: categories,
                accounts: accounts,
              ),
            ),
          );

          if (mounted) {
            setState(() => _isProcessing = false);
          }
        } else {
          // Replace the scanner with the confirmation page.
          // Returning from confirmation takes the user back home.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(
                invoice: invoice,
                categories: categories,
                accounts: accounts,
              ),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error reading QR code: $e');
        }
        // Wait two seconds before allowing another attempt after an error.
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set the scan window size to 75% of the screen width.
    final scanWindowSize = screenWidth * 0.75;

    // Center the scan window for the overlay and scanner crop.
    final scanWindowRect = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Point at the QR code'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: ZXing scanner.
          ReaderWidget(
            onScan: _handleDetection,

            // Disable the native decorations.
            showFlashlight: false,
            showGallery: false,
            showToggleCamera: false,

            // Disabling zoom provides a small performance improvement.
            allowPinchZoom: false,

            // Process 75% of the available width and height.
            cropPercent: 0.75,

            // Use our own overlay instead of ZXing's default scan window.
            showScannerOverlay: false,

            // Add a delay between scans to prevent duplicate reads.
            scanDelay: const Duration(milliseconds: 500),
          ),

          // Layer 2: overlay with a darkened background and a transparent cutout.
          RepaintBoundary(
            child: CustomPaint(painter: OverlayPainter(scanWindowRect)),
          ),

          // Camada 3: Borda e linha animada
          Center(
            child: SizedBox(
              height: scanWindowSize,
              width: scanWindowSize,
              child: Stack(
                children: [
                  // Draw the inverted rounded corners.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: ScannerBorderPainter()),
                    ),
                  ),
                  // Animated red line.
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanWindowSize * _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.0,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.6),
                                blurRadius: 8.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Layer 4: Instructions.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Text(
                'Place the QR code inside the visible area',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ),

          // Layer 5: processing indicator.
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Paint the overlay with a transparent cutout.
class OverlayPainter extends CustomPainter {
  final Rect scanWindow;
  OverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    // 1. Create the full background.
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Create the cutout path with inverted corners.
    const radius = 16.0;
    final holePath = Path();

    // Draw the cutout outline manually to support inverted arcs.
    holePath.moveTo(scanWindow.left, scanWindow.top + radius);

    // Top left (inverted).
    holePath.arcToPoint(
      Offset(scanWindow.left + radius, scanWindow.top),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.right - radius, scanWindow.top);

    // Top right (inverted).
    holePath.arcToPoint(
      Offset(scanWindow.right, scanWindow.top + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.right, scanWindow.bottom - radius);

    // Bottom right (inverted).
    holePath.arcToPoint(
      Offset(scanWindow.right - radius, scanWindow.bottom),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.lineTo(scanWindow.left + radius, scanWindow.bottom);

    // Bottom left (inverted).
    holePath.arcToPoint(
      Offset(scanWindow.left, scanWindow.bottom - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    holePath.close();

    // 3. Subtract the cutout from the background.
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, holePath),
      backgroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

// --- Draw the white frame corners ---
class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    const cornerLength = 30.0;
    const radius = 16.0; // Radius of the inverted curve.

    final path = Path();

    // Top left.
    path.moveTo(0, cornerLength);
    path.lineTo(0, radius);
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
      clockwise: false, // Curve outward (inverted).
    );
    path.lineTo(cornerLength, 0);

    // Top right.
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, cornerLength);

    // Bottom right.
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom left.
    path.moveTo(cornerLength, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
