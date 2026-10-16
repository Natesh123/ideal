import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  var url1 = Uri.parse("https://idealtraders.co/api/v2/products/ajwa-dates-500g/0");
  var response1 = await http.get(url1);
  print("Response 1: " + response1.body);

  var url2 = Uri.parse("https://idealtraders.co/api/v2/products/94/0");
  var response2 = await http.get(url2);
  print("Response 2: " + response2.body);
}
