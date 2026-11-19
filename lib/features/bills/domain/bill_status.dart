/// Lifecycle state of a bill statement.
enum BillStatus {
  /// Statement has not been paid yet and is still within the due window.
  unpaid,

  /// A partial payment has been made; some balance remains and is current.
  partiallyPaid,

  /// The bill has been paid in full.
  paid,

  /// The due date has passed and a balance remains unpaid.
  overdue,
}
