import 'dart:convert';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/banned_user.dart';

class LocalChatbotRepository {
  Future<Map<String, dynamic>> sendMessage(String message) async {
    String url = "${AppConfig.BASE_URL}/local-chatbot/message";
    var postBody = jsonEncode({
      "message": message,
    });

    try {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          if (access_token.$?.isNotEmpty == true)
            "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$ ?? "en",
        },
        body: postBody,
        middleware: BannedUser(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {"reply": "Sorry, I am unable to connect to the server right now. (Status: ${response.statusCode})"};
      }
    } catch (e) {
      print("LocalChatbotRepository sendMessage error: $e");
      return {"reply": "Sorry, I'm having trouble connecting right now."};
    }
  }

  Future<Map<String, dynamic>> getMyOrders() async {
    String url = "${AppConfig.BASE_URL}/local-chatbot/my-orders";

    try {
      final response = await ApiRequest.get(
        url: url,
        headers: {
          if (access_token.$?.isNotEmpty == true)
            "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$ ?? "en",
        },
        middleware: BannedUser(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          "logged_in": false,
          "reply": "Could not fetch your orders. Please make sure you are logged in."
        };
      }
    } catch (e) {
      print("LocalChatbotRepository getMyOrders error: $e");
      return {
        "logged_in": false,
        "reply": "Unable to load orders due to a connection issue."
      };
    }
  }
}
