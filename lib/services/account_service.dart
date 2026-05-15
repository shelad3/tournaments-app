import 'package:cloud_functions/cloud_functions.dart';

class AccountService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> deleteAccount() async {
    try {
      final result = await _functions.httpsCallable('deleteAccount').call();
      return (result.data as Map<String, dynamic>)['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
