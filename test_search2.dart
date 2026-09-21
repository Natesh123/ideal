import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String productName = "dates";
  String urlStr = "https://idealtraders.co/api/v2/products";
  Uri url = Uri.parse(urlStr);
  var response = await http.get(url);
  print(response.body);
}
