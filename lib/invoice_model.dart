// lib/invoice_model.dart

class Invoice {
  // Key A: issuer / merchant tax ID.
  // Example: A:123456789
  final String merchantNif;

  // Key B: buyer / customer tax ID (optional).
  // Example: B:999999990
  final String clientNif;

  // Key C: buyer / customer country (optional).
  // Example: C:PT
  final String clientCountry;

  // Key D: document type (e.g. FT - invoice, FS - simplified invoice).
  // Example: D:FT
  final String documentType;

  // Key E: document status (e.g. N - normal, C - cancelled).
  // Example: E:N
  final String documentStatus;

  // Key F: document issue date.
  // Example: F:20191231
  final DateTime date;

  // Key G: unique document ID.
  // Example: G:FT AB2019/0035
  final String documentId;

  // Key H: ATCUD (unique document code).
  // Example: H:CSDF7T5H0035
  final String atcud;

  // Key N: total VAT and stamp duty.
  // N:64000.02
  final double vatAmount;

  // Key O: document total including taxes.
  // Example: O:513600.58
  final double totalAmount;

  // Key Q: 4-character hash.
  // Example: Q:kLp0
  final String docHash;

  // Key S: other information.
  final String controlInfo;

  Invoice({
    required this.merchantNif,
    required this.clientNif,
    required this.clientCountry,
    required this.documentType,
    required this.documentStatus,
    required this.date,
    required this.documentId,
    required this.atcud,
    required this.vatAmount,
    required this.totalAmount,
    required this.docHash,
    required this.controlInfo,
  });

  // Keep copyWith focused on updating the combined DateTime value.
  Invoice copyWith({DateTime? date}) {
    return Invoice(
      merchantNif: merchantNif,
      clientNif: clientNif,
      clientCountry: clientCountry,
      documentType: documentType,
      documentStatus: documentStatus,
      date: date ?? this.date,
      documentId: documentId,
      atcud: atcud,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      docHash: docHash,
      controlInfo: controlInfo,
    );
  }

  // Create an invoice from a QR code string.
  factory Invoice.fromQrCodeString(String qrCode) {
    final Map<String, String> dataMap = {};

    // The Portuguese tax authority's QR code separates fields with '*'.
    final parts = qrCode.split('*');
    for (var part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length >= 2) {
        // Use the first element as the key and join the remainder if the value contains ':'.
        dataMap[keyValue[0]] = keyValue.sublist(1).join(':');
      }
    }

    final String merchantNif = dataMap['A'] ?? 'N/A';
    final String clientNif = dataMap['B'] ?? 'N/A';
    final String clientCountry = dataMap['C'] ?? 'N/A';
    final String documentType = dataMap['D'] ?? 'Invoice';
    final String documentStatus = dataMap['E'] ?? 'N/A';

    final String rawDate = (dataMap['F'] ?? '').trim();
    final DateTime dateNow = DateTime.now();
    DateTime finalDate = dateNow;

    if (rawDate.length == 8) {
      final String year = rawDate.substring(0, 4);
      final String month = rawDate.substring(4, 6);
      final String day = rawDate.substring(6, 8);

      // Rebuild the ISO (YYYY-MM-DD) date accepted by tryParse.
      final DateTime? parsedDate = DateTime.tryParse('$year-$month-$day');
      if (parsedDate != null) {
        finalDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          dateNow.hour,
          dateNow.minute,
        );
      }
    }

    final String documentId = dataMap['G'] ?? '';
    final String atcud = dataMap['H'] ?? '';

    final double vatAmount =
        double.tryParse((dataMap['N'] ?? '0.0').trim()) ?? 0.0;
    final double totalAmount =
        double.tryParse((dataMap['O'] ?? '0.0').trim()) ?? 0.0;

    final String docHash = dataMap['Q'] ?? '';
    final String controlInfo = dataMap['S'] ?? '';

    return Invoice(
      merchantNif: merchantNif,
      clientNif: clientNif,
      clientCountry: clientCountry,
      documentType: documentType,
      documentStatus: documentStatus,
      date: finalDate,
      documentId: documentId,
      atcud: atcud,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      docHash: docHash,
      controlInfo: controlInfo,
    );
  }

  @override
  String toString() {
    return 'Tax ID: $merchantNif\n'
        'Type: $documentType\n'
        'Document: $documentId\n'
        'ATCUD: $atcud\n'
        'Amount: ${totalAmount.toStringAsFixed(2)}€ (VAT: ${vatAmount.toStringAsFixed(2)}€)\n'
        'Hash: $docHash\n'
        '${controlInfo.isNotEmpty ? "Control: $controlInfo" : ""}';
  }
}
