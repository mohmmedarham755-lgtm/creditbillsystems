import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/errors/app_exceptions.dart';
import 'package:creditbillsytems/core/network/bills_api.dart';
import 'package:creditbillsytems/features/bills/data/php_bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';

class FakeBillsApi {
  List<BillModel> _bills = [];
  BillModel? _singleBill;
  Exception? _exceptionToThrow;

  void setBills(List<BillModel> bills) { _bills = bills; }
  void setSingleBill(BillModel bill) { _singleBill = bill; }
  void setException(Exception exception) { _exceptionToThrow = exception; }

  Future<List<BillModel>> getBills() async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _bills;
  }

  Future<BillModel> getBill(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    if (_singleBill == null) throw DatabaseException('Bill not found', code: 'NOT_FOUND');
    return _singleBill!;
  }

  Future<BillModel> createBill(BillRequest request) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return BillModel(
      id: 'new-bill-id',
      cardId: request.cardId,
      statementDate: DateTime.parse(request.statementDate),
      dueDate: DateTime.parse(request.dueDate),
      totalAmountDue: request.totalAmountDue,
      remainingBalance: request.remainingBalance,
      minimumDue: request.minimumDue,
      status: BillStatus.unpaid,
    );
  }

  Future<BillModel> updateBill(String id, BillRequest request) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return BillModel(
      id: id,
      cardId: request.cardId,
      statementDate: DateTime.parse(request.statementDate),
      dueDate: DateTime.parse(request.dueDate),
      totalAmountDue: request.totalAmountDue,
      remainingBalance: request.remainingBalance,
      minimumDue: request.minimumDue,
      status: BillStatus.unpaid,
    );
  }

  Future<void> deleteBill(String id) async {
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
  }
}

class FakeBillsApiWrapper implements BillsApi {
  final FakeBillsApi _fake;
  FakeBillsApiWrapper(this._fake);
  @override Future<List<BillModel>> getBills() => _fake.getBills();
  @override Future<BillModel> getBill(String id) => _fake.getBill(id);
  @override Future<BillModel> createBill(BillRequest request) => _fake.createBill(request);
  @override Future<BillModel> updateBill(String id, BillRequest request) => _fake.updateBill(id, request);
  @override Future<void> deleteBill(String id) => _fake.deleteBill(id);
}

void main() {
  group('PhpBillRepository', () {
    late FakeBillsApi fakeBillsApi;
    late PhpBillRepository repository;

    setUp(() {
      fakeBillsApi = FakeBillsApi();
      final fakeApiWrapper = FakeBillsApiWrapper(fakeBillsApi);
      repository = PhpBillRepository(billsApi: fakeApiWrapper);
    });

    group('createBill', () {
      test('creates bill and returns model with generated ID', () async {
        fakeBillsApi.setBills([]);
        final bill = BillModel(
          id: '',
          cardId: 'card-1',
          statementDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 25),
          totalAmountDue: 500.00,
          remainingBalance: 500.00,
          minimumDue: 50.00,
          status: BillStatus.unpaid,
        );
        final created = await repository.createBill(userId: 'user-123', bill: bill);
        expect(created.id, 'new-bill-id');
        expect(created.cardId, 'card-1');
        expect(created.totalAmountDue, 500.00);
        expect(created.status, BillStatus.unpaid);
      });

      test('throws ValidationException on validation error', () async {
        final repo = PhpBillRepository(
          billsApi: FakeBillsApiWrapper(FakeBillsApi()..setException(ValidationException('Invalid input', code: 'VALIDATION_ERROR'))),
        );
        expect(() => repo.createBill(userId: 'user-123', bill: BillModel(
          id: '', cardId: '',
          statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25),
          totalAmountDue: 500, remainingBalance: 500, minimumDue: 50, status: BillStatus.unpaid,
        )), throwsA(isA<ValidationException>()));
      });
    });

    group('getBill', () {
      test('returns bill when found', () async {
        fakeBillsApi.setSingleBill(BillModel(
          id: 'bill-1', cardId: 'card-1',
          statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25),
          totalAmountDue: 500.00, remainingBalance: 500.00, minimumDue: 50.00, status: BillStatus.unpaid,
        ));
        final bill = await repository.getBill(userId: 'user-123', billId: 'bill-1');
        expect(bill, isNotNull);
        expect(bill!.id, 'bill-1');
        expect(bill.cardId, 'card-1');
        expect(bill.totalAmountDue, 500.00);
        expect(bill.status, BillStatus.unpaid);
      });

      test('throws DatabaseException on not found', () async {
        expect(() => repository.getBill(userId: 'user-123', billId: 'missing'),
          throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')));
      });
    });

    group('getBills', () {
      test('returns list of bills', () async {
        fakeBillsApi.setBills([
          BillModel(id: 'bill-1', cardId: 'card-1', statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25), totalAmountDue: 500.00, remainingBalance: 500.00, minimumDue: 50.00, status: BillStatus.unpaid),
          BillModel(id: 'bill-2', cardId: 'card-2', statementDate: DateTime(2026, 9, 1), dueDate: DateTime(2026, 9, 25), totalAmountDue: 300.00, remainingBalance: 0.00, minimumDue: 30.00, status: BillStatus.paid),
        ]);
        final bills = await repository.getBills(userId: 'user-123');
        expect(bills.length, 2);
        expect(bills[0].id, 'bill-1'); expect(bills[0].status, BillStatus.unpaid);
        expect(bills[1].id, 'bill-2'); expect(bills[1].status, BillStatus.paid);
      });
    });

    group('updateBill', () {
      test('updates bill successfully', () async {
        final bill = BillModel(id: 'bill-1', cardId: 'card-1', statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25), totalAmountDue: 500.00, remainingBalance: 250.00, minimumDue: 50.00, status: BillStatus.unpaid);
        await repository.updateBill(userId: 'user-123', bill: bill);
      });

      test('throws DatabaseException on not found', () async {
        final repo = PhpBillRepository(billsApi: FakeBillsApiWrapper(FakeBillsApi()..setException(DatabaseException('Not found', code: 'NOT_FOUND'))));
        expect(() => repo.updateBill(userId: 'user-123', bill: BillModel(id: 'missing', cardId: 'card-1', statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25), totalAmountDue: 500, remainingBalance: 250, minimumDue: 50, status: BillStatus.unpaid)), throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'NOT_FOUND')));
      });
    });

    group('deleteBill', () {
      test('deletes bill successfully', () async { await repository.deleteBill(userId: 'user-123', billId: 'bill-1'); });

      test('throws DatabaseException on conflict (has payments)', () async {
        final repo = PhpBillRepository(billsApi: FakeBillsApiWrapper(FakeBillsApi()..setException(DatabaseException('Has payments', code: 'CONFLICT'))));
        expect(() => repo.deleteBill(userId: 'user-123', billId: 'bill-with-payments'), throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'CONFLICT')));
      });
    });

    group('watchBills', () {
      test('emits bills once then empty list', () async {
        fakeBillsApi.setBills([BillModel(id: 'bill-1', cardId: 'card-1', statementDate: DateTime(2026, 10, 1), dueDate: DateTime(2026, 10, 25), totalAmountDue: 500.00, remainingBalance: 500.00, minimumDue: 50.00, status: BillStatus.unpaid)]);
        final stream = repository.watchBills(userId: 'user-123');
        final events = await stream.toList();

        expect(events.length, 2);
        expect(events[0].length, 1);
        expect(events[1], isEmpty);
      });
    });
  });
}