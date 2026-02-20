import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';

class SimpleBarcodeScanner extends StatefulWidget {
  const SimpleBarcodeScanner({super.key});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppThemeColors.headerGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  case TorchState.unavailable:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _isScanned = true;
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Overlay to guide user
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppThemeColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Instructions text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Arahkan kamera ke barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

// Custom painter for scanner overlay
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutSizeVal = cutOutSize != 0.0 ? cutOutSize : width - 40.0;
    final cutOutBottomOffsetVal = cutOutBottomOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSizeVal / 2 + borderOffset,
      rect.top + height / 2 - cutOutSizeVal / 2 + borderOffset + cutOutBottomOffsetVal,
      cutOutSizeVal - borderWidth,
      cutOutSizeVal - borderWidth,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderPath = _getBorderPath(cutOutRect, borderRadius, borderLength);
    
    canvas.drawPath(borderPath, borderPaint);
    
  }
   
  Path _getBorderPath(Rect rect, double borderRadius, double borderLength) {
     final path = Path();
     // Top left
    path.moveTo(rect.left, rect.top + borderLength);
    path.lineTo(rect.left, rect.top + borderRadius);
    path.arcToPoint(
      Offset(rect.left + borderRadius, rect.top),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    path.lineTo(rect.left + borderLength, rect.top);

    // Top right
    path.moveTo(rect.right - borderLength, rect.top);
    path.lineTo(rect.right - borderRadius, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    path.lineTo(rect.right, rect.top + borderLength);

    // Bottom right
    path.moveTo(rect.right, rect.bottom - borderLength);
    path.lineTo(rect.right, rect.bottom - borderRadius);
    path.arcToPoint(
      Offset(rect.right - borderRadius, rect.bottom),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    path.lineTo(rect.right - borderLength, rect.bottom);

    // Bottom left
    path.moveTo(rect.left + borderLength, rect.bottom);
    path.lineTo(rect.left + borderRadius, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    path.lineTo(rect.left, rect.bottom - borderLength);

    return path;
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
