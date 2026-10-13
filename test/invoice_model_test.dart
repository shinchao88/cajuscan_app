import 'package:flutter_test/flutter_test.dart';

import 'package:cajuscan_app/invoice_model.dart';

void main() {
  test('parses invoice details from the Portuguese tax authority QR code', () {
    final invoice = Invoice.fromQrCodeString(
      'A:123456789*B:987654321*C:PT*D:FT*E:N*F:20261013*'
      'G:FT AB2026/1*H:CSDF7T5H0035*N:23.00*O:123.00*Q:abcd*S:Test',
    );

    expect(invoice.merchantNif, '123456789');
    expect(invoice.clientNif, '987654321');
    expect(invoice.documentType, 'FT');
    expect(invoice.documentId, 'FT AB2026/1');
    expect(invoice.atcud, 'CSDF7T5H0035');
    expect(invoice.vatAmount, 23.0);
    expect(invoice.totalAmount, 123.0);
    expect(invoice.date.year, 2026);
    expect(invoice.date.month, 10);
    expect(invoice.date.day, 13);
  });
}
