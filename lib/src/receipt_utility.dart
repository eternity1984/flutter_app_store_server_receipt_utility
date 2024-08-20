import 'dart:convert' show utf8, base64;

import 'constants.dart';
import 'package:pointycastle/pointycastle.dart';

final class ReceiptUtility {
  ReceiptUtility._();

  /// Extracts a transaction id from an encoded App Receipt. Throws if the receipt does not match the expected format.
  /// *NO validation* is performed on the receipt, and any data returned should only be used to call the App Store Server API.
  ///
  /// Takes the [appReceipt] of the unmodified app receipt
  ///
  /// Returns a transaction id from the array of in-app purchases, null if the receipt contains no in-app purchases
  ///
  static String? extractTransactionIdFromAppReceipt(
    String appReceipt,
  ) {
    final parser = ASN1Parser(base64.decode(appReceipt));
    final root = parser.nextObject();
    if (root is ASN1Sequence) {
      final id = root.elements![0] as ASN1ObjectIdentifier;
      if (id.objectIdentifierAsString == PKCS7_OID) {
        final signedData =
            ASN1Sequence.fromBytes(root.elements![1].valueBytes!);

        // OID should be 1.2.840.113549.1.7.1
        final content = signedData.elements![2] as ASN1Sequence;
        var receiptInfo =
            ASN1OctetString.fromBytes(content.elements![1].valueBytes!);

        // 0x04	OCTET STRING
        if (receiptInfo.valueBytes![0] == 4) {
          receiptInfo = receiptInfo.elements![0] as ASN1OctetString;
        }

        for (var sequence
            in ASN1Set.fromBytes(receiptInfo.valueBytes!).elements ?? []) {
          if ((sequence is ASN1Sequence) && (sequence.elements?.length == 3)) {
            final typeId = sequence.elements![0] as ASN1Integer;
            if (typeId.integer!.toInt() == IN_APP_TYPE_ID) {
              final inAppRoot = ASN1Set.fromBytes(
                  (sequence.elements![2] as ASN1OctetString).valueBytes!);

              for (ASN1Sequence sequence in inAppRoot.elements!.cast()) {
                if (sequence.elements?.length == 3) {
                  final transTypeId =
                      (sequence.elements![0] as ASN1Integer).integer!.toInt();
                  if ((transTypeId == TRANSACTION_IDENTIFIER_TYPE_ID) ||
                      (transTypeId ==
                          ORIGINAL_TRANSACTION_IDENTIFIER_TYPE_ID)) {
                    final transactionId = ASN1UTF8String.fromBytes(
                        sequence.elements![2].valueBytes!);
                    return transactionId.utf8StringValue;
                  }
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Extracts a transaction id from an encoded transactional receipt. Throws if the receipt does not match the expected format.
  /// *NO validation* is performed on the receipt, and any data returned should only be used to call the App Store Server API.
  ///
  /// Takes the [transactionReceipt] of the unmodified transactionReceipt
  ///
  /// Returns a transaction id, or null if no transactionId is found in the receipt
  ///
  static String? extractTransactionIdFromTransactionReceipt(
    String transactionReceipt,
  ) {
    final decodedTopLevel = utf8.decode(base64.decode(transactionReceipt));
    final matchingResult = RegExp(r'"purchase-info"\s+=\s+"([a-zA-Z0-9+/=]+)";')
        .firstMatch(decodedTopLevel);
    String? encodedPurchaseInfo =
        (matchingResult?.groupCount == 1) ? matchingResult?.group(1) : null;
    if (encodedPurchaseInfo == null) {
      return null;
    }

    final decodedInnerLevel = utf8.decode(base64.decode(encodedPurchaseInfo));
    final innerMatchingResult =
        RegExp(r'"transaction-id"\s+=\s+"([a-zA-Z0-9+/=]+)";')
            .firstMatch(decodedInnerLevel);
    return (innerMatchingResult?.groupCount == 1)
        ? innerMatchingResult?.group(1)
        : null;
  }
}
