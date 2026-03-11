import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuraHistoryScreen extends StatefulWidget {
  const AuraHistoryScreen({super.key});

  @override
  State<AuraHistoryScreen> createState() => _AuraHistoryScreenState();
}

class _AuraHistoryScreenState extends State<AuraHistoryScreen> {
  String _filter = 'all'; // 'all', 'received', 'spent'
  List<AuraTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransactions();
    });
  }

  Future<void> _fetchTransactions() async {
    final apiService = context.read<ApiService>();
    try {
      final data = await apiService.getAuraHistory();
      if (!mounted) return;
      setState(() {
        _transactions = data.map((json) => AuraTransaction.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history')),
      );
    }
  }

  List<AuraTransaction> _getFilteredTransactions(List<AuraTransaction> transactions) {
    if (_filter == 'received') {
      return transactions.where((t) => t.amount > 0).toList();
    } else if (_filter == 'spent') {
      return transactions.where((t) => t.amount < 0).toList();
    }
    return transactions;
  }

  int _getTotalReceived(List<AuraTransaction> transactions) =>
      transactions.where((t) => t.amount > 0).fold(0, (s, t) => s + t.amount);
  
  int _getTotalSpent(List<AuraTransaction> transactions) => transactions
      .where((t) => t.amount < 0)
      .fold(0, (s, t) => s + t.amount.abs());

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions(_transactions);
    final totalReceived = _getTotalReceived(_transactions);
    final totalSpent = _getTotalSpent(_transactions);

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Aura History',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '+$totalReceived',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Earned',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '-$totalSpent',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Spent',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter Chips ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Earned',
                  isActive: _filter == 'received',
                  onTap: () => setState(() => _filter = 'received'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Spent',
                  isActive: _filter == 'spent',
                  onTap: () => setState(() => _filter = 'spent'),
                ),
              ],
            ),
          ),

          // ── Transaction List ────────────────
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AuraBuddyTheme.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions',
                          style: GoogleFonts.inter(
                            color: AuraBuddyTheme.textLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final tx = filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: AuraBuddyTheme.whiteCard(),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (tx.isPositive
                                          ? AuraBuddyTheme.success
                                          : AuraBuddyTheme.danger)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: tx.emoji == '✨'
                                      ? AuraBuddyTheme.auraIcon(size: 20)
                                      : Text(
                                          tx.emoji,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AuraBuddyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _timeAgo(tx.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AuraBuddyTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isPositive ? '+' : ''}${tx.amount}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      tx.isPositive
                                          ? AuraBuddyTheme.success
                                          : AuraBuddyTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? AuraBuddyTheme.primary
                  : AuraBuddyTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isActive ? Colors.white : AuraBuddyTheme.primary,
          ),
        ),
      ),
    );
  }
}

