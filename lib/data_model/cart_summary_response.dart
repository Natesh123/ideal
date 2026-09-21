
import 'dart:convert';

CartSummaryResponse cartSummaryResponseFromJson(String str) =>
    CartSummaryResponse.fromJson(json.decode(str));

String cartSummaryResponseToJson(CartSummaryResponse data) =>
    json.encode(data.toJson());

class CartSummaryResponse {
  String? sub_total;
  String? tax;
  String? shipping_cost;
  String? discount;
  dynamic grand_total;
  double? grand_total_value;
  String? coupon_code;
  bool? coupon_applied;
  String? cash_on_delivery_charge;
  double? cash_on_delivery_charge_value;

  CartSummaryResponse({
    this.sub_total,
    this.tax,
    this.shipping_cost,
    this.discount,
    this.grand_total,
    this.grand_total_value,
    this.coupon_code,
    this.coupon_applied,
    this.cash_on_delivery_charge,
    this.cash_on_delivery_charge_value,
  });

  factory CartSummaryResponse.fromJson(Map<String, dynamic> json) =>
      CartSummaryResponse(
        sub_total: json["sub_total"],
        tax: json["tax"],
        shipping_cost: json["shipping_cost"],
        discount: json["discount"],
        grand_total: json["grand_total"],
        grand_total_value:
            double.tryParse(json["grand_total_value"].toString()) ?? 0.0,
        coupon_code: json["coupon_code"],
        coupon_applied: json["coupon_applied"],
        cash_on_delivery_charge: json["cash_on_delivery_charge"],
        cash_on_delivery_charge_value: double.tryParse(
                json["cash_on_delivery_charge_value"].toString()) ??
            double.tryParse(
                json["plane_cash_on_delivery_charge"].toString()) ??
            0.0,
      );

  Map<String, dynamic> toJson() => {
        "sub_total": sub_total,
        "tax": tax,
        "shipping_cost": shipping_cost,
        "discount": discount,
        "grand_total": grand_total,
        "grand_total_value": grand_total_value,
        "coupon_code": coupon_code,
        "coupon_applied": coupon_applied,
        "cash_on_delivery_charge": cash_on_delivery_charge,
        "cash_on_delivery_charge_value": cash_on_delivery_charge_value,
      };
}
