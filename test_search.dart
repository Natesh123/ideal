import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String productName = "Ajwa Dates (500g)";
  Uri url = Uri.parse("https://idealtraders.co/api/v2/products/search?name=${Uri.encodeComponent(productName)}");
  var response = await http.get(url);
  print(response.body);
}
