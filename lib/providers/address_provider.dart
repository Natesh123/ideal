import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_provider.g.dart';

@riverpod
class AddressProvider extends _$AddressProvider {
  @override
  Future<List<dynamic>> build() async {
    return fetchAddresses();
  }

  Future<List<dynamic>> fetchAddresses() async {
    final response = await AddressRepository().getAddressList();
    return response.addresses;
  }

  Future<void> makeDefault(int addressId) async {
    final response = await AddressRepository().getAddressMakeDefaultResponse(addressId);
    if (response.result == true) {
      ref.invalidateSelf();
    }
  }

  Future<void> deleteAddress(int addressId) async {
    final response = await AddressRepository().getAddressDeleteResponse(addressId);
    if (response.result == true) {
      ref.invalidateSelf();
    }
  }

  Future<bool> addAddress({
    required String address,
    required int country_id,
    required int state_id,
    required int city_id,
    int? area_id,
    required String postal_code,
    required String phone,
  }) async {
    final response = await AddressRepository().getAddressAddResponse(
      address: address,
      country_id: country_id,
      state_id: state_id,
      city_id: city_id,
      area_id: area_id,
      postal_code: postal_code,
      phone: phone,
    );
    if (response.result == true) {
      ref.invalidateSelf();
    }
    return response.result;
  }

  Future<bool> updateAddress({
    required int id,
    required String address,
    required int country_id,
    required int state_id,
    required int city_id,
    int? area_id,
    required String postal_code,
    required String phone,
  }) async {
    final response = await AddressRepository().getAddressUpdateResponse(
      id: id,
      address: address,
      country_id: country_id,
      state_id: state_id,
      city_id: city_id,
      area_id: area_id,
      postal_code: postal_code,
      phone: phone,
    );
    if (response.result == true) {
      ref.invalidateSelf();
    }
    return response.result;
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
