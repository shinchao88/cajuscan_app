// lib/account_management_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AccountManagementService {
  static const String _accountsKey = 'cashew_accounts';

  // Load all saved accounts.
  Future<List<String>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String>? stringList = prefs.getStringList(_accountsKey);
    if (stringList != null) {
      return stringList;
    }

    // Initialize the default accounts on first launch.
    final defaultAccounts = getDefaultAccounts();
    await saveAccounts(defaultAccounts);
    return defaultAccounts;
  }

  // Return the default accounts.
  List<String> getDefaultAccounts() {
    return ['Wallet', 'Credit Card', 'Revolut'];
  }

  // Save the full account list.
  Future<void> saveAccounts(List<String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_accountsKey, accounts);
  }

  // Add an account if it does not already exist.
  Future<void> addAccount(String accountName) async {
    final accounts = await getAccounts();
    if (!accounts.contains(accountName)) {
      accounts.add(accountName);
      await saveAccounts(accounts);
    }
  }

  // Delete an account.
  Future<void> deleteAccount(String accountName) async {
    final accounts = await getAccounts();
    accounts.remove(accountName);
    await saveAccounts(accounts);
  }

  // Edit or rename an account.
  Future<void> updateAccount(String oldName, String newName) async {
    final accounts = await getAccounts();
    final index = accounts.indexOf(oldName);
    if (index != -1 && !accounts.contains(newName)) {
      accounts[index] = newName;
      await saveAccounts(accounts);
    }
  }
}
