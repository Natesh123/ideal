import 'package:active_ecommerce_cms_demo_app/helpers/main_helpers.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/group_middleware.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/middleware.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/aiz_api_response.dart';
import 'package:http/http.dart' as http;

class ApiRequest {
  static Future<http.Response> get(
      {required String url,
      Map<String, String>? headers,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    print("------------------ API Request ------------------");
    print("URL: $url");
    print("Headers: $headerMap");
    try {
      var response = await http.get(uri, headers: headerMap);
      print("Status Code: ${response.statusCode}");
      print("Body (First 100 chars): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}");
      return AIZApiResponse.check(response,
          middleware: middleware, groupMiddleWare: groupMiddleWare);
    } catch (e) {
      print("API ERROR: $e");
      rethrow;
    }
  }

  static Future<http.Response> post(
      {required String url,
      Map<String, String>? headers,
      required String body,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    print("------------------ API Request (POST) ------------------");
    print("URL: $url");
    print("Headers: $headerMap");
    print("Body: $body");
    try {
      var response = await http.post(uri, headers: headerMap, body: body);
      print("Status Code: ${response.statusCode}");
      print("Response Body (Full): ${response.body}");
      return AIZApiResponse.check(response,
          middleware: middleware, groupMiddleWare: groupMiddleWare);
    } catch (e) {
      print("API ERROR (POST): $e");
      rethrow;
    }
  }

  static Future<http.Response> delete(
      {required String url,
      Map<String, String>? headers,
      Middleware? middleware,
      GroupMiddleware? groupMiddleWare}) async {
    Uri uri = Uri.parse(url);
    Map<String, String>? headerMap = commonHeader;
    headerMap.addAll(currencyHeader);
    if (headers != null) {
      headerMap.addAll(headers);
    }
    print("------------------ API Request (DELETE) ------------------");
    print("URL: $url");
    print("Headers: $headerMap");
    try {
      var response = await http.delete(uri, headers: headerMap);
      print("Status Code: ${response.statusCode}");
      return AIZApiResponse.check(response,
          middleware: middleware, groupMiddleWare: groupMiddleWare);
    } catch (e) {
      print("API ERROR (DELETE): $e");
      rethrow;
    }
  }
}
