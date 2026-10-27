import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../payments/domain/payment_model.dart';
import '../../payments/domain/payment_repository.dart';
import '../domain/bill_model.dart';
import '../domain/bill_repository.dart';
import '../domain/bill_status.dart';
import '../domain/bill_status_evaluator.dart';

/// State controller for bill statements and lifecycle.
class BillProvider extends ChangeNotifier {
  final BillRepository _billRepository;
  final PaymentRepository _paymentRepository;

  AuthProvider? _authProvider;
  StreamSubscription<List<BillModel>>? _billsSubscription;
  String? _authenticatedUserId;
  int _userGeneration = 0;
  int _billsStreamGeneration = 0;
  int _paymentsStreamGeneration = 0;
  bool _disposed = false;

  final List<BillModel> _bills = [];
  final List<PaymentModel> _payments = [];
  StreamSubscription<List<PaymentModel>>? _paymentsSubscription;
  BillStatus? _billFilter;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  BillProvider({
    required BillRepository billRepository,
    AuthProvider? authProvider,
    required PaymentRepository paymentRepository,
  })  : _billRepository = billRepository,
        _paymentRepository = paymentRepository {
    bindAuthProvider(authProvider);
  }

  BillRepository _getRepository() => _billRepository;

  PaymentRepository _getPaymentRepository() => _paymentRepository;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasAuthenticatedUser =>
      _authenticatedUserId != null && _authenticatedUserId!.isNotEmpty;
  String? get errorMessage => _errorMessage;
  BillStatus? get billFilter => _billFilter;
  List<BillModel> get bills => List.unmodifiable(_bills);

  /// All payments for the authenticated user, ordered by date descending.
  List<PaymentModel> get payments => List.unmodifiable(_payments);

  /// Payments for a specific bill, ordered by date descending (newest first).
  List<PaymentModel> paymentsForBill(String billId) {
    return _payments
        .where((payment) => payment.billId == billId)
        .toList(growable: false);
  }

  /// Bills filtered by the currently selected status filter.
  /// When no filter is selected, returns all bills.
  List<BillModel> get filteredBills {
    if (_billFilter == null) {
      return List.unmodifiable(_bills);
    }
    return List.unmodifiable(
      _bills.where((bill) => bill.status == _billFilter).toList(),
    );
  }

  /// Sets the client-side status filter. Passing null clears the filter.
  void setBillFilter(BillStatus? filter) {
    if (_billFilter == filter) return;
    _billFilter = filter;
    notifyListeners();
  }

  void bindAuthProvider(AuthProvider? authProvider) {
    if (identical(_authProvider, authProvider)) return;
    _authProvider?.removeListener(_handleAuthChange);
    _authProvider = authProvider;
    _setAuthenticatedUserId(authProvider?.userId);
    authProvider?.addListener(_handleAuthChange);
    if (authProvider?.userId == _authenticatedUserId &&
        hasAuthenticatedUser &&
        _billsSubscription == null) {
      _subscribeToBills();
    }
  }

  void _handleAuthChange() {
    _setAuthenticatedUserId(_authProvider?.userId);
  }

  void _setAuthenticatedUserId(String? userId) {
    if (_authenticatedUserId == userId) return;
    _authenticatedUserId = userId;
    _userGeneration++;
    _billsStreamGeneration++;
    _paymentsStreamGeneration++;
    _billsSubscription?.cancel();
    _billsSubscription = null;
    _paymentsSubscription?.cancel();
    _paymentsSubscription = null;
    _bills.clear();
    _payments.clear();
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    if (hasAuthenticatedUser) {
      _subscribeToBills();
      _subscribeToPayments();
      return;
    }
    notifyListeners();
  }

