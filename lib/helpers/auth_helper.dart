import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';

import '../data_model/login_response.dart';
import 'shared_value_helper.dart';

class AuthHelper {
  setUserData(LoginResponse loginResponse, {bool skipWholesaleUpdate = false}) {
    if (loginResponse.result == true) {
      SystemConfig.systemUser = loginResponse.user;
      is_logged_in.$ = true;
      is_logged_in.save();
      access_token.$ = loginResponse.access_token;
      access_token.save();
      
      // Use root user_id if user object is not available
      user_id.$ = loginResponse.user?.id ?? loginResponse.user_id;
      user_id.save();
      
      user_name.$ = loginResponse.user?.name ?? "";
      user_name.save();
      user_email.$ = loginResponse.user?.email ?? "";
      user_email.save();
      user_phone.$ = loginResponse.user?.phone ?? "";
      user_phone.save();
      avatar_original.$ = loginResponse.user?.avatar_original ?? "";
      avatar_original.save();

      print("Full user object: ${loginResponse.user?.toJson()}");
      print("User type from response: ${loginResponse.user?.type}");
      
      if (!skipWholesaleUpdate) {
        // Robust check for wholesale user type
        if (loginResponse.user?.type?.toLowerCase() == "wholesale") {
          is_wholesale_user.$ = true;
        } else {
          is_wholesale_user.$ = false;
        }
        is_wholesale_user.save();
      }
    }
  }

  clearUserData() {
    is_logged_in.$ = false;
    is_logged_in.save();
    access_token.$ = "";
    access_token.save();
    user_id.$ = 0;
    user_id.save();
    user_name.$ = "";
    user_name.save();
    user_email.$ = "";
    user_email.save();
    user_phone.$ = "";
    user_phone.save();
    avatar_original.$ = "";
    avatar_original.save();
    is_wholesale_user.$ = false;
    is_wholesale_user.save();

    temp_user_id.$ = "";
    temp_user_id.save();
  }

  fetch_and_set() async {
    var loginResponse = await AuthRepository().getUserByTokenResponse();
    if (loginResponse.result == true) {
      bool isWholesale = is_wholesale_user.$;
      print("fetch_and_set: Captured wholesale status: $isWholesale");
      // If we are already wholesale, don't let the (possibly inconsistent) 
      // info response overwrite the status.
      setUserData(loginResponse, skipWholesaleUpdate: isWholesale);
    }
  }
}
