// lib/cashew_import_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class CashewImportResult {
  final Map<String, List<String>>? categories;
  final List<String>? accounts;
  final String? errorMessage;

  const CashewImportResult({this.categories, this.accounts, this.errorMessage});

  bool get success => categories != null || accounts != null;
}

class CashewImportService {
  Future<CashewImportResult> pickAndParse() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        return const CashewImportResult(errorMessage: 'cancelled');
      }

      final file = result.files.first;
      String jsonString;

      if (kIsWeb) {
        if (file.bytes == null) {
          return const CashewImportResult(
            errorMessage: 'Could not read the file data on the web.',
          );
        }
        jsonString = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          return const CashewImportResult(
            errorMessage: 'Invalid file path.',
          );
        }
        final ioFile = File(file.path!);
        jsonString = await ioFile.readAsString();
      }

      return parseJson(jsonString);
    } catch (e) {
      return CashewImportResult(
        errorMessage: 'Error selecting file: $e',
      );
    }
  }

  CashewImportResult parseJson(String jsonString) {
    try {
      final data = json.decode(jsonString);
      if (data is! Map<String, dynamic>) {
        return const CashewImportResult(
          errorMessage: 'Invalid JSON format. Expected an object.',
        );
      }

      Map<String, List<String>>? importedCategories;
      List<String>? importedAccounts;

      // Parse categories.
      if (data.containsKey('categories')) {
        final rawCategories = data['categories'];
        if (rawCategories is Map<String, dynamic> && rawCategories.isNotEmpty) {
          final Map<String, List<String>> tempCategories = {};

          for (final entry in rawCategories.entries) {
            final key = entry.key;
            final val = entry.value;
            if (val is List) {
              tempCategories[key] = val
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            } else {
              tempCategories[key] = [];
            }
          }

          if (tempCategories.isNotEmpty) {
            importedCategories = tempCategories;
          }
        }
      }

      // Parse accounts.
      if (data.containsKey('accounts')) {
        final rawAccounts = data['accounts'];
        if (rawAccounts is List) {
          final parsedAccounts = rawAccounts
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (parsedAccounts.isNotEmpty) {
            importedAccounts = parsedAccounts;
          }
        }
      }

      if (importedCategories == null && importedAccounts == null) {
        return const CashewImportResult(
          errorMessage:
              'The file does not contain valid category or account data from Cashew.',
        );
      }

      return CashewImportResult(
        categories: importedCategories,
        accounts: importedAccounts,
      );
    } catch (e) {
      return CashewImportResult(
        errorMessage: 'Error processing the JSON structure: $e',
      );
    }
  }
}