  void _subscribeToBills() {
    final userId = _authenticatedUserId;
    if (userId == null || userId.isEmpty) return;
    final repository = _getRepository();
    final generation = ++_billsStreamGeneration;
    _billsSubscription?.cancel();
    _billsSubscription = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      _billsSubscription = repository
          .watchBills(userId: userId)
          .listen(
            (bills) {
              if (!_isBillsCurrentStream(generation, userId)) return;
              final now = DateTime.now();
              final currentDate = DateTime(now.year, now.month, now.day);
              _bills
                ..clear()
                ..addAll(
                  bills.map((bill) {
                    final evaluatedStatus = BillStatusEvaluator.evaluate(
                      bill: bill,
                      currentDate: currentDate,
                    );
                    return evaluatedStatus == bill.status
                        ? bill
                        : bill.copyWith(status: evaluatedStatus);
                  }).toList(growable: false),
                );
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_isBillsCurrentStream(generation, userId)) return;
              _isLoading = false;
              _errorMessage = error is AppException
                  ? error.message
                  : 'Something went wrong while loading bills.';
              notifyListeners();
            },
            onDone: () {
              if (!_isBillsCurrentStream(generation, userId)) return;
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (error) {
      if (!_isBillsCurrentStream(generation, userId)) return;
      _isLoading = false;
      _errorMessage = error is AppException
          ? error.message
          : 'Something went wrong while loading bills.';
      notifyListeners();
    }
  }

  bool _isBillsCurrentStream(int generation, String userId) =>
      !_disposed &&
      generation == _billsStreamGeneration &&
      userId == _authenticatedUserId;

  /// Subscribes to the current authenticated user's payment stream.
  void _subscribeToPayments() {
    final userId = _authenticatedUserId;
    if (userId == null || userId.isEmpty) return;
    final repository = _getPaymentRepository();
    final generation = ++_paymentsStreamGeneration;
    _paymentsSubscription?.cancel();
    _paymentsSubscription = null;
    try {
      _paymentsSubscription = repository
          .watchPayments(userId: userId)
          .listen(
            (payments) {
              if (!_isPaymentsCurrentStream(generation, userId)) return;
              _payments
                ..clear()
                ..addAll(payments);
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_isPaymentsCurrentStream(generation, userId)) return;
              // Don't set _isLoading to false here as it's for bills
              _errorMessage = error is AppException
                  ? error.message
                  : 'Something went wrong while loading payments.';
              notifyListeners();
            },
            onDone: () {
              if (!_isPaymentsCurrentStream(generation, userId)) return;
              notifyListeners();
            },
          );
    } catch (error) {
      if (_isPaymentsCurrentStream(generation, userId)) {
        _errorMessage = error is AppException
            ? error.message
            : 'Something went wrong while loading payments.';
        notifyListeners();
      }
    }
  }

  bool _isPaymentsCurrentStream(int generation, String userId) =>
      !_disposed &&
      generation == _paymentsStreamGeneration &&
      userId == _authenticatedUserId;

  /// Re-subscribes to the current authenticated user's bill stream.
  void retryBills() {
    if (!hasAuthenticatedUser) return;
    _subscribeToBills();
    _subscribeToPayments();
  }

  /// Saves a new bill statement for the authenticated user.
  Future<bool> createBill({required BillModel bill}) async {
    if (_disposed) return false;
    _errorMessage = null;
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      _errorMessage = 'You must be signed in to log a bill.';
      notifyListeners();
      return false;
    }
    final repository = _getRepository();

