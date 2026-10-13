// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'management_page.dart';
import 'category_editor_page.dart';
import 'backup_service.dart';
import 'about_page.dart';
import 'settings_service.dart';
import 'cashew_import_service.dart';
import 'category_management_service.dart';
import 'account_editor_page.dart';
import 'account_management_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BackupService _backupService = BackupService();
  final SettingsService _settingsService = SettingsService();
  final CashewImportService _cashewImportService = CashewImportService();
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  final AccountManagementService _accountService = AccountManagementService();
  bool _isProcessing = false;

  bool _confirmOnCashew = true;
  bool _continuousScan = true;
  bool _sendFiscalInfo = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Load settings ---
  Future<void> _loadSettings() async {
    final confirmValue = await _settingsService.getConfirmOnCashew();
    final continuousValue = await _settingsService.getContinuousScan();
    final fiscalInfoValue = await _settingsService.getSendFiscalInfo();
    if (mounted) {
      setState(() {
        _confirmOnCashew = confirmValue;
        _continuousScan = continuousValue;
        _sendFiscalInfo = fiscalInfoValue;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
    });

    String statusMessage = '';
    bool isError = false;

    try {
      final bool success = await _backupService.exportData();
      if (success) {
        statusMessage = 'Export completed successfully!';
      }
    } catch (e) {
      statusMessage = e.toString().replaceAll('Exception: ', '');
      isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }

    if (statusMessage.isNotEmpty && mounted) {
      _showSnackBar(statusMessage, isError ? Colors.red : Colors.green);
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isProcessing = true;
    });

    String statusMessage = '';
    bool isError = false;

    try {
      final bool success = await _backupService.importData();
      if (success) {
        statusMessage = 'Data imported successfully!';
      }
    } catch (e) {
      statusMessage = e.toString().replaceAll('Exception: ', '');
      isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }

    if (statusMessage.isNotEmpty && mounted) {
      _showSnackBar(statusMessage, isError ? Colors.red : Colors.green);
    }
  }

  Future<void> _handleCashewImport() async {
    setState(() {
      _isProcessing = true;
    });

    final result = await _cashewImportService.pickAndParse();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    // The user cancelled the file picker.
    if (result.errorMessage == 'cancelled') {
      return;
    }

    if (!result.success) {
      if (mounted) {
        _showSnackBar(result.errorMessage!, Colors.red);
      }
      return;
    }

    final categories = result.categories;
    final accounts = result.accounts;

    final hasCategories = categories != null && categories.isNotEmpty;
    final hasAccounts = accounts != null && accounts.isNotEmpty;

    if (!hasCategories && !hasAccounts) {
      if (mounted) {
        _showSnackBar(
          'The file contains no valid data to import.',
          Colors.red,
        );
      }
      return;
    }

    if (!mounted) return;

    // Build the import summary shown in the confirmation dialog.
    final List<String> infoLines = [];
    if (hasCategories) {
      infoLines.add('Found ${categories.length} categories.');
    }
    if (hasAccounts) {
      infoLines.add('Found ${accounts.length} accounts.');
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import data from Cashew'),
        content: Text(
          '${infoLines.join('\n')}\n\n'
          'This will replace the current app settings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final List<String> successMessages = [];

      if (hasCategories) {
        await _categoryService.saveCategories(categories);
        successMessages.add('${categories.length} categories');
      }

      if (hasAccounts) {
        await _accountService.saveAccounts(accounts);
        successMessages.add('${accounts.length} accounts');
      }

      if (mounted) {
        _showSnackBar(
          'Data imported successfully: ${successMessages.join(' and ')}.',
          Colors.green,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Error saving Cashew data.', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isProcessing || _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // --- Settings toggles ---
                SwitchListTile(
                  title: const Text('Confirm in Cashew'),
                  subtitle: const Text(
                    'When enabled, data opens in Cashew for confirmation before it is saved.',
                  ),
                  value: _confirmOnCashew,
                  onChanged: (bool value) async {
                    await _settingsService.setConfirmOnCashew(value);
                    if (mounted) {
                      setState(() {
                        _confirmOnCashew = value;
                      });
                    }
                  },
                  secondary: const Icon(Icons.touch_app),
                ),
                SwitchListTile(
                  title: const Text('Continuous scanning'),
                  subtitle: const Text(
                    'Scan multiple invoices without leaving the camera.',
                  ),
                  value: _continuousScan,
                  onChanged: (bool value) async {
                    await _settingsService.setContinuousScan(value);
                    if (mounted) setState(() => _continuousScan = value);
                  },
                  secondary: const Icon(Icons.all_inclusive),
                ),
                SwitchListTile(
                  title: const Text('Attach tax metadata'),
                  subtitle: const Text(
                    'Add extra information to transaction notes.',
                  ),
                  value: _sendFiscalInfo,
                  onChanged: (bool value) async {
                    await _settingsService.setSendFiscalInfo(value);
                    if (mounted) setState(() => _sendFiscalInfo = value);
                  },
                  secondary: const Icon(Icons.receipt_long),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Manage merchants'),
                  subtitle: const Text(
                    'View and edit saved merchant profiles',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ManagementPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Manage categories'),
                  subtitle: const Text(
                    'Add, edit, or delete Cashew categories and subcategories',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => const CategoryEditorPage(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Manage accounts'),
                  subtitle: const Text(
                    'Add, edit, or delete Cashew destination accounts',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (c) => const AccountEditorPage(),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export data (backup)'),
                  subtitle: const Text(
                    'Save all app data to a file',
                  ),
                  onTap: _handleExport,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Import data (restore)'),
                  subtitle: const Text(
                    'Load data from a backup file',
                  ),
                  onTap: _handleImport,
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Import data from Cashew'),
                  subtitle: const Text(
                    'Load categories and accounts from a Cashew export',
                  ),
                  onTap: _isProcessing ? null : _handleCashewImport,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About CajuScan'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
