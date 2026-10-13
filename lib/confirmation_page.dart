// lib/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'invoice_model.dart';
import 'profile_service.dart';
import 'cashew_launcher.dart';
import 'merchant_profile.dart';
import 'settings_service.dart';

class ConfirmationPage extends StatefulWidget {
  final Invoice invoice;
  final Map<String, List<String>> categories;
  final List<String> accounts;

  const ConfirmationPage({
    super.key,
    required this.invoice,
    required this.categories,
    required this.accounts,
  });

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final ProfileService _profileService = ProfileService();
  final CashewLauncher _cashewLauncher = CashewLauncher();
  final SettingsService _settingsService = SettingsService();

  MerchantProfile? _profile;
  Map<String, List<String>> _allCategories = {};
  List<String> _allAccounts = [];
  String? _selectedAccount;
  String? _suggestedAccount;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isMerchantStored = false;
  bool _sendFiscalInfo = false;

  late Invoice _localInvoice;

  // Keys for persisting account usage history.
  static const String _globalHistoryKey = 'ac_global_history';
  static const String _merchantHistoryKey = 'ac_merchant_history';

  @override
  void initState() {
    super.initState();
    _localInvoice = widget.invoice;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loadedProfile = await _profileService.getProfile(
        _localInvoice.merchantNif,
      );

      final loadedCategories = widget.categories;
      final loadedAccounts = widget.accounts;
      final sendFiscalValue = await _settingsService.getSendFiscalInfo();

      final prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _allCategories = loadedCategories;
          _isMerchantStored = loadedProfile != null;
          _sendFiscalInfo = sendFiscalValue;

          _profile =
              loadedProfile ??
              MerchantProfile(name: 'Unknown', category: '');

          List<String> accounts = List<String>.from(loadedAccounts);
          final String globalRaw = prefs.getString(_globalHistoryKey) ?? '{}';
          final String merchantRaw =
              prefs.getString(_merchantHistoryKey) ?? '{}';

          final Map<String, dynamic> globalHistory = json.decode(globalRaw);
          final Map<String, dynamic> merchantHistory = json.decode(merchantRaw);

          final String merchantId = _localInvoice.merchantNif;
          final Map<String, dynamic> thisMerchantHistory =
              merchantHistory[merchantId] ?? {};

          String? prediction;

          // Rule 1: Prefer the most-used account for this merchant.
          if (thisMerchantHistory.isNotEmpty) {
            prediction = thisMerchantHistory.entries
                .reduce((a, b) => (a.value as int) > (b.value as int) ? a : b)
                .key;
          }

          if ((prediction == null || !accounts.contains(prediction)) &&
              globalHistory.isNotEmpty) {
            prediction = globalHistory.entries
                .reduce((a, b) => (a.value as int) > (b.value as int) ? a : b)
                .key;
          }

          // Rule 3: Use the first account as the final fallback.
          if (prediction == null || !accounts.contains(prediction)) {
            prediction = accounts.isNotEmpty ? accounts.first : null;
          }

          // Sort the list with the most-used accounts first.
          accounts.sort((a, b) {
            final int countA = globalHistory[a] ?? 0;
            final int countB = globalHistory[b] ?? 0;
            return countB.compareTo(countA);
          });

          _allAccounts = accounts;
          _suggestedAccount = prediction;
          _selectedAccount = prediction;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Record account usage to improve future suggestions.
  Future<void> _incrementAccountUsage(String account) async {
    final prefs = await SharedPreferences.getInstance();
    final String merchantId = _localInvoice.merchantNif;

    // Update the global history.
    final String globalRaw = prefs.getString(_globalHistoryKey) ?? '{}';
    final Map<String, dynamic> globalHistory = Map<String, dynamic>.from(
      json.decode(globalRaw),
    );
    globalHistory[account] = (globalHistory[account] ?? 0) + 1;
    await prefs.setString(_globalHistoryKey, json.encode(globalHistory));

    // Update the history for this merchant.
    final String merchantRaw = prefs.getString(_merchantHistoryKey) ?? '{}';
    final Map<String, dynamic> merchantHistory = Map<String, dynamic>.from(
      json.decode(merchantRaw),
    );

    final Map<String, dynamic> thisMerchantHistory =
        merchantHistory.containsKey(merchantId) &&
            merchantHistory[merchantId] is Map
        ? Map<String, dynamic>.from(merchantHistory[merchantId] as Map)
        : {};

    thisMerchantHistory[account] = (thisMerchantHistory[account] ?? 0) + 1;
    merchantHistory[merchantId] = thisMerchantHistory;

    await prefs.setString(_merchantHistoryKey, json.encode(merchantHistory));
  }

  /// Open the native time picker.
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(_localInvoice.date);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && picked != currentTime) {
      setState(() {
        _localInvoice = _localInvoice.copyWith(
          date: DateTime(
            _localInvoice.date.year,
            _localInvoice.date.month,
            _localInvoice.date.day,
            picked.hour,
            picked.minute,
          ),
        );
      });
    }
  }

  // --- Regista no Cashew e guarda o perfil ---
  Future<void> _registerTransaction() async {
    if (_profile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Record account usage before opening Cashew.
      if (_selectedAccount != null) {
        await _incrementAccountUsage(_selectedAccount!);
      }

      // Save the updated profile.
      await _profileService.saveProfile(_localInvoice.merchantNif, _profile!);

      // Send the fully updated invoice.
      await _cashewLauncher.launchCashew(
        invoice: _localInvoice,
        category: _profile!.category,
        subcategory: _profile!.subcategory,
        account: _selectedAccount,
        title: _profile!.name,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveProfileOnly() async {
    if (_profile == null) return;

    // Ensure the merchant has a name before saving the profile.
    if (_profile!.name.trim() == 'Unknown' ||
        _profile!.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a merchant name before saving.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    try {
      await _profileService.saveProfile(_localInvoice.merchantNif, _profile!);
      if (mounted) {
        setState(() {
          _isMerchantStored = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Merchant "${_profile!.name}" saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Show a simple dialog for editing the merchant name.
  void _showEditMerchantNameDialog() {
    if (_profile == null) return;

    final localNameController = TextEditingController(
      text: _profile!.name == 'Unknown' ? '' : _profile!.name,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Merchant name'),
          content: TextField(
            controller: localNameController,
            decoration: const InputDecoration(
              labelText: 'Business name',
              hintText: 'e.g. Whole Foods, Target',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (localNameController.text.trim().isNotEmpty) {
                  setState(() {
                    _profile = MerchantProfile(
                      name: localNameController.text.trim(),
                      category: _profile!.category,
                      subcategory: _profile!.subcategory,
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Show the category and subcategory picker.
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Text(
                        'Select category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: _allCategories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No categories available. Set them up in Cashew.',
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              shrinkWrap: true,
                              itemCount: _allCategories.keys.length,
                              itemBuilder: (context, index) {
                                final category = _allCategories.keys.elementAt(
                                  index,
                                );
                                final subcategories =
                                    _allCategories[category] ?? [];
                                final isSelectedCategory =
                                    _profile?.category == category;

                                if (subcategories.isEmpty) {
                                  return ListTile(
                                    leading: Icon(
                                      Icons.category_outlined,
                                      color: isSelectedCategory
                                          ? Colors.green
                                          : Colors.blueGrey,
                                    ),
                                    title: Text(
                                      category,
                                      style: TextStyle(
                                        fontWeight: isSelectedCategory
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelectedCategory
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _profile = MerchantProfile(
                                          name: _profile?.name ?? 'Unknown',
                                          category: category,
                                          subcategory: null,
                                        );
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }

                                return ExpansionTile(
                                  leading: Icon(
                                    Icons.category,
                                    color: isSelectedCategory
                                        ? Colors.green
                                        : Colors.blueGrey,
                                  ),
                                  title: Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: isSelectedCategory
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  initiallyExpanded: isSelectedCategory,
                                  children: subcategories.map((sub) {
                                    final isSelectedSub =
                                        isSelectedCategory &&
                                        _profile?.subcategory == sub;
                                    return ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        56,
                                        0,
                                        20,
                                        0,
                                      ),
                                      leading: Icon(
                                        Icons.subdirectory_arrow_right,
                                        size: 18,
                                        color: isSelectedSub
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      title: Text(
                                        sub,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isSelectedSub
                                              ? Colors.green
                                              : null,
                                          fontWeight: isSelectedSub
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: isSelectedSub
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 18,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _profile = MerchantProfile(
                                            name: _profile?.name ?? 'Unknown',
                                            category: category,
                                            subcategory: sub,
                                          );
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show the account picker.
  void _showAccountBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Select destination account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: _allAccounts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No accounts available. Set them up in Cashew.',
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _allAccounts.length,
                          itemBuilder: (context, index) {
                            final account = _allAccounts[index];
                            final isSuggested = account == _suggestedAccount;
                            final isSelected = account == _selectedAccount;

                            return ListTile(
                              leading: Icon(
                                isSuggested
                                    ? Icons.stars
                                    : Icons.account_balance_wallet,
                                color: isSuggested
                                    ? Colors.amber[700]
                                    : Colors.blueGrey,
                              ),
                              title: Text(
                                account,
                                style: TextStyle(
                                  fontWeight: isSuggested || isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : (isSuggested
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Suggested',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          )
                                        : null),
                              onTap: () {
                                setState(() {
                                  _selectedAccount = account;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    if (_profile == null) return;

    final localNameController = TextEditingController(text: _profile!.name);

    String? dialogSelectedCategory = _profile!.category.isEmpty
        ? null
        : _profile!.category;
    String? dialogSelectedSubcategory = _profile!.subcategory;
    String? dialogSelectedAccount = _selectedAccount;

    if (dialogSelectedCategory != null &&
        !_allCategories.containsKey(dialogSelectedCategory)) {
      dialogSelectedCategory = null;
      dialogSelectedSubcategory = null;
    }
    if (dialogSelectedSubcategory != null &&
        !(_allCategories[dialogSelectedCategory]?.contains(
              dialogSelectedSubcategory,
            ) ??
            false)) {
      dialogSelectedSubcategory = null;
    }
    if (dialogSelectedAccount != null &&
        !_allAccounts.contains(dialogSelectedAccount)) {
      dialogSelectedAccount = _allAccounts.isNotEmpty
          ? _allAccounts.first
          : null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableSubcategories =
                _allCategories[dialogSelectedCategory] ?? [];

            return AlertDialog(
              title: const Text('Edit merchant'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: localNameController,
                      decoration: const InputDecoration(
                        labelText: 'Merchant name',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: dialogSelectedCategory,
                      hint: const Text('None (select in Cashew)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (select in Cashew)'),
                        ),
                        ..._allCategories.keys.map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                      onChanged: (newValue) {
                        setDialogState(() {
                          dialogSelectedCategory = newValue;
                          dialogSelectedSubcategory = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 20),
                    if (dialogSelectedCategory != null &&
                        availableSubcategories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: dialogSelectedSubcategory,
                        hint: const Text('None'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...availableSubcategories.map(
                            (sub) =>
                                DropdownMenuItem(value: sub, child: Text(sub)),
                          ),
                        ],
                        onChanged: (newValue) {
                          setDialogState(() {
                            dialogSelectedSubcategory = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: dialogSelectedAccount,
                      hint: const Text('None (select in Cashew)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (select in Cashew)'),
                        ),
                        ..._allAccounts.map(
                          (acc) =>
                              DropdownMenuItem(value: acc, child: Text(acc)),
                        ),
                      ],
                      onChanged: (newValue) {
                        setDialogState(() {
                          dialogSelectedAccount = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Destination account',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (localNameController.text.isNotEmpty) {
                      setState(() {
                        _profile = MerchantProfile(
                          name: localNameController.text,
                          category: dialogSelectedCategory ?? '',
                          subcategory: dialogSelectedSubcategory,
                        );
                        _selectedAccount = dialogSelectedAccount;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dateText =
        "${_localInvoice.date.month.toString().padLeft(2, '0')}/${_localInvoice.date.day.toString().padLeft(2, '0')}/${_localInvoice.date.year}";

    final String timeText = TimeOfDay.fromDateTime(
      _localInvoice.date,
    ).format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit profile',
            onPressed: _isLoading ? null : _showEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: InkWell(
                      onTap: _isLoading ? null : _showEditMerchantNameDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.store, size: 40),
                        title: Text(
                          _profile?.name ?? 'Loading...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('Tax ID: ${_localInvoice.merchantNif}'),
                        trailing: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month, size: 40),
                        title: const Text('Invoice date and time'),
                        subtitle: Text(
                          '$dateText at $timeText',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: _isLoading ? null : _showCategoryBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(Icons.category, size: 40),
                        title: const Text('Category'),
                        subtitle: Text(
                          _profile?.category.isEmpty ?? true
                              ? 'Not set'
                              : '${_profile!.category}${_profile!.subcategory != null ? ' > ${_profile!.subcategory}' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: InkWell(
                      onTap: _showAccountBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          size: 40,
                        ),
                        title: const Text('Destination account'),
                        subtitle: Text(
                          _selectedAccount ??
                              'Not set (select in Cashew)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.euro, size: 40),
                      title: const Text('Total amount'),
                      subtitle: Text(
                        '${_localInvoice.totalAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_sendFiscalInfo) ...[
                    Card(
                      color: Colors.yellow[100],
                      child: ListTile(
                        leading: const Icon(Icons.info, size: 40),
                        title: const Text('Additional notes'),
                        subtitle: Text(
                          _localInvoice.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Flexible space to push the button to the bottom.
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Add to Cashew',
                              style: TextStyle(fontSize: 18),
                            ),
                      onPressed: _isProcessing ? null : _registerTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  // Allow saving the merchant without creating a transaction.
                  if (!_isMerchantStored) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save merchant only',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: _isProcessing ? null : _saveProfileOnly,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).viewPadding.bottom + 16.0,
                      ),
                    ),
                  ],
                  // Add space between the button and the bottom edge.
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 12.0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
