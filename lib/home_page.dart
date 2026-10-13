// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'scanner_page.dart';
import 'settings_page.dart';
import 'file_scanner_service.dart';
import 'confirmation_page.dart';
import 'invoice_model.dart';
import 'category_management_service.dart';
import 'account_management_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  final AccountManagementService _accountService = AccountManagementService();
  late StreamSubscription _intentSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentSubscription.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // The app was opened from a share while running in the background.
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedContent(files.first);
        }
      },
    );

    // The app was launched directly from a share (cold start).
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> files,
    ) {
      if (files.isNotEmpty) {
        _handleSharedContent(files.first);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  Future<void> _handleSharedContent(SharedMediaFile file) async {
    String? jsonString;

    if (file.type == SharedMediaType.text) {
      jsonString = file.path;
    } else if (file.type == SharedMediaType.file) {
      try {
        final f = await _readFile(file.path);
        jsonString = f;
      } catch (_) {
        _showError('Could not read the shared file.');
        return;
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      _showError('Shared content is empty or invalid.');
      return;
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      _showError('The shared content is not valid JSON.');
      return;
    }

    // Check whether the JSON contains any of the keys expected by Cashew.
    if (!data.containsKey('categories') && !data.containsKey('accounts')) {
      return;
    }

    Map<String, List<String>> categories = {};
    if (data.containsKey('categories') && data['categories'] is Map) {
      final rawCategories = data['categories'] as Map<String, dynamic>;
      categories = rawCategories.map((key, value) {
        final subs = (value as List<dynamic>).whereType<String>().toList();
        return MapEntry(key, subs);
      });
    }

    List<String> accounts = [];
    if (data.containsKey('accounts') && data['accounts'] is List) {
      final rawAccounts = data['accounts'] as List<dynamic>;
      accounts = rawAccounts.whereType<String>().toList();
    }

    if (categories.isEmpty && accounts.isEmpty) {
      _showError('The file contains no valid categories or accounts.');
      return;
    }

    if (!mounted) return;
    _showImportDialog(categories, accounts);
  }

  Future<String> _readFile(String path) async {
    return File(path).readAsString();
  }

  void _showImportDialog(
    Map<String, List<String>> categories,
    List<String> accounts,
  ) {
    // Build the dialog message based on the imported data.
    final List<String> infoLines = [];
    if (categories.isNotEmpty) {
      infoLines.add('${categories.length} categories');
    }
    if (accounts.isNotEmpty) infoLines.add('${accounts.length} accounts');
    final String contentMessage = infoLines.join(' and ');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import data'),
        content: Text(
          'Found $contentMessage.\n\n'
          'This will replace your current data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              await _categoryService.saveCategoriesAndAccounts(
                categories: categories,
                accounts: accounts,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data imported successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleFileImport(BuildContext context) async {
    final fileScanner = FileScannerService();
    final qrData = await fileScanner.selectAndScan(context);

    if (!context.mounted) return;
    if (qrData == null) return;

    if (qrData == 'NOT_FOUND') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid QR code was found in the file.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final invoice = Invoice.fromQrCodeString(qrData);
      final categories = await _categoryService.getCategories();
      final accounts = await _accountService.getAccounts();

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            invoice: invoice,
            categories: categories,
            accounts: accounts,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error interpreting invoice data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8;
    const double buttonHeight = 60.0;

    final btnStyle = ElevatedButton.styleFrom(
      fixedSize: Size(buttonWidth, buttonHeight),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense tracker'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings and management',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              const Text(
                'Choose how to scan your invoice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan invoice'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScannerPage(),
                    ),
                  );
                },
                style: btnStyle,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text('Import file (PDF/photo)'),
                onPressed: () => _handleFileImport(context),
                style: btnStyle,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
