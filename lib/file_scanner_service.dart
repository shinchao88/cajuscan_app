// lib/file_scanner_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;

/// Processes files and extracts QR codes.
class FileScannerService {
  /// Selects and scans a file, regardless of its format.
  /// Returns the invoice string if valid (starts with A:), 'NOT_FOUND' if no
  /// valid code is found, or null if the user cancels.
  Future<String?> selectAndScan(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('==> Starting selectAndScan');
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) {
      if (kDebugMode) {
        debugPrint('==> Selection cancelled by user');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('==> Selected file: ${result.files.single.path}');
    }

    // Show visual feedback.
    if (context.mounted) _showLoading(context);

    // Allow the circular progress indicator to appear.
    await Future.delayed(const Duration(milliseconds: 150));

    final filePath = result.files.single.path!;
    final extension = result.files.single.extension?.toLowerCase();

    try {
      String? qrData;

      // Select the processing method based on the file extension.
      if (extension == 'pdf') {
        if (kDebugMode) {
          debugPrint('==> Processing PDF: $filePath');
        }
        qrData = await _scanPdf(filePath);
      } else {
        if (kDebugMode) {
          debugPrint('==> Processing image: $filePath');
        }
        qrData = await _scanImage(filePath);
      }

      if (kDebugMode) {
        debugPrint('==> Final scan result: $qrData');
      }

      if (context.mounted) Navigator.of(context).pop();

      // Validate the scanned content.
      if (qrData != null && qrData.startsWith('A:')) {
        return qrData;
      }

      if (kDebugMode) {
        debugPrint('==> Ignoring QR code with invalid format: $qrData');
      }
      return 'NOT_FOUND';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('==> FileScannerService error: $e');
      }
      if (context.mounted) Navigator.of(context).pop();
      return 'NOT_FOUND';
    }
  }

  /// Scan an image at multiple resolutions using an isolate.
  Future<String?> _scanImage(String path) async {
    final Uint8List fileBytes = await File(path).readAsBytes();

    return await compute(_processImageDynamicIsolate, fileBytes);
  }

  /// Scan a PDF at multiple scales using an isolate for image processing.
  Future<String?> _scanPdf(String path) async {
    final document = await PdfDocument.openFile(path);

    // Scan up to five pages to limit processing time and memory usage.
    final totalPages = document.pagesCount;
    final pagesToScan = totalPages > 5 ? 5 : totalPages;

    // Render PDF pages at multiple scales.
    // 1.5 to 2.0: ideal for clean digital PDFs.
    // 3.0: balanced.
    // 5.0: needed for very dense QR codes.
    final scales = [1.5, 2.5, 4.0, 5.0];

    for (var i = 1; i <= pagesToScan; i++) {
      if (kDebugMode) {
        debugPrint('==> Scanning page $i of $totalPages');
      }
      final page = await document.getPage(i);

      for (var scale in scales) {
        if (kDebugMode) {
          debugPrint('==> Trying scale $scale on page $i');
        }

        final pageImage = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          quality: 100,
        );

        if (pageImage != null) {
          // Process each intensive render in an isolate.
          final result = await compute(
            _processSingleImageIsolate,
            pageImage.bytes,
          );

          // Stop scanning the PDF as soon as an invoice QR code is found.
          if (result != null && result.startsWith('A:')) {
            if (kDebugMode) {
              debugPrint(
                '==> QR code found on page $i at scale $scale',
              );
            }
            await page.close();
            await document.close();
            return result;
          }
        }
      }
      await page.close();
    }

    await document.close();
    return null;
  }

  /// Decode an image using luminance to improve QR code detection.
  static String? _decodeWithLuminance(img.Image image) {
    final luminanceImage = image.convert(numChannels: 1);
    final result = zx.readBarcode(
      luminanceImage.toUint8List(),
      DecodeParams(
        format: Format.qrCode,
        width: luminanceImage.width,
        height: luminanceImage.height,
      ),
    );
    return (result.isValid && result.text != null) ? result.text : null;
  }

  /// Process multiple resolutions of a gallery image on a separate thread.
  static String? _processImageDynamicIsolate(Uint8List bytes) {
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    final imageBase = img.bakeOrientation(originalImage);
    final targetWidths = [800, 1200, 1600];

    for (var width in targetWidths) {
      img.Image resized = (imageBase.width > width)
          ? img.copyResize(imageBase, width: width)
          : imageBase;

      final text = _decodeWithLuminance(resized);

      // If the QR code is not an invoice, keep trying other resolutions.
      if (text != null && text.startsWith('A:')) return text;

      if (imageBase.width <= width) break;
    }
    return null;
  }

  /// Process one image (a PDF render) on a separate thread.
  static String? _processSingleImageIsolate(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;
    final text = _decodeWithLuminance(image);

    return (text != null && text.startsWith('A:')) ? text : null;
  }

  /// Show a modal loading indicator while processing.
  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
