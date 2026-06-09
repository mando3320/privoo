// lib/services/payment_service.dart
/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';

enum PaymentGateway { paymob, fawry, paypal, stripe }

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();
  
  static const String _paymobApiKey = 'YOUR_PAYMOB_API_KEY';
  static const String _paymobIntegrationId = 'YOUR_INTEGRATION_ID';
  static const String _fawryMerchantCode = 'YOUR_MERCHANT_CODE';
  
  Future<Map<String, dynamic>?> createPayMobPayment({
    required int amount,
    required String currency,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final authResponse = await http.post(
        Uri.parse('https://accept.paymob.com/api/auth/tokens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': _paymobApiKey}),
      );
      if (authResponse.statusCode != 200) return null;
      
      final authData = jsonDecode(authResponse.body);
      final token = authData['token'];
      
      final orderResponse = await http.post(
        Uri.parse('https://accept.paymob.com/api/ecommerce/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': token,
          'delivery_needed': false,
          'amount_cents': amount * 100,
          'currency': currency,
          'items': [],
        }),
      );
      if (orderResponse.statusCode != 200) return null;
      
      final orderData = jsonDecode(orderResponse.body);
      final orderId = orderData['id'];
      
      final paymentResponse = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payment_keys'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': token,
          'amount_cents': amount * 100,
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone_number': phone,
            'country': 'EG',
          },
          'currency': currency,
          'integration_id': _paymobIntegrationId,
        }),
      );
      
      if (paymentResponse.statusCode != 200) return null;
      final paymentData = jsonDecode(paymentResponse.body);
      
      return {
        'token': paymentData['token'],
        'iframeUrl': 'https://accept.paymob.com/api/acceptance/iframes/YOUR_IFRAME_ID?payment_token=${paymentData['token']}',
      };
    } catch (e) {
      logger.e('❌ PayMob payment failed: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> createFawryPayment({
    required int amount,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final merchantRefNum = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await http.post(
        Uri.parse('https://atfawry.fawrystaging.com/api/v1/payments'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'merchantCode': _fawryMerchantCode,
          'merchantRefNum': merchantRefNum,
          'customerProfileId': email,
          'customer': {
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'mobile': phone,
          },
          'paymentMethod': 'PAYATFAWRY',
          'amount': amount,
          'description': 'Privoo Pro Subscription',
          'chargeItems': [
            {'itemId': 'privoo_pro_monthly', 'description': 'Privoo Pro Monthly Subscription', 'price': amount, 'quantity': 1}
          ],
        }),
      );
      
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      
      return {'referenceNumber': merchantRefNum, 'paymentUrl': data['paymentUrl']};
    } catch (e) {
      logger.e('❌ Fawry payment failed: $e');
      return null;
    }
  }
  
  Future<void> purchaseWithGooglePlay({required String productId, required String userId}) async {
    logger.i('🛒 Google Play purchase: $productId for user $userId');
  }
  
  Future<void> purchaseWithAppleStore({required String productId, required String userId}) async {
    logger.i('🍎 Apple Store purchase: $productId for user $userId');
  }
}
*/