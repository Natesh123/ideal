import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebviewScreen extends StatefulWidget {
  String url;
  String page_name;

  CommonWebviewScreen({super.key, this.url = "", this.page_name = ""});

  @override
  _CommonWebviewScreenState createState() => _CommonWebviewScreenState();
}

class _CommonWebviewScreenState extends State<CommonWebviewScreen> {
  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    webView();
  }

  webView() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onNavigationRequest: (NavigationRequest request) {
            final urlLower = request.url.toLowerCase();
            // Block any navigation to Google Play or third-party app stores (Apple Guideline 2.3.10)
            if (urlLower.contains('play.google.com') ||
                urlLower.contains('market://') ||
                urlLower.contains('playstore')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (page) {
            // Strip any website popups or Play Store links that might be injected by the backend website
            _webViewController.runJavaScript('''
              (function() {
                var popups = document.querySelectorAll('.website-popup, [data-key*="website-popup"]');
                popups.forEach(function(el) { el.remove(); });
                var playLinks = document.querySelectorAll('a[href*="play.google.com"], a[href*="market://"]');
                playLinks.forEach(function(el) { el.remove(); });
              })();
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody(),
      ),
    );
  }

  buildBody() {
    return SizedBox.expand(
      child: Container(
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.page_name,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
