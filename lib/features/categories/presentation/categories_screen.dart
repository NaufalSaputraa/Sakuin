import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../domain/category_model.dart';
import '../providers/category_providers.dart';
import '../../../core/utils/result.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _emojiPickerList = [
    '🍔', '☕', '🍜', '🍕', '🚗', '🛵', '⛽', '🚆',
    '📱', '💡', '💧', '🏠', '🛒', '🛍️', '👔', '👠',
    '🎮', '🎬', '🎧', '✈️', '💊', '🏥', '🏋️', '📚',
    '💰', '💼', '📈', '💻', '🎁', '🎓', '👶', '🐾',
  ];

  final List<String> _colorPalette = [
    '#6B5CE7', '#E74C3C', '#2ECC71', '#3498DB',
    '#E67E22', '#9B59B6', '#1ABC9C', '#F1C40F',
    '#E84393', '#00CEC9', '#0984E3', '#6C5CE7',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context, {bool isIncome = false}) {
    final theme = Theme.of(context);
    final scaffoldContext = context;
    final nameController = TextEditingController();
    final nameIdController = TextEditingController();
    String selectedEmoji = isIncome ? '💰' : '🛒';
    String selectedColor = isIncome ? '#2ECC71' : '#6B5CE7';
    bool currentIsIncome = isIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tambah Kategori Baru',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    // Type Toggle (Pengeluaran vs Pemasukan)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Pengeluaran')),
                        ButtonSegment(value: true, label: Text('Pemasukan')),
                      ],
                      selected: {currentIsIncome},
                      onSelectionChanged: (set) {
                        setSheetState(() {
                          currentIsIncome = set.first;
                          if (currentIsIncome) {
                            selectedEmoji = '💰';
                            selectedColor = '#2ECC71';
                          } else {
                            selectedEmoji = '🛒';
                            selectedColor = '#6B5CE7';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selected Emoji Avatar Preview
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(int.parse(selectedColor.replaceAll('#', '0xFF'))),
                        child: Text(selectedEmoji, style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Fields
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori (Contoh: Gaming / Coffee)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameIdController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori ID (Contoh: Main Game / Kopi)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emoji Picker Grid
                    Text('Pilih Ikon Emoji', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _emojiPickerList.length,
                        itemBuilder: (context, idx) {
                          final emoji = _emojiPickerList[idx];
                          final isSelected = emoji == selectedEmoji;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedEmoji = emoji),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Color Palette Selector
                    Text('Pilih Warna Tema', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorPalette.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final hex = _colorPalette[idx];
                          final isSelected = hex == selectedColor;
                          final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedColor = hex),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: color,
                              child: isSelected
                                  ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 16)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('Nama kategori tidak boleh kosong'),
                              ),
                            );
                            return;
                          }

                          final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                          final repo = ref.read(categoryRepositoryProvider);

                          try {
                            final result = await repo.createCategory(
                              key: key,
                              name: name,
                              nameId: nameIdController.text.trim().isNotEmpty
                                  ? nameIdController.text.trim()
                                  : name,
                              icon: selectedEmoji,
                              color: selectedColor,
                              isIncome: currentIsIncome,
                            );

                            if (result case Failure(:final error)) {
                              if (scaffoldContext.mounted) {
                                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal menambah kategori: ${error.message}',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            ref.invalidate(expenseCategoriesProvider);
                            ref.invalidate(incomeCategoriesProvider);
                            ref.invalidate(allCategoriesProvider);

                            if (scaffoldContext.mounted) {
                              Navigator.of(scaffoldContext).pop();
                            }
                          } catch (e) {
                            if (scaffoldContext.mounted) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                SnackBar(
                                  content: Text('Terjadi kesalahan: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Simpan Kategori'),
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
   },
);
   }

  @override
  Widget build(BuildContext context) {
    final expenseCategoriesAsync = ref.watch(expenseCategoriesProvider);
    final incomeCategoriesAsync = ref.watch(incomeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Expense Categories Tab
          expenseCategoriesAsync.when(
            data: (categories) => _CategoryList(
              categories: categories,
              onDelete: (cat) async {
                final repo = ref.read(categoryRepositoryProvider);
                await repo.deleteCategory(cat.id);
              },
            ),
            loading: () => const ShimmerLoadingSection(section: ShimmerSection.categoriesList),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // Income Categories Tab
          incomeCategoriesAsync.when(
            data: (categories) => _CategoryList(
              categories: categories,
              onDelete: (cat) async {
                final repo = ref.read(categoryRepositoryProvider);
                await repo.deleteCategory(cat.id);
              },
            ),
            loading: () => const ShimmerLoadingSection(section: ShimmerSection.categoriesList),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddCategorySheet(context, isIncome: _tabController.index == 1);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori Baru'),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onDelete;

  const _CategoryList({required this.categories, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const Center(child: Text('Belum ada kategori'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(int.parse(cat.color.replaceAll('#', '0xFF')));

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(cat.icon, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: cat.nameId != null && cat.nameId != cat.name
              ? Text(cat.nameId!, style: theme.textTheme.bodySmall)
              : null,
          trailing: cat.isDefault
              ? const Chip(
                  label: Text('Bawaan', style: TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              : IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Kategori?'),
                        content: Text('Yakin ingin menghapus kategori "${cat.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onDelete(cat);
                            },
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        );
      },
    );
  }
}
