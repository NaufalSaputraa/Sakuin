import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budget/providers/budget_providers.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallets/domain/wallet_model.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../../../services/ml/text_parser_service.dart';
import '../providers/chat_providers.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isActionIntent(String text) {
    final lower = text.toLowerCase();
    final actionVerbs = RegExp(
      r'\b(catat|catatkan|masukkan|tambahkan|simpan|beli|bayar|isi|record|add|log|spend|paid)\b',
      caseSensitive: false,
    );
    final hasNumber = RegExp(r'\d+').hasMatch(text);
    return (actionVerbs.hasMatch(lower) && hasNumber) || lower.startsWith('1.') || lower.startsWith('-');
  }

  bool _isEnglish(String text) {
    final lower = text.toLowerCase();
    final engKeywords = RegExp(r'\b(how|what|my|budget|spend|spent|record|balance|money|please|can|you|advice|tips)\b');
    return engKeywords.hasMatch(lower);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    final chatRepo = ref.read(chatRepositoryProvider);
    _controller.clear();

    // 1. Save User Message to Database
    await chatRepo.addMessage(content: text, isUser: true);
    _scrollToBottom();

    setState(() {
      _isTyping = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final totalBalance = ref.read(totalBalanceProvider).asData?.value ?? 0.0;
    final income = ref.read(currentMonthIncomeProvider).asData?.value ?? 0.0;
    final expense = ref.read(currentMonthExpenseProvider).asData?.value ?? 0.0;
    final budget = ref.read(primaryBudgetProvider).asData?.value;
    final limit = budget?.amount ?? 3000000.0;
    final remainingBudget = limit - expense;
    final isEng = _isEnglish(text);

    // 2. Action Intent: Record Expenses
    if (_isActionIntent(text)) {
      final parser = ref.read(textParserServiceProvider);
      final wallets = ref.read(allWalletsProvider).asData?.value ?? <WalletModel>[];
      final categories = ref.read(allCategoriesProvider).asData?.value ?? <CategoryModel>[];
      final txRepo = ref.read(transactionRepositoryProvider);

      final batchResults = await parser.parseBatchText(
        text: text,
        availableWallets: wallets,
        availableCategories: categories,
      );

      final createdTitles = <String>[];
      double totalBatch = 0.0;

      for (final item in batchResults) {
        if (item.amount == null || item.amount! <= 0) continue;

        int? walletId;
        if (item.walletProvider != null) {
          final match = wallets.where((w) {
            if (item.walletProvider == 'physical') return w.isPhysical;
            return w.provider == item.walletProvider;
          }).firstOrNull;
          if (match != null) walletId = match.id;
        }
        walletId ??= (wallets.isNotEmpty ? wallets.first.id : 1);

        int? categoryId;
        if (item.categoryKey != null) {
          final match = categories.where((c) => c.key == item.categoryKey).firstOrNull;
          if (match != null) categoryId = match.id;
        }

        final res = await txRepo.createTransaction(
          walletId: walletId,
          categoryId: categoryId,
          amount: item.amount!,
          transactionType: item.transactionType,
          title: item.title,
          sourceInput: 'ai_chat',
          rawInput: item.rawInput,
        );

        if (res.isSuccess) {
          createdTitles.add('• ${item.title}: ${RupiahFormatter.format(item.amount!)}');
          totalBatch += item.amount!;
        }
      }

      if (createdTitles.isNotEmpty) {
        await HapticFeedback.mediumImpact();
        String reply;
        if (isEng) {
          reply = '✅ **Successfully recorded ${createdTitles.length} transaction(s)** (Total: **${RupiahFormatter.format(totalBatch)}**):\n\n${createdTitles.join("\n")}\n\nYour balance and budget limits have been updated.';
        } else {
          reply = '✅ **Berhasil mencatat ${createdTitles.length} transaksi** (Total: **${RupiahFormatter.format(totalBatch)}**):\n\n${createdTitles.join("\n")}\n\nSaldo dompet dan anggaran bulananmu telah diperbarui.';
        }

        await chatRepo.addMessage(content: reply, isUser: false);
        if (mounted) setState(() => _isTyping = false);
        _scrollToBottom();
        return;
      }
    }

    // 3. Conversational Advice & Intelligence
    String response;
    final lower = text.toLowerCase();

    if (isEng) {
      if (lower.contains('balance') || lower.contains('money') || lower.contains('how much')) {
        response = 'Your total active balance is **${RupiahFormatter.format(totalBalance)}** across your physical cash and digital e-wallets.';
      } else if (lower.contains('budget') || lower.contains('safe') || lower.contains('limit')) {
        if (expense > limit) {
          response = '⚠️ **Budget Alert:** You have spent **${RupiahFormatter.format(expense)}**, which exceeds your monthly limit of **${RupiahFormatter.format(limit)}**. We advise reducing non-essential spending.';
        } else {
          response = '✅ **Budget on Track!** You have spent **${RupiahFormatter.format(expense)}** out of your **${RupiahFormatter.format(limit)}** limit. You have **${RupiahFormatter.format(remainingBudget)}** remaining this month.';
        }
      } else if (lower.contains('tips') || lower.contains('advice') || lower.contains('save')) {
        response = '💡 **Gemma Financial Advice:**\n1. Follow the 50/30/20 rule: 50% Needs, 30% Wants, 20% Savings.\n2. Regularly log small daily micro-expenses (coffee, parking) to prevent hidden leaks.';
      } else {
        response = '📊 **Monthly Overview:**\n- Income: **+${RupiahFormatter.format(income)}**\n- Expenses: **-${RupiahFormatter.format(expense)}**\n- Total Balance: **${RupiahFormatter.format(totalBalance)}**\n- Remaining Budget: **${RupiahFormatter.format(remainingBudget)}**';
      }
    } else {
      if (lower.contains('saldo') || lower.contains('uang') || lower.contains('berapa')) {
        response = 'Total saldomu saat ini adalah **${RupiahFormatter.format(totalBalance)}** yang tersimpan di dompet fisik dan e-wallet digitalmu.';
      } else if (lower.contains('anggaran') || lower.contains('budget') || lower.contains('aman') || lower.contains('status')) {
        if (expense > limit) {
          response = '⚠️ **Peringatan Anggaran:** Pengeluaranmu (**${RupiahFormatter.format(expense)}**) telah melebihi batas bulanan (**${RupiahFormatter.format(limit)}**). Tahan pengeluaran hiburan dan belanja non-primer.';
        } else {
          response = '✅ **Anggaran Sangat Aman!** Kamu baru memakai **${RupiahFormatter.format(expense)}** dari batas **${RupiahFormatter.format(limit)}**. Sisa dana yang bisa kamu gunakan bulan ini: **${RupiahFormatter.format(remainingBudget)}**.';
        }
      } else if (lower.contains('saran') || lower.contains('tips') || lower.contains('nasihat') || lower.contains('hemat') || lower.contains('insight')) {
        response = '💡 **Insight & Nasihat Keuangan Gemma:**\n1. **Pantau Kategori Terbesar**: Cek tab Analytics untuk melihat kategori pengeluaran teratasmu.\n2. **Manfaatkan Dual Wallet**: Pisahkan uang operasional di Dompet Digital (GoPay/OVO) dan tabungan darurat di Dompet Fisik/Bank.\n3. **Cepat Catat**: Cukup ketik daftar pengeluaranmu di sini atau via Smart Input Bar kapan saja.';
      } else if (lower.contains('ringkasan') || lower.contains('rekap') || lower.contains('laporan')) {
        response = '📊 **Rekap Keuangan Bulan Ini:**\n- Pemasukan: **+${RupiahFormatter.format(income)}**\n- Pengeluaran: **-${RupiahFormatter.format(expense)}**\n- Saldo Aktif: **${RupiahFormatter.format(totalBalance)}**\n- Sisa Anggaran: **${RupiahFormatter.format(remainingBudget)}**';
      } else {
        response = 'Saya telah menganalisis catatan keuanganmu: Saldo aktifmu **${RupiahFormatter.format(totalBalance)}** dengan sisa anggaran **${RupiahFormatter.format(remainingBudget)}**.\n\nKamu bisa bertanya saran finansial atau langsung menyuruh saya mencatat transaksi (contoh: *"catatkan makan siang 25rb gopay dan bensin 50rb"*).';
      }
    }

    await chatRepo.addMessage(content: response, isUser: false);
    if (mounted) setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text('Semua pesan percakapan dengan asisten AI akan dihapus. Transaksi keuangan yang sudah tercatat di database tetap aman.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final chatRepo = ref.read(chatRepositoryProvider);
              await chatRepo.clearHistory();
              // Add fresh welcome message
              await chatRepo.addMessage(
                content: 'Halo! Percakapan baru telah dimulai. Ada yang bisa saya bantu terkait keuangan atau pencatatan transaksimu?',
                isUser: false,
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messagesAsync = ref.watch(chatMessagesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sakuin AI (Gemma)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  'On-Device Action Assistant',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Hapus Riwayat Chat',
            onPressed: _showClearHistoryDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Prompts Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _QuickPromptChip(
                    text: '📝 Catatkan list belanja',
                    onTap: () => _handleSend('Catatkan:\n1. Makan siang 30rb gopay\n2. Parkir 5rb cash\n3. Pulsa 50rb dana'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPromptChip(
                    text: '📊 Rekap keuangan',
                    onTap: () => _handleSend('Rekap keuangan bulan ini'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPromptChip(
                    text: '💡 Nasihat & tips hemat',
                    onTap: () => _handleSend('Beri aku saran dan tips hemat finansial'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPromptChip(
                    text: '🛡️ Status anggaran',
                    onTap: () => _handleSend('Apakah anggaranku masih aman?'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Messages Stream from SQLite
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _MessageBubble(
                        message: msg,
                        isDark: isDark,
                        onDelete: () async {
                          final chatRepo = ref.read(chatRepositoryProvider);
                          await chatRepo.deleteMessage(msg.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),

            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      'Gemma AI sedang memproses...',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF232338) : const Color(0xFFF0E5DA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ketik perintah / list pengeluaran / pertanyaan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF232338) : const Color(0xFFFFF8F0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _handleSend(_controller.text),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntry message;
  final bool isDark;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Pesan Ini?'),
            content: const Text('Pesan ini akan dihapus dari riwayat chat.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDelete();
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF232338) : const Color(0xFFFFF1E6)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: isUser
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickPromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      label: Text(text),
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
