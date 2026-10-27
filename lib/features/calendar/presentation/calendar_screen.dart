import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../bills/domain/bill_model.dart';
import '../../bills/domain/bill_status.dart';
import '../../bills/presentation/bill_detail_screen.dart';
import '../domain/calendar_event.dart';
import 'calendar_provider.dart';

/// Interactive monthly calendar showing bill due dates with semantic status dots.
///
/// Tapping a highlighted date shows all bills due that day with a direct
/// "Record Payment" shortcut (FR-15).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();
    final userId = authProvider?.userId;
    if (userId == null || userId.isEmpty) {
      return const _UnauthenticatedState();
    }
    final calendarProvider = context.watch<CalendarProvider?>();
    if (calendarProvider == null) {
      return const _CalendarProviderUnavailableState();
    }

    if (calendarProvider.isLoading) {
      return const _LoadingState();
    }
    if (calendarProvider.errorMessage != null) {
      return _ErrorState(
        message: calendarProvider.errorMessage!,
        onRetry: calendarProvider.retry,
      );
    }

    final events = calendarProvider.events;
    final selectedEvents = calendarProvider.eventsForSelectedDay;
    final effectiveSelectedDay = _selectedDay ?? calendarProvider.selectedDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          _buildTableCalendar(context, events, calendarProvider, effectiveSelectedDay),
          const SizedBox(height: 16),
          Expanded(child: _buildDayPanel(effectiveSelectedDay, selectedEvents)),
        ],
      ),
    );
  }

  Widget _buildTableCalendar(
      BuildContext context,
      List<CalendarEvent> events,
      CalendarProvider calendarProvider,
      DateTime? effectiveSelectedDay) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: TableCalendar<CalendarEvent>(
        key: ValueKey(_calendarFormat.toString()),
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => _isSameDay(effectiveSelectedDay, day),
        eventLoader: (day) {
          return events.where((e) => _isSameDay(e.date, day)).toList();
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekVisible: true,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, dayEvents) {
            if (dayEvents.isEmpty) return null;
            final hasPending = dayEvents.any((e) => e.hasPending);
            final allPaid = dayEvents.every((e) => e.allPaid);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: hasPending
                    ? AppColors.healthRisk
                    : (allPaid ? AppColors.healthHealthy : AppColors.healthModerate),
                shape: BoxShape.circle,
              ),
              width: 8,
              height: 8,
            );
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          calendarProvider.selectDay(selectedDay);
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      ),
    );
  }

  Widget _buildDayPanel(DateTime? selectedDay, List<CalendarEvent> selectedEvents) {
    if (selectedDay == null) {
      return const _SelectDayState();
    }
    if (selectedEvents.isEmpty) {
      return const _NoBillsDayState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            DateFormatter.formatDisplay(selectedDay),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: selectedEvents.length,
            itemBuilder: (context, index) {
              return _CalendarEventCard(event: selectedEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Card showing bills due on the selected day, with a Record Payment shortcut.
class _CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final pending = event.bills.where(
      (b) => b.status == BillStatus.unpaid || b.status == BillStatus.partiallyPaid,
    );
    final paid = event.bills.where((b) => b.status == BillStatus.paid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        key: Key('calendar-event-${event.bills.first.id}'),
        title: Text(
          'Card ${event.bills.first.cardId}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              'Due: ${DateFormatter.formatDisplay(event.bills.first.dueDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (paid.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${paid.length} paid',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.healthHealthy,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              CurrencyFormatter.format(event.totalRemaining),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: pending.isNotEmpty
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(width: 8),
              FilledButton(
                key: Key('calendar-record-payment-${event.bills.first.id}'),
                onPressed: () => _openBillDetail(context, pending.first),
                child: const Text('Pay'),
              ),
            ],
          ],
        ),
        onTap: pending.isNotEmpty
            ? () => _openBillDetail(context, pending.first)
            : null,
      ),
    );
  }

  void _openBillDetail(BuildContext context, BillModel bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillDetailScreen(bill: bill),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
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
}

class _SelectDayState extends StatelessWidget {
  const _SelectDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 48, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            Text('Select a date',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap a day with a dot to see bills due that day.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NoBillsDayState extends StatelessWidget {
  const _NoBillsDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.healthHealthy),
            const SizedBox(height: 16),
            Text('No bills due',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('All clear for this date.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _UnauthenticatedState extends StatelessWidget {
  const _UnauthenticatedState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Sign in to view your calendar.'),
      ),
    );
  }
}

class _CalendarProviderUnavailableState extends StatelessWidget {
  const _CalendarProviderUnavailableState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Calendar storage is unavailable.'),
      ),
    );
  }
}
