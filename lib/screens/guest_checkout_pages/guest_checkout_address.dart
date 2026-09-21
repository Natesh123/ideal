
import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/custom/aiz_route.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/loading.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/business_setting_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/city_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/country_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/state_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/business_setting_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/guest_checkout_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/shipping_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../l10n/app_localizations.dart';

class GuestCheckoutAddress extends StatefulWidget {
  const GuestCheckoutAddress({super.key});

  @override
  _GuestCheckoutAddressState createState() => _GuestCheckoutAddressState();
}

class _GuestCheckoutAddressState extends State<GuestCheckoutAddress> {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Phone number state
  final ValueNotifier<PhoneNumber> _initialPhoneNumberNotifier = ValueNotifier(PhoneNumber(isoCode: 'US'));
  final ValueNotifier<String> _fullPhoneNumberNotifier = ValueNotifier('');

  // Country list for phone picker
  final ValueNotifier<List<String>> _allowedCountryCodesForPhoneNotifier = ValueNotifier([]);

  // Selected values for dropdowns
  final ValueNotifier<Country?> _selectedCountryNotifier = ValueNotifier(null);
  final ValueNotifier<MyState?> _selectedStateNotifier = ValueNotifier(null);
  final ValueNotifier<City?> _selectedCityNotifier = ValueNotifier(null);
  final ValueNotifier<City?> _selectedAreaNotifier = ValueNotifier(null);

  // UI state flags
  final ValueNotifier<bool> _showStateFieldNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _isAreaRequiredNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  _onTapOpenAddressDialog() async {
    _resetAddressFields();

    var countryResponse = await AddressRepository().getCountryList(name: "");
    if (!mounted) return;
    var settingsResponse =
    await BusinessSettingRepository().getBusinessSettingList();
    if (!mounted) return;

    _allowedCountryCodesForPhoneNotifier.value = countryResponse.countries
        .map((c) => c.code)
        .where((c) => c != null)
        .cast<String>()
        .toList();
    if (_allowedCountryCodesForPhoneNotifier.value.isNotEmpty) {
      _initialPhoneNumberNotifier.value =
          PhoneNumber(isoCode: _allowedCountryCodesForPhoneNotifier.value.first);
    }

    var hasStateData = (settingsResponse.data ?? [])
        .firstWhere((setting) => setting.type == "has_state",
        orElse: () => Datum());

    bool showStateField = hasStateData.value == "1";
    _showStateFieldNotifier.value = showStateField;
    bool showCountryField = countryResponse.countries.length != 1;

    if (!showCountryField && countryResponse.countries.isNotEmpty) {
      final singleCountry = countryResponse.countries.first;
      _selectedCountryNotifier.value = singleCountry;
      _countryController.text = singleCountry.name ?? "";
    }

    _buildShowAddFormDialog(context, showCountryField, showStateField);
  }

  bool _requiredFieldVerification() {
    final emailValid = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_emailController.text.trim());

