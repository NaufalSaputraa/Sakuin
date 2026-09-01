import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/thousands_separator_formatter.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../../budget/domain/budget_model.dart';
import '../../budget/providers/budget_providers.dart';

/// Riverpod 3 removed [StateProvider]; use a [Notifier] instead.
class OnboardingStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final onboardingStateProvider =
    NotifierProvider<OnboardingStateNotifier, bool>(
  () => OnboardingStateNotifier(),
);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Profile
  final TextEditingController _nameController = TextEditingController(text: 'Pengguna');

  // Step 2: Initial Balances - Simplified to 1 wallet (Dompet Fisik + Dompet Digital)
  final TextEditingController _cashBalanceController = TextEditingController(
    text: RupiahFormatter.formatWithoutSymbol(100000),
  );
  final TextEditingController _digitalBalanceController = TextEditingController(
    text: RupiahFormatter.formatWithoutSymbol(50000),
  );

  // Step 3: Monthly Budget
  double _monthlyBudget = 3000000.0;
  final TextEditingController _budgetController = TextEditingController(text: '3000000');

  @override
  void initState() {
    super.initState();
    // Load persisted name if exists (fix: nama tidak berganti)
    SharedPreferences.getInstance().then((prefs) {
      final savedName = prefs.getString(AppConstants.userNameKey);
      if (savedName != null && savedName.isNotEmpty && mounted) {
        setState(() => _nameController.text = savedName);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cashBalanceController.dispose();
    _digitalBalanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);
    await prefs.setString(AppConstants.userNameKey, _nameController.text.trim());

    // Update initial wallet balances if entered
    final wallets = ref.read(allWalletsProvider).asData?.value ?? [];
    final walletRepo = ref.read(walletRepositoryProvider);

    final cashAmount = double.tryParse(_cashBalanceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    final digitalAmount = double.tryParse(_digitalBalanceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;

    for (final w in wallets) {
      if (w.isPhysical && cashAmount > 0) {
        await walletRepo.updateWallet(w.copyWith(balance: cashAmount));
      } else if (w.walletType == 'digital' && w.parentId == null && digitalAmount > 0) {
        // Dompet Digital root - user can customize name later (e.g. DANA/ShopeePay)
        await walletRepo.updateWallet(w.copyWith(balance: digitalAmount));
      }
    }

    // Create Initial Budget
    if (_monthlyBudget > 0) {
      final budgetRepo = ref.read(budgetRepositoryProvider);
      await budgetRepo.createBudget(
        name: 'Anggaran Bulanan',
        budgetType: BudgetType.limit,
        amount: _monthlyBudget,
        period: 'monthly',
      );
    }

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page View Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1Welcome(theme),
                  _buildStep2Wallets(theme),
                  _buildStep3Budget(theme),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Welcome(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Selamat Datang di Sakuin',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pencatat keuangan cerdas dengan sistem dua dompet dan privasi 100% lokal di perangkatmu.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Siapa nama panggilanmu?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: 'Nama panggilan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Wallets(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Setup Saldo Awal',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan saldo kas dan e-wallet yang sedang kamu pegang saat ini.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Cash
          _WalletInputRow(
            icon: '💵',
            name: 'Dompet Fisik (Tunai)',
            controller: _cashBalanceController,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Dompet Digital - user bisa customize nama nanti (DANA/ShopeePay/dll)
          _WalletInputRow(
            icon: '💳',
            name: 'Dompet Digital',
            controller: _digitalBalanceController,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Budget(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batas Anggaran Bulanan',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tentukan batas pengeluaran bulananmu agar pengeluaran selalu terkontrol.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              RupiahFormatter.format(_monthlyBudget),
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BudgetChip(
                amount: 1500000,
                isSelected: _monthlyBudget == 1500000,
                onTap: (val) => setState(() {
                  _monthlyBudget = val;
                  _budgetController.text = RupiahFormatter.formatWithoutSymbol(val);
                }),
              ),
              _BudgetChip(
                amount: 3000000,
                isSelected: _monthlyBudget == 3000000,
                onTap: (val) => setState(() {
                  _monthlyBudget = val;
                  _budgetController.text = RupiahFormatter.formatWithoutSymbol(val);
                }),
              ),
              _BudgetChip(
                amount: 5000000,
                isSelected: _monthlyBudget == 5000000,
                onTap: (val) => setState(() {
                  _monthlyBudget = val;
                  _budgetController.text = RupiahFormatter.formatWithoutSymbol(val);
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Atau ketik manual',
              hintText: 'Contoh: 2.500.000',
              prefixText: 'Rp ',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            onChanged: (val) {
              final digits = val.replaceAll('.', '').replaceAll(',', '');
              final parsed = double.tryParse(digits);
              if (parsed != null && parsed > 0) {
                setState(() => _monthlyBudget = parsed);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _WalletInputRow extends StatelessWidget {
  final String icon;
  final String name;
  final TextEditingController controller;
  final ThemeData theme;

  const _WalletInputRow({
    required this.icon,
    required this.name,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(name, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              prefixText: 'Rp ',
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final ValueChanged<double> onTap;

  const _BudgetChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(RupiahFormatter.compact(amount)),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      onSelected: (_) => onTap(amount),
    );
  }
}
