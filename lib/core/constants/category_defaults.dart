class DefaultCategoryItem {
  final String key;
  final String name;
  final String nameId;
  final String icon;
  final String colorHex;
  final bool isIncome;
  final int sortOrder;

  const DefaultCategoryItem({
    required this.key,
    required this.name,
    required this.nameId,
    required this.icon,
    required this.colorHex,
    this.isIncome = false,
    required this.sortOrder,
  });
}

class CategoryDefaults {
  static const List<DefaultCategoryItem> defaults = [
    // Expenses
    DefaultCategoryItem(
      key: 'food',
      name: 'Food & Drinks',
      nameId: 'Makanan & Minuman',
      icon: '🍽️',
      colorHex: '#FF6B6B',
      sortOrder: 1,
    ),
    DefaultCategoryItem(
      key: 'transport',
      name: 'Transportation',
      nameId: 'Transportasi',
      icon: '🚗',
      colorHex: '#4ECDC4',
      sortOrder: 2,
    ),
    DefaultCategoryItem(
      key: 'shopping',
      name: 'Shopping',
      nameId: 'Belanja',
      icon: '🛒',
      colorHex: '#45B7D1',
      sortOrder: 3,
    ),
    DefaultCategoryItem(
      key: 'pulsa',
      name: 'Data & Mobile',
      nameId: 'Pulsa & Paket Data',
      icon: '📱',
      colorHex: '#96CEB4',
      sortOrder: 4,
    ),
    DefaultCategoryItem(
      key: 'bills',
      name: 'Bills & Utilities',
      nameId: 'Tagihan & Utilitas',
      icon: '💡',
      colorHex: '#FFEAA7',
      sortOrder: 5,
    ),
    DefaultCategoryItem(
      key: 'health',
      name: 'Health & Medical',
      nameId: 'Kesehatan',
      icon: '🏥',
      colorHex: '#DDA0DD',
      sortOrder: 6,
    ),
    DefaultCategoryItem(
      key: 'entertainment',
      name: 'Entertainment',
      nameId: 'Hiburan',
      icon: '🎬',
      colorHex: '#98D8C8',
      sortOrder: 7,
    ),
    DefaultCategoryItem(
      key: 'education',
      name: 'Education',
      nameId: 'Pendidikan',
      icon: '📚',
      colorHex: '#F7DC6F',
      sortOrder: 8,
    ),
    DefaultCategoryItem(
      key: 'housing',
      name: 'Rent & Housing',
      nameId: 'Kos & Kontrakan',
      icon: '🏠',
      colorHex: '#BB8FCE',
      sortOrder: 9,
    ),
    DefaultCategoryItem(
      key: 'warung',
      name: 'Street Food & Snacks',
      nameId: 'Warung & Jajanan',
      icon: '🥘',
      colorHex: '#F0B27A',
      sortOrder: 10,
    ),
    DefaultCategoryItem(
      key: 'fuel',
      name: 'Fuel & Gas',
      nameId: 'BBM & Bensin',
      icon: '⛽',
      colorHex: '#85C1E9',
      sortOrder: 11,
    ),
    DefaultCategoryItem(
      key: 'other_expense',
      name: 'Other Expense',
      nameId: 'Lainnya',
      icon: '📦',
      colorHex: '#AEB6BF',
      sortOrder: 12,
    ),

    // Incomes
    DefaultCategoryItem(
      key: 'salary',
      name: 'Salary',
      nameId: 'Gaji',
      icon: '💰',
      colorHex: '#2ECC71',
      isIncome: true,
      sortOrder: 13,
    ),
    DefaultCategoryItem(
      key: 'freelance',
      name: 'Freelance',
      nameId: 'Freelance',
      icon: '💻',
      colorHex: '#1ABC9C',
      isIncome: true,
      sortOrder: 14,
    ),
    DefaultCategoryItem(
      key: 'transfer_in',
      name: 'Transfer In',
      nameId: 'Transfer Masuk',
      icon: '📥',
      colorHex: '#3498DB',
      isIncome: true,
      sortOrder: 15,
    ),
    DefaultCategoryItem(
      key: 'other_income',
      name: 'Other Income',
      nameId: 'Lainnya',
      icon: '💵',
      colorHex: '#27AE60',
      isIncome: true,
      sortOrder: 16,
    ),
  ];
}
