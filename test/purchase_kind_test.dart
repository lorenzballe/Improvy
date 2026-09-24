import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/services/purchase_service.dart';

/// `pro_purchase_success` must mean money. These are the three ways a
/// purchase can complete, and only one of them is a sale.
void main() {
  final started = DateTime.utc(2026, 9, 24, 10, 43, 45);

  test('a sandbox account is never a sale, whatever the date', () {
    expect(
      PurchaseService.classifyPurchase(
          sandbox: true, transactionDate: started, startedAt: started),
      PurchaseKind.sandbox,
    );
  });

  test('a transaction made during the purchase is a sale', () {
    expect(
      PurchaseService.classifyPurchase(
          sandbox: false,
          transactionDate: started.add(const Duration(seconds: 20)),
          startedAt: started),
      PurchaseKind.paid,
    );
  });

  test('a phone clock a minute behind the store still reads as a sale', () {
    expect(
      PurchaseService.classifyPurchase(
          sandbox: false,
          transactionDate: started.subtract(const Duration(minutes: 1)),
          startedAt: started),
      PurchaseKind.paid,
    );
  });

  test('an old transaction handed back is a re-delivery, not a sale', () {
    expect(
      PurchaseService.classifyPurchase(
          sandbox: false,
          transactionDate: DateTime.utc(2026, 8, 2),
          startedAt: started),
      PurchaseKind.redelivered,
    );
  });

  test('no date at all is still a sale when the account is real', () {
    expect(
      PurchaseService.classifyPurchase(
          sandbox: false, transactionDate: null, startedAt: started),
      PurchaseKind.paid,
    );
  });

  group('the discount the app states is the one the store charges', () {
    test('€20.99 → €17.99 says 14%, not the 10% written on the code', () {
      expect(PurchaseService.discountPercent(regular: 20.99, discounted: 17.99, fallback: 10), 14);
    });
    test('an exact 10% says 10', () {
      expect(PurchaseService.discountPercent(regular: 20.00, discounted: 18.00, fallback: 5), 10);
    });
    test('no saving, or prices unread, falls back to the code', () {
      expect(PurchaseService.discountPercent(regular: 19.99, discounted: 19.99, fallback: 10), 10);
      expect(PurchaseService.discountPercent(regular: 0, discounted: 17.99, fallback: 10), 10);
    });
  });
}
