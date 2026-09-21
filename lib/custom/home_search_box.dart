import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

class HomeSearchBox extends StatelessWidget {
  final BuildContext? context;
  const HomeSearchBox({super.key, this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xfff3f3f3),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 226, 226, 226).withOpacity(.12),
            blurRadius: 15,
            spreadRadius: 0.4,
            offset: Offset(0.0, 5.0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/search.png',
              height: 16,
              color: Color(0xff7B7980),
            ),
            SizedBox(width: 10),
            Text(
              AppConfig.search_bar_text,
              style: TextStyle(fontSize: 13.0, color: Color(0xff7B7980)),
            ),
          ],
        ),
      ),
    );
  }
}
