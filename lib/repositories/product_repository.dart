import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/category.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/product_details_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/product_mini_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/variant_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/wholesale_model.dart';
import '../data_model/variant_price_response.dart';

class ProductRepository {
  Future<CatResponse> getCategoryRes() async {
    String url = ("${AppConfig.BASE_URL}/seller/products/categories");

    var reqHeader = {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    };

    final response = await ApiRequest.get(url: url, headers: reqHeader);

    return catResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFeaturedProducts({page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/featured?page=$page");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getBestSellingProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/best-seller");
    if (is_wholesale_user.$) {
      url += "?is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Currency-Code": SystemConfig.systemCurrency!.code!,
      "Currency-Exchange-Rate":
          SystemConfig.systemCurrency!.exchangeRate.toString(),
    });
    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getInHouseProducts({page}) async {
    String url = ("${AppConfig.BASE_URL}/products/inhouse?page=$page");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getTodaysDealProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/todays-deal");
    if (is_wholesale_user.$) {
      url += "?is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getFlashDealProducts(id) async {
    String url = ("${AppConfig.BASE_URL}/flash-deal-products/$id");
    if (is_wholesale_user.$) {
      url += "?is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getCategoryProducts(
      {String? id = "", name = "", page = 1}) async {
    String url =
        ("${AppConfig.BASE_URL}/products/category/${Uri.encodeComponent(id!)}?page=${page}&name=${name}");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getShopProducts(
      {int? id = 0, name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/seller/$id?page=${page}&name=${name}");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getBrandProducts(
      {required String slug, name = "", page = 1}) async {
    String url =
        ("${AppConfig.BASE_URL}/products/brand/$slug?page=$page&name=$name");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getFilteredProducts(
      {
        name = "",
      sort_key = "",
      page = 1,
      brands = "",
      categories = "",
      min = "",
      max = ""
      }) async {
    String encodedName = Uri.encodeComponent(name.toString());
    String url = ("${AppConfig.BASE_URL}/products/search" "?page=$page&name=$encodedName&sort_key=$sort_key&brands=$brands&categories=$categories&min=$min&max=$max");
    if (is_wholesale_user.$) {
      url += "&is_wholesale=1";
    }

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getDigitalProducts({
    name = "",
    sort_key = "",
    page = 1,
    brands = "",
    categories = "",
    min = "",
    max = ""
  }) async {
    String url = ("${AppConfig.BASE_URL}/products/search?page=1&name=$name&sort_key=$sort_key&brands=$brands&categories=&min=$min&max=$max&digital=$page");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }



  ///////
  Future<ProductDetailsResponse> getProductDetails(
      {String? slug = "", dynamic userId = ''}) async {
    String url =
        ("${AppConfig.BASE_URL}/products/$slug/$userId");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
print('product details ${response.body}');
    return productDetailsResponseFromJson(response.body);
  }

  Future<ProductDetailsResponse> getDigitalProductDetails({int id = 0}) async {
    String url = ("${AppConfig.BASE_URL}/products/$id");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productDetailsResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFrequentlyBoughProducts(
      {required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/frequently-bought/$slug");
    if (is_wholesale_user.$) {
      url += "?is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<ProductMiniResponse> getTopFromThisSellerProducts(
      {required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/top-from-seller/$slug");
    if (is_wholesale_user.$) {
      url += "?is_wholesale=1";
    }
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  Future<VariantResponse> getVariantWiseInfo(
      {required String slug, color = '', variants = '', qty = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/variant/price");

    var postBody = jsonEncode(
        {'slug': slug, "color": color, "variants": variants, "quantity": qty});

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: postBody);

    return variantResponseFromJson(response.body);
  }

  Future<VariantPriceResponse> getVariantPrice({id, quantity}) async {
    String url = ("${AppConfig.BASE_URL}/varient-price");

    var postBody = jsonEncode({"id": id, "quantity": quantity});

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: postBody);

    return variantPriceResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> lastViewProduct() async {
    String url = ("${AppConfig.BASE_URL}/products/last-viewed");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    });

    return _filterWholesaleProducts(productMiniResponseFromJson(response.body));
  }


  ProductMiniResponse _filterWholesaleProducts(ProductMiniResponse response) {
    if (is_wholesale_user.$) {
      final originalCount = response.products?.length ?? 0;
      response.products =
          response.products?.where((p) => p.isWholesale ?? false).toList();
      print(
          "Filtering wholesale products: $originalCount -> ${response.products?.length}");
    }
    return response;
  }

  Future<WholesaleProductModel> getWholesaleProducts({page = 1}) async {
    String url = "${AppConfig.BASE_URL}/wholesale/all-products?page=$page";
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    if (response.statusCode == 200) {
      return WholesaleProductModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load products");
    }
  }
}

