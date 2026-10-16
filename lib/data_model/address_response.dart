
import 'dart:convert';

AddressResponse addressResponseFromJson(String str) =>
    AddressResponse.fromJson(json.decode(str));

String addressResponseToJson(AddressResponse data) =>
    json.encode(data.toJson());

class AddressResponse {
  AddressResponse({
    this.addresses,
    this.success,
    this.status,
  });

  List<Address>? addresses;
  bool? success;
  int? status;

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      AddressResponse(
        addresses:
        List<Address>.from(json["data"].map((x) => Address.fromJson(x))),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(addresses!.map((x) => x.toJson())),
    "success": success,
    "status": status,
  };
}

class Address {
  Address({
    this.id,
    this.user_id,
    this.address,
    this.country_id,
    this.state_id,
    this.city_id,
    this.area_id,
    this.country_name,
    this.state_name,
    this.city_name,
    this.area_name,
    this.postal_code,
    this.phone,
    this.set_default,
    this.location_available,
    this.lat,
    this.lang,
    this.valid,
  });

  int? id;
  int? user_id;
  String? address;
  int? country_id;
  int? state_id;
  int? city_id;
  int? area_id;
  String? country_name;
  String? state_name;
  String? city_name;
  String? area_name;
  String? postal_code;
  String? phone;
  int? set_default;
  bool? location_available;
  double? lat;
  double? lang;
  bool? valid;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json["id"],
    user_id: json["user_id"],
    address: json["address"],
    country_id: json["country_id"],
    state_id: json["state_id"],
    city_id: json["city_id"],
    area_id: json["area_id"],
    country_name: json["country_name"],
    state_name: json["state_name"],
    city_name: json["city_name"],
    area_name: json["area_name"],
    postal_code: json["postal_code"] ?? "",
    phone: json["phone"] ?? "",
    set_default: json["set_default"],
    location_available: json["location_available"],
    lat: json["lat"] == null ? 0.0 : json["lat"].toDouble(),
    lang: json["lang"] == null ? 0.0 : json["lang"].toDouble(),
    valid: json["valid"], // <-- ADD THIS
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": user_id,
    "address": address,
    "country_id": country_id,
    "state_id": state_id,
    "city_id": city_id,
    "area_id": area_id,
    "country_name": country_name,
    "state_name": state_name,
    "city_name": city_name,
    "area_name": area_name,
    "postal_code": postal_code,
    "phone": phone,
    "set_default": set_default,
    "location_available": location_available,
    "lat": lat,
    "lang": lang,
    "valid": valid,
  };
}