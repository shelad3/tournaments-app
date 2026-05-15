import 'package:cloud_functions/cloud_functions.dart';

class MpesaResponse {
  final bool success;
  final String? checkoutRequestId;
  final String? message;

  MpesaResponse({required this.success, this.checkoutRequestId, this.message});
}

class MpesaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<MpesaResponse> stkPush({
    required String phone,
    required int amount,
    required String transactionRef,
  }) async {
    try {
      final result = await _functions.httpsCallable('stkPush').call({
        'phone': phone,
        'amount': amount,
        'transactionRef': transactionRef,
      });
      final data = result.data as Map<String, dynamic>;
      return MpesaResponse(
        success: data['success'] == true,
        checkoutRequestId: data['checkoutRequestId'],
        message: data['responseDescription'],
      );
    } on FirebaseFunctionsException catch (e) {
      return MpesaResponse(success: false, message: e.message ?? e.code);
    } catch (e) {
      return MpesaResponse(success: false, message: e.toString());
    }
  }

  Future<String> checkStatus(String ref) async {
    try {
      final result = await _functions.httpsCallable('checkTransactionStatus').call({'ref': ref});
      final data = result.data as Map<String, dynamic>;
      return data['status'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
