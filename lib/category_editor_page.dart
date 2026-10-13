// lib/category_editor_page.dart
import 'package:flutter/material.dart';
import 'category_management_service.dart';

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key});

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  final CategoryManagementService _categoryService =
      CategoryManagementService();
  Map<String, List<String>> _categories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    final loadedCategories = await _categoryService.getCategories();
    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog({String? categoryToEdit}) async {
    final nameController = TextEditingController(text: categoryToEdit);
    final isEditing = categoryToEdit != null;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit category' : 'New category'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (isEditing) {
        // Rename by deleting the old category and adding the new one.
        final subcategories = _categories[categoryToEdit]!;
        await _categoryService.deleteCategory(categoryToEdit);
        await _categoryService.addCategory(newName);
        for (var sub in subcategories) {
          await _categoryService.addSubcategory(newName, sub);
        }
      } else {
        await _categoryService.addCategory(newName);
      }
      _loadCategories();
    }
  }

  Future<void> _showAddSubcategoryDialog(String categoryName) async {
    final nameController = TextEditingController();
    final newSubcategoryName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New subcategory for "$categoryName"'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subcategory name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newSubcategoryName != null && newSubcategoryName.isNotEmpty) {
      await _categoryService.addSubcategory(categoryName, newSubcategoryName);
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(
          'Are you sure you want to delete the "$categoryName" category and all its subcategories?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      await _categoryService.deleteCategory(categoryName);
      _loadCategories();
    }
  }

  Future<void> _deleteSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    await _categoryService.deleteSubcategory(categoryName, subcategoryName);
    _loadCategories();
  }

  Future<void> _restoreDefaultCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore categories'),
        content: const Text(
          'This will replace your current category list with the default list. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      final defaultCategories = _categoryService.getDefaultCategories();
      await _categoryService.saveCategories(defaultCategories);
      _loadCategories();
    }
  }

  Future<void> _deleteAllCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This action cannot be undone and will delete all categories and subcategories. Are you sure?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, delete everything'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _categoryService.saveCategories({}); // Save an empty map.
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryKeys = _categories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete everything',
            onPressed: _isLoading || _categories.isEmpty
                ? null
                : _deleteAllCategories,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore defaults',
            onPressed: _isLoading ? null : _restoreDefaultCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        tooltip: 'New category',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          // The restore button is in the app bar.
          ? const Center(child: Text('Your category list is empty.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120.0),
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final category = categoryKeys[index];
                final subcategories = _categories[category]!;
                return ExpansionTile(
                  key: PageStorageKey(category),
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(Icons.folder_open),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Rename',
                        onPressed: () =>
                            _showAddDialog(categoryToEdit: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                  children: [
                    ...subcategories.map(
                      (sub) => ListTile(
                        title: Text(sub),
                        leading: const Icon(Icons.label_outline, size: 18),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _deleteSubcategory(category, sub),
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Add subcategory...'),
                      leading: const Icon(Icons.add, color: Colors.green),
                      onTap: () => _showAddSubcategoryDialog(category),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
