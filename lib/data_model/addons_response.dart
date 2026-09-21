// To parse this JSON data, do
//
//     final addonsListResponse = addonsListResponseFromJson(jsonString);

import 'dart:convert';

List<AddonsListResponse> addonsListResponseFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded == null || decoded is! List) {
    return [];
  }
  return List<AddonsListResponse>.from(
      decoded.map((x) => AddonsListResponse.fromJson(x)));
}

String addonsListResponseToJson(List<AddonsListResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AddonsListResponse {
  AddonsListResponse({
    this.id,
    this.name,
    this.uniqueIdentifier,
    this.activated,
  });

  var id;
  String? name;
  String? uniqueIdentifier;
  var activated;

  factory AddonsListResponse.fromJson(Map<String, dynamic> json) =>
      AddonsListResponse(
        id: json["id"],
        name: json["name"],
        uniqueIdentifier: json["unique_identifier"],
        activated: json["activated"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "unique_identifier": uniqueIdentifier,
        "activated": activated,
      };
}
