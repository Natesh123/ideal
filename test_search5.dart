import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  var url1 = Uri.parse("https://idealtraders.co/api/v2/products/best-seller");
  var response1 = await http.get(url1, headers: {"App-Language": "en"});
  print("Response 1 status: " + response1.statusCode.toString());
  print("Response 1 body: " + (response1.body.length > 500 ? response1.body.substring(0, 500) : response1.body));
}
