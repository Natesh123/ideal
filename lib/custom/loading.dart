import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:flutter/material.dart';

class Loading {
  static BuildContext? _context;

  static show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Loading._context = context;
        return AlertDialog(
            content: Row(
          children: [
            CircularProgressIndicator(),
            const SizedBox(
              width: 10,
            ),
            Text(LangText(context).local.please_wait_ucf),
          ],
        ));
      },
    );
  }

  static close() {
    print("DEBUG: Loading.close called, current _context: ${Loading._context}");
    if (Loading._context != null) {
      try {
        Navigator.of(Loading._context!).pop();
        print("DEBUG: Loading.close - Navigator.pop executed successfully");
        Loading._context = null;
      } catch (e) {
        print("DEBUG: Loading.close ERROR: $e");
      }
    } else {
      print("DEBUG: Loading.close - No context to close");
    }
  }

  static Widget bottomLoading(bool value) {
    return value
        ? Container(
            alignment: Alignment.center,
            child: SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator()),
          )
        : SizedBox(
            height: 5,
            width: 5,
          );
  }
}
