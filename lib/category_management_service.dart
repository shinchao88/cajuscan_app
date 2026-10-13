// lib/category_management_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryManagementService {
  static const String _categoriesKey = 'cashew_categories';
  static const String _accountsKey = 'cashew_accounts';

  // Load defaults automatically on first launch.
  Future<Map<String, List<String>>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);

    if (jsonString != null) {
      // Decode and return existing data.
      final Map<String, dynamic> decodedMap = json.decode(jsonString);
      return decodedMap.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
    } else {
      // --- First launch ---
      // Load and save the defaults when no data exists.
      final defaultCategories = getDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  // Return the default categories.
  Map<String, List<String>> getDefaultCategories() {
    return {
      'Food': [
        'Lunch',
        'Dinner',
        'Coffee',
        'Water',
        'Snacks',
        'Delivery',
        'Takeaway',
      ],
      'Shopping': [
        'Amazon',
        'Continente',
        'Lidl',
        'Pingo Doce',
        'IKEA',
        'Zara',
        'H&M',
        'Primark',
        'Fnac',
        'Worten',
      ],
      'Home': [
        'Rent',
        'Condo fees',
        'Maintenance',
        'Cleaning',
        'Furniture',
        'Decor',
        'Repairs',
      ],
      'Utilities': ['Electricity', 'Gas', 'Water'],
      'Communications': ['Mobile phone', 'Cloud', 'Internet', 'TV'],
      'Entertainment': [
        'Cinema',
        'Theater',
        'Concerts',
        'Parks',
        'Travel',
        'Hotels',
      ],
      'Education': ['Books', 'Courses', 'School', 'University'],
      'Clothing': ['Casual', 'Formal', 'Sports', 'Shoes', 'Accessories'],
      'Beauty': ['Hairdresser', 'Beauty care', 'Cosmetics'],
      'Pets': ['Pet food', 'Veterinarian', 'Accessories'],
      'Children': ['Diapers', 'Toys', 'Clothing', 'Education'],
      'Taxes': ['Income tax', 'Property tax', 'VAT', 'Other'],
      'Health': ['Pharmacy', 'Dentist', 'Glasses'],
      'Transportation': [
        'Fuel',
        'Tolls',
        'Maintenance',
        'Parking',
        'Insurance',
        'Taxes',
      ],
      'Other': [],
    };
  }

  Future<void> saveCategories(Map<String, List<String>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(categories);
    await prefs.setString(_categoriesKey, jsonString);
  }

  Future<void> saveAccounts(List<String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_accountsKey, accounts);
  }

  Future<void> saveCategoriesAndAccounts({
    required Map<String, List<String>> categories,
    required List<String> accounts,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final String categoriesJson = json.encode(categories);
    await prefs.setString('cashew_categories', categoriesJson);

    await prefs.setStringList('cashew_accounts', accounts);
  }

  Future<void> addCategory(String categoryName) async {
    final categories = await getCategories();
    if (!categories.containsKey(categoryName)) {
      categories[categoryName] = [];
      await saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    final categories = await getCategories();
    categories.remove(categoryName);
    await saveCategories(categories);
  }

  Future<void> addSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    final categories = await getCategories();
    if (categories.containsKey(categoryName) &&
        !categories[categoryName]!.contains(subcategoryName)) {
      categories[categoryName]!.add(subcategoryName);
      await saveCategories(categories);
    }
  }

  Future<void> deleteSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    final categories = await getCategories();
    if (categories.containsKey(categoryName)) {
      categories[categoryName]!.remove(subcategoryName);
      await saveCategories(categories);
    }
  }
}
