import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String urlStr = "https://idealtraders.co/api/v2/products/ajwa-dates-500g";
  Uri url = Uri.parse(urlStr);
  var response = await http.get(url);
  print(response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length)));
}
