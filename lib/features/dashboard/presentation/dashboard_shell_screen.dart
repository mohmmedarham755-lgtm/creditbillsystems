// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/credit_calculator.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../bills/domain/bill_model.dart';
import '../../bills/domain/bill_status.dart';
import '../../bills/presentation/bills_tab_screen.dart';
import '../../bills/presentation/bill_detail_screen.dart';
import '../../bills/presentation/bill_provider.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../cards/presentation/card_carousel.dart';
import '../../cards/presentation/card_provider.dart';
import 'dart:io';

import '../../settings/domain/settings_repository.dart';
import '../../settings/presentation/settings_screen.dart';
import 'utilization_gauge_widget.dart';

/// Main navigation shell housing the Material 3 NavigationBar.
class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _currentIndex = 0;
  String? _adminLogoPath;
  bool _logoLoadAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _logoLoadAttempted = false;
      return;
    }
    if (!_logoLoadAttempted) {
      _logoLoadAttempted = true;
      _loadAdminLogo();
    }
  }

  Future<void> _loadAdminLogo() async {
    try {
      final repo = context.read<SettingsRepository?>();
      if (repo == null) return;
      final settings = await repo.getSettings();
      if (!mounted) return;
      setState(() {
        _adminLogoPath = settings.logoPath;
      });
    } catch (_) {
      // Best-effort; keep default icon.
    }
  }

  Widget _buildBrandLogo(BuildContext context) {
    final path = _adminLogoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          key: const Key('dashboard-brand-logo'),
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            file,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _BrandLogoFallback(),
          ),
        );
      }
    }
    return const _BrandLogoFallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildBrandLogo(context),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Credit Bill System',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _DashboardTab(),
          const BillsTabScreen(),
          const CalendarScreen(),
          SettingsScreen(
            onLogoChanged: () {
              if (mounted) _loadAdminLogo();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 3) _loadAdminLogo();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider?>();
    final billProvider = context.watch<BillProvider?>();

    return RefreshIndicator(
      onRefresh: () async {
        cardProvider?.retryPortfolio();
        billProvider?.retryBills();
      },
      child: SingleChildScrollView(
        key: const Key('dashboard-tab-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (cardProvider != null &&
                cardProvider.hasAuthenticatedUser &&
                !cardProvider.isPortfolioLoading &&
                cardProvider.portfolioErrorMessage == null) ...[
              Center(
                key: const Key('dashboard-utilization-gauge-center'),
                child: UtilizationGaugeWidget(
                  utilizationPercentage: CreditCalculator.calculateUtilization(
                    totalBalance: cardProvider.totalCurrentBalance,
                    totalLimit: cardProvider.totalCreditLimit,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Limit',
                      value: CurrencyFormatter.format(
                        cardProvider.totalCreditLimit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Unpaid',
                      value: CurrencyFormatter.format(
                        cardProvider.totalCurrentBalance,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Your cards',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const CardCarousel(),
            const SizedBox(height: 24),
            Text(
              'Upcoming Bills',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (billProvider == null)
              const _BillProviderUnavailableState()
            else if (!billProvider.hasAuthenticatedUser)
              const _UnauthenticatedBillsState()
            else if (billProvider.errorMessage != null)
              _BillsErrorState(
                message: billProvider.errorMessage!,
                onRetry: billProvider.retryBills,
              )
            else if (billProvider.isLoading)
              const _BillsLoadingState()
            else
              _UpcomingBillsList(bills: billProvider.bills),
          ],
        ),
      ),
    );
  }
}

/// Displays one metric value with a title inside a card.
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Shows when BillProvider is not available in the widget tree.
class _BillProviderUnavailableState extends StatelessWidget {
  const _BillProviderUnavailableState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Bill storage is unavailable.'),
    ),
  );
}

/// Shows when no user is authenticated.
class _UnauthenticatedBillsState extends StatelessWidget {
  const _UnauthenticatedBillsState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Sign in to view your bills.'),
    ),
  );
}

/// Shows while bills are loading.
class _BillsLoadingState extends StatelessWidget {
  const _BillsLoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );
}

/// Shows when bill loading fails, with a retry action.
class _BillsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BillsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

/// Displays the top upcoming bills sorted by due date (closest first).
class _UpcomingBillsList extends StatelessWidget {
  final List<BillModel> bills;

  const _UpcomingBillsList({required this.bills});

  @override
  Widget build(BuildContext context) {
    final sorted = List<BillModel>.from(bills)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final topThree = sorted.take(3).toList();

    if (topThree.isEmpty) {
      // Fixed: use a simple Center widget with the expected text.
      return const Center(child: Text('No upcoming bills.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...topThree.map(
          (bill) => _UpcomingBillTile(
            key: Key('dashboard-bill-${bill.id}'),
            bill: bill,
          ),
        ),
      ],
    );
  }
}

class _BrandLogoFallback extends StatelessWidget {
  const _BrandLogoFallback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: Key('dashboard-brand-logo-fallback'),
      width: 28,
      height: 28,
      child: Icon(Icons.credit_card, size: 22),
    );
  }
}

/// Displays one upcoming bill in a compact list tile.
class _UpcomingBillTile extends StatelessWidget {
  final BillModel bill;

  const _UpcomingBillTile({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.status == BillStatus.overdue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Card ${bill.cardId}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              'Due: ${DateFormatter.formatDisplay(bill.dueDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Status: ${_statusDisplayName(bill.status)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOverdue ? Theme.of(context).colorScheme.error : null,
                fontWeight: isOverdue ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(bill.remainingBalance),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOverdue ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum: ${CurrencyFormatter.format(bill.minimumDue)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
          );
        },
      ),
    );
  }

  String _statusDisplayName(BillStatus status) {
    final name = status.name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