    final requestGeneration = _userGeneration;
    _isSaving = true;
    notifyListeners();
    try {
      await repository.createBill(
        userId: userId,
        bill: bill,
      );
      if (_disposed ||
          requestGeneration != _userGeneration ||
          userId != _authenticatedUserId) {
        return false;
      }
      // Schedule local due-date reminders (FR-16). Best-effort: a failure
      // here must not roll back a successfully created bill.
      try {
        await NotificationService().initialize();
        await NotificationService().scheduleBillReminders(
          billId: bill.id,
          dueDate: bill.dueDate,
        );
      } catch (_) {
        // Notifications are best-effort; do not fail bill creation.
      }
      // The bill stream listener will add the saved bill to _bills.
      return true;
    } on AppException catch (error) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = 'Something went wrong while saving the bill.';
      }
      return false;
    } finally {
      if (!_disposed && requestGeneration == _userGeneration) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  /// Records a payment for the given bill for the authenticated user.
  ///
  /// The authenticated UID is obtained from the bound [AuthProvider]; the UI
  /// never supplies a user ID. The repository performs the atomic payment,
  /// bill, and card balance updates in a single Firestore transaction.
  Future<bool> recordPayment({
    required BillModel bill,
    required double amount,
    String? note,
  }) async {
    if (_disposed) return false;
    _errorMessage = null;
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      _errorMessage = 'You must be signed in to record a payment.';
      notifyListeners();
      return false;
    }
    if (_isSaving) return false;
    final repository = _getPaymentRepository();

    final requestGeneration = _userGeneration;
    _isSaving = true;
    notifyListeners();
    try {
      await repository.recordPayment(
        userId: userId,
        payment: PaymentModel(
          id: '',
          billId: bill.id,
          cardId: bill.cardId,
          amount: amount,
          date: DateTime.now(),
          note: note,
        ),
      );
      if (_disposed ||
          requestGeneration != _userGeneration ||
          userId != _authenticatedUserId) {
        return false;
      }
      // When the bill is fully paid, cancel its pending reminders (FR-17).
      if (bill.remainingBalance - amount <= 0) {
        try {
          await NotificationService().initialize();
          await NotificationService().cancelBillReminders(bill.id);
        } catch (_) {
          // Best-effort cancellation; does not fail payment recording.
        }
      }
      return true;
    } on AppException catch (error) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = 'Something went wrong while recording the payment.';
      }
      return false;
    } finally {
      if (!_disposed && requestGeneration == _userGeneration) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  /// Deletes a payment for the given bill for the authenticated user.
  ///
  /// The backend atomically deletes the payment and restores the bill's
  /// remaining balance, status, and the card's current balance.
  /// The bill stream will automatically refresh with updated balances.
  Future<bool> deletePayment({
    required String paymentId,
  }) async {
    if (_disposed) return false;
    _errorMessage = null;
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      _errorMessage = 'You must be signed in to delete a payment.';
      notifyListeners();
      return false;
    }
    if (_isSaving) return false;
    final repository = _getPaymentRepository();

    final requestGeneration = _userGeneration;
    _isSaving = true;
    notifyListeners();
    try {
      await repository.deletePayment(
        userId: userId,
        paymentId: paymentId,
      );
      if (_disposed ||
          requestGeneration != _userGeneration ||
          userId != _authenticatedUserId) {
        return false;
      }
      // When a payment is deleted and any bill still has a balance, re-schedule
      // reminders so the user is alerted again (FR-17 fallback).
      try {
        await NotificationService().initialize();
        for (final bill in _bills) {
          if (bill.remainingBalance > 0 &&
              (bill.status == BillStatus.unpaid ||
                  bill.status == BillStatus.partiallyPaid)) {
            await NotificationService().scheduleBillReminders(
              billId: bill.id,
              dueDate: bill.dueDate,
            );
          }
        }
      } catch (_) {
        // Best-effort re-scheduling; does not fail payment deletion.
      }
      return true;
    } on AppException catch (error) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!_disposed && requestGeneration == _userGeneration) {
        _errorMessage = 'Something went wrong while deleting the payment.';
      }
      return false;
    } finally {
      if (!_disposed && requestGeneration == _userGeneration) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  String? get _currentAuthenticatedUserId {
    final authProvider = _authProvider;
    if (authProvider == null ||
        authProvider.userId == null ||
        authProvider.userId!.isEmpty ||
        authProvider.userId != _authenticatedUserId) {
      return null;
    }
    return authProvider.userId;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _userGeneration++;
    _billsStreamGeneration++;
    _paymentsStreamGeneration++;
    _isLoading = false;
    _isSaving = false;
    _billsSubscription?.cancel();
    _billsSubscription = null;
    _paymentsSubscription?.cancel();
    _paymentsSubscription = null;
    _authProvider?.removeListener(_handleAuthChange);
    super.dispose();
  }
}
