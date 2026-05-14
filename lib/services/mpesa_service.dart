import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MpesaResponse {
  final bool success;
  final String? checkoutRequestId;
  final String? message;

  MpesaResponse({required this.success, this.checkoutRequestId, this.message});
}

class MpesaService {
  final String baseUrl = AppConfig.mpesaBackendUrl;

  Future<MpesaResponse> stkPush({
    required String phone,
    required int amount,
    required String userId,
    required String transactionRef,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mpesa/stkpush'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'amount': amount,
          'userId': userId,
          'transactionRef': transactionRef,
        }),
      );
      final data = jsonDecode(res.body);
      return MpesaResponse(
        success: data['success'] == true,
        checkoutRequestId: data['checkoutRequestId'],
        message: data['responseDescription'] ?? data['error'],
      );
    } catch (e) {
      return MpesaResponse(success: false, message: e.toString());
    }
  }

  Future<MpesaResponse> b2cPayment({
    required String phone,
    required int amount,
    required String userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mpesa/b2c'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'amount': amount,
          'userId': userId,
        }),
      );
      final data = jsonDecode(res.body);
      return MpesaResponse(
        success: data['success'] == true,
        message: data['message'] ?? data['error'],
      );
    } catch (e) {
      return MpesaResponse(success: false, message: e.toString());
    }
  }

  Future<String> checkStatus(String ref) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/mpesa/status/$ref'));
      final data = jsonDecode(res.body);
      return data['status'] ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
