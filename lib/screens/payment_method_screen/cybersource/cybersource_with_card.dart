import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class PaymentService {
  static const String _baseUrl = '${AppConfig.BASE_URL}/cyber-source/payment/pay';

  static Future<Map<String, dynamic>> generatePaymentToken({
    required String cardNumber,
    required String expMonth,
    required String expYear,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate-payment-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'card_number': cardNumber,
        'exp_month': expMonth,
        'exp_year': expYear,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> processPayment({
    required String token,
    required String orderId,
    required double amount,
    required String currency,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/process-payment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'order_id': orderId,
        'amount': amount.toString(),
        'currency': currency,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }
}

class CybersourceWithCard extends StatefulWidget {
  const CybersourceWithCard({super.key});

  @override
  _CybersourceWithCardState createState() => _CybersourceWithCardState();
}

class CardState {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cvvCode;
  final bool isCvvFocused;

  CardState({
    this.cardNumber = '',
    this.expiryDate = '',
    this.cardHolderName = '',
    this.cvvCode = '',
    this.isCvvFocused = false,
  });
}

class _CybersourceWithCardState extends State<CybersourceWithCard> {
  final ValueNotifier<CardState> _cardState = ValueNotifier(CardState());
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Added formKey

  @override
  void dispose() {
    _cardState.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<CardState>(
              valueListenable: _cardState,
              builder: (context, cardState, _) => CreditCardWidget(
                cardNumber: cardState.cardNumber,
                expiryDate: cardState.expiryDate,
                cardHolderName: cardState.cardHolderName,
                cvvCode: cardState.cvvCode,
                showBackView: cardState.isCvvFocused,
                onCreditCardWidgetChange: (creditCardBrand) {},
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ValueListenableBuilder<CardState>(
                  valueListenable: _cardState,
                  builder: (context, cardState, _) => CreditCardForm(
                    cardNumber: cardState.cardNumber,
                    expiryDate: cardState.expiryDate,
                    cardHolderName: cardState.cardHolderName,
                    cvvCode: cardState.cvvCode,
                    onCreditCardModelChange: onCreditCardModelChange,
                    formKey: formKey, // Now using the declared formKey
                    cvvValidationMessage: 'Please input a valid CVV',
                    dateValidationMessage: 'Please input a valid date',
                    numberValidationMessage: 'Please input a valid number',
                    cardHolderValidator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, _) => isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _processPayment,
                      child: Text('PAY'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    _cardState.value = CardState(
      cardNumber: creditCardModel.cardNumber,
      expiryDate: creditCardModel.expiryDate,
      cardHolderName: creditCardModel.cardHolderName,
      cvvCode: creditCardModel.cvvCode,
      isCvvFocused: creditCardModel.isCvvFocused,
    );
  }

  Future<void> _processPayment() async {
    if (!formKey.currentState!.validate()) {
      // Validate form before processing
      return;
    }

    _isLoading.value = true;

    try {
      // Extract month and year from expiry date (format: MM/YY)
      final parts = _cardState.value.expiryDate.split('/');
      final expMonth = parts[0].trim();
      final expYear = '20${parts[1].trim()}'; // Convert YY to YYYY

      // Generate payment token
      final tokenResponse = await PaymentService.generatePaymentToken(
        cardNumber: _cardState.value.cardNumber.replaceAll(' ', ''),
        expMonth: expMonth,
        expYear: expYear,
      );

      // Process payment with token
      final paymentResponse = await PaymentService.processPayment(
        token: tokenResponse['token'],
        orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        amount: 100.0, // Your amount
        currency: 'USD',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
      );

      if (paymentResponse['status'] == 'AUTHORIZED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment failed: ${paymentResponse['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
