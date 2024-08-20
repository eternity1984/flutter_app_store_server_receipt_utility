import 'dart:io';

import 'package:flutter_app_store_server_receipt_utility/receipt_utility.dart';
import 'package:flutter_test/flutter_test.dart';

const APP_RECEIPT_EXPECTED_TRANSACTION_ID = "0";
const TRANSACTION_RECEIPT_EXPECTED_TRANSACTION_ID = "33993399";

String load(String path) {
  return File(path).readAsStringSync();
}

void main() {
  test('xcode-app-receipt-empty', () {
    final receipt = load("test/resources/xcode-app-receipt-empty");
    final extractedTransactionId =
        ReceiptUtility.extractTransactionIdFromAppReceipt(receipt);
    expect(extractedTransactionId, null);
  });
  test('xcode-app-receipt-with-transaction', () {
    final receipt = load("test/resources/xcode-app-receipt-with-transaction");
    final extractedTransactionId =
        ReceiptUtility.extractTransactionIdFromAppReceipt(receipt);
    expect(extractedTransactionId, APP_RECEIPT_EXPECTED_TRANSACTION_ID);
  });
  test('legacy-transaction', () {
    final receipt = load("test/resources/legacy-transaction");
    final extractedTransactionId =
        ReceiptUtility.extractTransactionIdFromTransactionReceipt(receipt);
    expect(extractedTransactionId, TRANSACTION_RECEIPT_EXPECTED_TRANSACTION_ID);
  });
}