    if (_nameController.text.trim().isEmpty) {
      ToastComponent.showDialog(LangText(context).local.name_required);
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      ToastComponent.showDialog(LangText(context).local.email_required);
      return false;
    }
    if (!emailValid) {
      ToastComponent.showDialog(LangText(context).local.enter_correct_email);
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      ToastComponent.showDialog(
          LangText(context).local.shipping_address_required);
      return false;
    }
    if (_selectedCountryNotifier.value == null) {
      ToastComponent.showDialog(LangText(context).local.country_required);
      return false;
    }
    if (_showStateFieldNotifier.value && _selectedStateNotifier.value == null) {
      ToastComponent.showDialog(LangText(context).local.state_required);
      return false;
    }
    if (_selectedCityNotifier.value == null) {
      ToastComponent.showDialog(LangText(context).local.city_required);
      return false;
    }
    if (_isAreaRequiredNotifier.value && _selectedAreaNotifier.value == null) {
      ToastComponent.showDialog("Please select an Area");
      return false;
    }
    if (_postalCodeController.text.trim().isEmpty) {
      ToastComponent.showDialog(LangText(context).local.postal_code_required);
      return false;
    }
    if (_fullPhoneNumberNotifier.value.isEmpty) {
      ToastComponent.showDialog(LangText(context).local.phone_number_required);
      return false;
    }
    return true;
  }

  Future<void> _continueToDeliveryInfo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_requiredFieldVerification()) return;

    Loading.show(context);

    Map<String, String> guestInfo = {
      "email": _emailController.text.trim(),
      "phone": _fullPhoneNumberNotifier.value,
    };

    var guestCheckResponse = await GuestCheckoutRepository()
        .guestCustomerInfoCheck(jsonEncode(guestInfo));
    if (!mounted) return;
    Loading.close();

    if (guestCheckResponse.result!) {
      ToastComponent.showDialog(LangText(context).local.already_have_account);
    } else {
      Map<String, dynamic> shippingAddress = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "country_id": _selectedCountryNotifier.value!.id.toString(),
        "state_id": _selectedStateNotifier.value?.id.toString() ?? "0",
        "city_id": _selectedCityNotifier.value!.id.toString(),
        "area_id": _selectedAreaNotifier.value?.id.toString(),
        "postal_code": _postalCodeController.text.trim(),
        "phone": _fullPhoneNumberNotifier.value,
        "longitude": '',
        "latitude": '',
        "temp_user_id": temp_user_id.$
      };

      guestEmail.$ = _emailController.text.trim();
      guestEmail.save();

      Navigator.of(context, rootNavigator: true).pop();

      AIZRoute.push(
        context,
        ShippingInfo(
          guestCheckOutShippingAddress: jsonEncode(shippingAddress),
        ),
      );
    }
  }

  void _onSelectCountry(Country country) {
    if (_selectedCountryNotifier.value?.id == country.id) return;
    _selectedCountryNotifier.value = country;
    _selectedStateNotifier.value = null;
    _selectedCityNotifier.value = null;
    _selectedAreaNotifier.value = null;
    _isAreaRequiredNotifier.value = false;
    _countryController.text = country.name ?? "";
    _stateController.clear();
    _cityController.clear();
    _areaController.clear();
  }

  void _onSelectState(MyState state) {
    if (_selectedStateNotifier.value?.id == state.id) return;
    _selectedStateNotifier.value = state;
    _selectedCityNotifier.value = null;
    _selectedAreaNotifier.value = null;
    _isAreaRequiredNotifier.value = false;
    _stateController.text = state.name ?? "";
    _cityController.clear();
    _areaController.clear();
  }

  void _onSelectCity(City city) async {
    if (_selectedCityNotifier.value?.id == city.id) return;
    var areaResponse =
    await AddressRepository().getAriaListByCity(city_id: city.id!);
    _selectedCityNotifier.value = city;
    _selectedAreaNotifier.value = null;
    _isAreaRequiredNotifier.value = areaResponse.cities.isNotEmpty;
    _cityController.text = city.name ?? "";
    _areaController.clear();
  }

  void _onSelectArea(City area) {
    if (_selectedAreaNotifier.value?.id == area.id) return;
    _selectedAreaNotifier.value = area;
    _areaController.text = area.name ?? "";
  }

  void _resetAddressFields() {
    _nameController.clear();
    _emailController.clear();
    _addressController.clear();
    _postalCodeController.clear();
    _phoneController.clear();
    _countryController.clear();
    _stateController.clear();
    _cityController.clear();
    _areaController.clear();
    _selectedCountryNotifier.value = null;
    _selectedStateNotifier.value = null;
    _selectedCityNotifier.value = null;
    _selectedAreaNotifier.value = null;
    _isAreaRequiredNotifier.value = false;
    _fullPhoneNumberNotifier.value = '';
    _allowedCountryCodesForPhoneNotifier.value = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Btn.minWidthFixHeight(
                  minWidth: MediaQuery.of(context).size.width - 16,
                  height: 90,
                  color: const Color(0xffFEF0D7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                          color: Colors.amber.shade600, width: 1.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LangText(context).local.enter_address_ucf,
                        style: TextStyle(
                            fontSize: 13,
                            color: MyTheme.dark_font_grey,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.add_circle_outline,
                        color: MyTheme.accent_color,
                        size: 30,
                      ),
                    ],
                  ),
                  onPressed: _onTapOpenAddressDialog,
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_font_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
          AppLocalizations.of(context)!.addresses_of_user,
        style: const TextStyle(
            fontSize: 16,
            color: Color(0xff3E4447),
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
  Future _buildShowAddFormDialog(
      BuildContext context, bool showCountryField, bool showStateField) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 10),
            contentPadding: const EdgeInsets.only(
                top: 23.0, left: 20.0, right: 20.0, bottom: 2.0),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFieldInDialog(_nameController,
                        LangText(context).local.name_ucf,
                        LangText(context).local.enter_your_name),
                    _buildTextFieldInDialog(_emailController,
                        LangText(context).local.email_ucf,
                        LangText(context).local.enter_email),
                    _buildTextFieldInDialog(_addressController,
                        LangText(context).local.address_ucf,
                        LangText(context).local.enter_address_ucf),
                    if (showCountryField)
                      _buildCountryTypeAheadInDialog(),
                    if (showStateField)
                      _buildStateTypeAheadInDialog(),
                    _buildCityTypeAheadInDialog(
                        showStateField),
                    ValueListenableBuilder(
                      valueListenable: _isAreaRequiredNotifier,
                      builder: (context, bool isAreaRequired, child) {
                        if (isAreaRequired) {
                          return _buildAreaTypeAheadInDialog();
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    _buildTextFieldInDialog(
                        _postalCodeController,
                        LangText(context).local.postal_code,
                        LangText(context).local.enter_postal_code_ucf),
                    _buildPhoneFieldInDialog(),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Btn.basic(
                      child: Text(
                        LangText(context).local.close_ucf,
                        style: TextStyle(color: MyTheme.medium_grey),
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: Btn.basic(
                      color: MyTheme.accent_color,
                      child: Text(
                        LangText(context).local.continue_ucf,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        _continueToDeliveryInfo();
                      },
                    ),
                  ),
                ],
              )
            ],
          );
        });
  }

  Widget _buildTextFieldInDialog(
      TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("$label *",
              style: const TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            decoration: _buildAddressInputDecoration(hint),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneFieldInDialog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("${LangText(context).local.phone_ucf} *",
              style: const TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 60,
          child: ValueListenableBuilder(
            valueListenable: _allowedCountryCodesForPhoneNotifier,
            builder: (context, List<String> allowedCountryCodes, child) {
              return ValueListenableBuilder(
                valueListenable: _initialPhoneNumberNotifier,
                builder: (context, PhoneNumber initialPhoneNumber, child) {
                  return InternationalPhoneNumberInput(
                    textFieldController: _phoneController,
                    onInputChanged: (PhoneNumber number) {
                      _fullPhoneNumberNotifier.value = number.phoneNumber ?? '';
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DROPDOWN,
                    ),
                    formatInput: true,
                    countries: allowedCountryCodes,
                    initialValue: initialPhoneNumber,
                    inputDecoration: _buildAddressInputDecoration(
                        LangText(context).local.enter_phone_number),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryTypeAheadInDialog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("${LangText(context).local.country_ucf} *",
              style: const TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 40,
          child: TypeAheadField<Country>(
            controller: _countryController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildAddressInputDecoration(
                  LangText(context).local.enter_country_ucf),
            ),
            suggestionsCallback: (name) async {
              var countryResponse =
              await AddressRepository().getCountryList(name: name);
              return countryResponse.countries;
            },
            itemBuilder: (context, country) => ListTile(
              dense: true,
              title: Text(country.name ?? '',
                  style: TextStyle(color: MyTheme.font_grey)),
            ),
            onSelected: (value) => _onSelectCountry(value),
            loadingBuilder: (context) =>
                Center(child: Text(LangText(context).local.loading_countries_ucf)),
          ),
        ),
      ],
    );
  }

  Widget _buildStateTypeAheadInDialog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("${LangText(context).local.state_ucf} *",
              style: const TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 40,
          child: TypeAheadField<MyState>(
            controller: _stateController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildAddressInputDecoration(
                  LangText(context).local.enter_state_ucf),
            ),
            suggestionsCallback: (name) async {
              if (_selectedCountryNotifier.value == null) return [];
              var stateResponse = await AddressRepository()
                  .getStateListByCountry(
                  country_id: _selectedCountryNotifier.value!.id!, name: name);
              return stateResponse.states;
            },
            itemBuilder: (context, state) => ListTile(
              dense: true,
              title: Text(state.name ?? '',
                  style: TextStyle(color: MyTheme.font_grey)),
            ),
            onSelected: (value) => _onSelectState(value),
            loadingBuilder: (context) =>
                Center(child: Text(LangText(context).local.loading_states_ucf)),
          ),
        ),
      ],
    );
  }

  Widget _buildCityTypeAheadInDialog(
      bool showStateField) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("${LangText(context).local.city_ucf} *",
              style: const TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 40,
          child: TypeAheadField<City>(
            controller: _cityController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildAddressInputDecoration(
                  LangText(context).local.enter_city_ucf),
            ),
            suggestionsCallback: (name) async {
              if (showStateField) {
                if (_selectedStateNotifier.value == null) return [];
                var cityResponse = await AddressRepository()
                    .getCityListByState(state_id: _selectedStateNotifier.value!.id!, name: name);
                return cityResponse.cities;
              } else {
                if (_selectedCountryNotifier.value == null) return [];
                var cityResponse = await AddressRepository()
                    .getCityListByCountry(
                    country_id: _selectedCountryNotifier.value!.id!, name: name);
                return cityResponse.cities;
              }
            },
            itemBuilder: (context, city) => ListTile(
              dense: true,
              title: Text(city.name ?? '',
                  style: TextStyle(color: MyTheme.font_grey)),
            ),
            onSelected: (value) => _onSelectCity(value),
            loadingBuilder: (context) =>
                Center(child: Text(LangText(context).local.loading_cities_ucf)),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaTypeAheadInDialog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text("Area *",
              style: TextStyle(
                  color: Color(0xff3E4447),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        SizedBox(
          height: 40,
          child: TypeAheadField<City>(
            controller: _areaController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildAddressInputDecoration("Enter Area"),
            ),
            suggestionsCallback: (name) async {
              if (_selectedCityNotifier.value == null) return [];
              var areaResponse = await AddressRepository()
                  .getAriaListByCity(city_id: _selectedCityNotifier.value!.id!, name: name);
              return areaResponse.cities;
            },
            itemBuilder: (context, area) => ListTile(
              dense: true,
              title: Text(area.name ?? '',
                  style: TextStyle(color: MyTheme.font_grey)),
            ),
            onSelected: (value) => _onSelectArea(value),
            loadingBuilder: (context) =>
            const Center(child: Text("Loading Areas...")),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildAddressInputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xffF6F7F8),
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12.0, color: Color(0xff999999)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      contentPadding: const EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
    );
  }
}