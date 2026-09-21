import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String slug = "ajwa-dates-500g-q4cor";
  String urlStr = "https://idealtraders.co/api/v2/products/" + slug + "/";
  var url = Uri.parse(urlStr);
  var response = await http.get(url, headers: {
    "App-Language": "en",
    "System-Key": "\$2y\$10\$sb9oYSMePUim6BS1pZCd7eTtRRLbJvK24CDYe.lkGa4sxD0AJbKRa",
    "Accept": "application/json"
  });
  print("Response status: " + response.statusCode.toString());
  print("Response body: " + (response.body.length > 500 ? response.body.substring(0, 500) : response.body));
}
