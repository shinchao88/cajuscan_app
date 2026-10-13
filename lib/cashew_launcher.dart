// lib/cashew_launcher.dart

import 'package:url_launcher/url_launcher.dart';
import 'invoice_model.dart';
import 'settings_service.dart';

class CashewLauncher {
  // Use the settings service to read user preferences.
  final SettingsService _settingsService = SettingsService();

  Future<void> launchCashew({
    required Invoice invoice,
    required String category,
    String? subcategory,
    String? account,
    String? title,
  }) async {
    // Check whether the user wants to confirm in Cashew.
    final bool useConfirmationRoute = await _settingsService
        .getConfirmOnCashew();
    final String endpoint = useConfirmationRoute
        ? 'addTransactionRoute'
        : 'addTransaction';

    // Check whether the user wants to include full tax metadata in the notes.
    final bool sendFiscalInfo = await _settingsService.getSendFiscalInfo();

    // Build the query parameters, ensuring the amount is negative.
    final transactionTitle = title ?? 'Expense ${invoice.merchantNif}';

    final String notasFinais =
        'Invoice imported via QR code\n'
        '${sendFiscalInfo ? invoice.toString() : 'Tax ID: ${invoice.merchantNif}'}';

    final Map<String, String> queryParameters = {
      'amount': (-invoice.totalAmount).toString(),
      'date': invoice.date.toIso8601String(),
      'title': transactionTitle,
      'notes': notasFinais,
    };

    // Add parameters only when they are not empty.
    if (category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      queryParameters['subcategory'] = subcategory;
    }

    // Include the account in the parameters read by Cashew.
    if (account != null && account.isNotEmpty) {
      queryParameters['account'] = account;
    }

    // Build the final URI to open Cashew with the required parameters.
    final uri = Uri(
      scheme: 'https',
      host: 'cashewapp.web.app',
      path: endpoint,
      queryParameters: queryParameters,
    );

    // Open the URL or throw a clear exception if it fails.
    if (await canLaunchUrl(uri)) {
      // Open in the external app instead of a web view.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception(
        'Could not open Cashew. Make sure the app is installed and configured to open links.',
      );
    }
  }
}
