import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/payments_api.dart';
import 'package:creditbillsytems/features/payments/data/php_payment_repository.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';

class FakePaymentsApi {
  List<PaymentModel> _payments = [];
  PaymentModel? _singlePayment;
  Exception? _exceptionToThrow;
  String? _deletedPaymentId;

  void setPayments(List<PaymentModel> payments) { _payments = payments; }
  void setSinglePayment(PaymentModel payment) { _singlePayment = payment; }
  void setException(Exception exception) { _exceptionToThrow = exception; }
  String? get deletedPaymentId => _deletedPaymentId;

  Future<List<PaymentModel>> getPayments() async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _payments;
  }

  Future<PaymentModel> getPayment(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    if (_singlePayment == null) throw DatabaseException('Payment not found', code: 'NOT_FOUND');
    return _singlePayment!;
  }

  Future<PaymentModel> recordPayment(PaymentRequest request) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return PaymentModel(
      id: 'new-payment-id',
      billId: request.billId,
      cardId: request.cardId,
      amount: request.amount,
      date: DateTime.now(),
      note: request.note,
    );
  }

  Future<void> deletePayment(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    _deletedPaymentId = id;
  }
}

class FakePaymentsApiWrapper implements PaymentsApi {
  final FakePaymentsApi _fake;
  FakePaymentsApiWrapper(this._fake);
  @override Future<List<PaymentModel>> getPayments() => _fake.getPayments();
  @override Future<PaymentModel> getPayment(String id) => _fake.getPayment(id);
  @override Future<PaymentModel> recordPayment(PaymentRequest request) => _fake.recordPayment(request);
  @override Future<void> deletePayment(String id) => _fake.deletePayment(id);
}

void main() {
  group('PhpPaymentRepository', () {
    late FakePaymentsApi fakePaymentsApi;
    late PhpPaymentRepository repository;

    setUp(() {
      fakePaymentsApi = FakePaymentsApi();
      final fakeApiWrapper = FakePaymentsApiWrapper(fakePaymentsApi);
      repository = PhpPaymentRepository(paymentsApi: fakeApiWrapper);
    });

    group('recordPayment', () {
      test('records payment and returns model with generated ID', () async {
        fakePaymentsApi.setPayments([]);
        final payment = await repository.recordPayment(userId: 'user-123', payment: PaymentModel(
          id: '', billId: 'bill-1', cardId: 'card-1', amount: 100.00,
          date: DateTime.now(), note: 'Monthly payment',
        ));
        expect(payment.id, 'new-payment-id');
        expect(payment.billId, 'bill-1');
        expect(payment.amount, 100.00);
        expect(payment.note, 'Monthly payment');
      });

      test('throws ValidationException on amount exceeds balance', () async {
        final repo = PhpPaymentRepository(paymentsApi: FakePaymentsApiWrapper(FakePaymentsApi()..setException(ValidationException('Exceeds balance', code: 'VALIDATION_ERROR'))));
        expect(() => repo.recordPayment(userId: 'user-123', payment: PaymentModel(id: '', billId: 'bill-1', cardId: 'card-1', amount: 100.00, date: DateTime.now())), throwsA(isA<ValidationException>()));
      });

      test('throws ValidationException on card/bill mismatch', () async {
        final repo = PhpPaymentRepository(paymentsApi: FakePaymentsApiWrapper(FakePaymentsApi()..setException(ValidationException('Mismatch', code: 'VALIDATION_ERROR'))));
        expect(() => repo.recordPayment(userId: 'user-123', payment: PaymentModel(id: '', billId: 'bill-1', cardId: 'wrong-card', amount: 50.00, date: DateTime.now())), throwsA(isA<ValidationException>()));
      });
    });

    group('getPayment', () {
      test('returns payment when found', () async {
        fakePaymentsApi.setSinglePayment(PaymentModel(id: 'payment-1', billId: 'bill-1', cardId: 'card-1', amount: 100.00, date: DateTime.now(), note: 'Monthly payment'));
        final payment = await repository.getPayment(userId: 'user-123', paymentId: 'payment-1');
        expect(payment, isNotNull);
        expect(payment!.id, 'payment-1');
        expect(payment.billId, 'bill-1');
        expect(payment.amount, 100.00);
        expect(payment.note, 'Monthly payment');
      });

      test('throws DatabaseException on not found', () async {
        expect(() => repository.getPayment(userId: 'user-123', paymentId: 'missing'), throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')));
      });
    });

    group('getPayments', () {
      test('returns list of payments', () async {
        fakePaymentsApi.setPayments([
          PaymentModel(id: 'payment-1', billId: 'bill-1', cardId: 'card-1', amount: 100.00, date: DateTime.now(), note: 'Monthly payment'),
          PaymentModel(id: 'payment-2', billId: 'bill-2', cardId: 'card-2', amount: 50.00, date: DateTime.now(), note: null),
        ]);
        final payments = await repository.getPayments(userId: 'user-123');
        expect(payments.length, 2);
        expect(payments[0].id, 'payment-1'); expect(payments[0].note, 'Monthly payment');
        expect(payments[1].id, 'payment-2'); expect(payments[1].note, isNull);
      });
    });

    group('watchPayments', () {
      test('emits payments once then empty list', () async {
        fakePaymentsApi.setPayments([PaymentModel(id: 'payment-1', billId: 'bill-1', cardId: 'card-1', amount: 100.00, date: DateTime.now(), note: 'Monthly payment')]);
        final stream = repository.watchPayments(userId: 'user-123');
        final events = await stream.toList();

        expect(events.length, 2);
        expect(events[0].length, 1);
        expect(events[1], isEmpty);
      });
    });

    group('deletePayment', () {
      test('deletes payment and returns void', () async {
        await repository.deletePayment(userId: 'user-123', paymentId: 'payment-1');
        expect(fakePaymentsApi.deletedPaymentId, 'payment-1');
      });

      test('throws exception on failure', () async {
        final repo = PhpPaymentRepository(paymentsApi: FakePaymentsApiWrapper(FakePaymentsApi()..setException(DatabaseException('Not found', code: 'NOT_FOUND'))));
        expect(() => repo.deletePayment(userId: 'user-123', paymentId: 'missing'), throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')));
      });
    });
  });
}