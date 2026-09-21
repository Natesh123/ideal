void main() {
  String name = "Ajwa Dates (500g)";
  String url = "https://idealtraders.co/api/v2/products/search?page=1&name=$name";
  Uri uri = Uri.parse(url);
  print(uri.toString());
}
