
var this_year = DateTime.now().year.toString();

class AppConfig {
  //configure this
  static String copyright_text =
      "@ IdealTraders $this_year"; //this shows in the splash screen
  static String app_name =
      "Ideal Traders"; //this shows in the splash screen
  static String search_bar_text =
      "Search in Ideal Traders..."; //this will show in app Search bar.
  static String purchase_code =
      "cd7d0bbb-2c6d-4eae-a440-93bd614da0db"; //enter your purchase code for the app from codecanyon
  static String system_key =
      r"$2y$10$sb9oYSMePUim6BS1pZCd7eTtRRLbJvK24CDYe.lkGa4sxD0AJbKRa"; //system key from business settings

  //Default language config
  static String default_language = "en";
  static String mobile_app_code = "en";
  static bool app_language_rtl = false;
  //configure this
  static const bool HTTPS = true; // if you are using localhost , set this to false
  static const DOMAIN_PATH = "idealtraders.co"; // use only domain name without http:// or https://
  //do not configure these below
  static const String API_ENDPATH = "api/v2";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "$PROTOCOL$DOMAIN_PATH";
  static const String BASE_URL = "$RAW_BASE_URL/$API_ENDPATH";

  static String getSanitizedUrl(String url) {
    if (url.isEmpty) return url;



    // Handle common local patterns if the backend returns them
    String sanitized = url;
    if (sanitized.contains("localhost") ||
        sanitized.contains("127.0.0.1") ||
        sanitized.contains("192.168.")) {

      // Replace local host/IP with the live domain
      RegExp hostRegex = RegExp(r"(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+)(:\d+)?");
      sanitized = sanitized.replaceFirst(hostRegex, DOMAIN_PATH);

      // Ensure correct protocol for live domain
      if (HTTPS && !sanitized.startsWith("https")) {
        sanitized = sanitized.replaceFirst("http://", "https://");
      }
    }

    // Fix for local images having /public/ in path (ONLY for localhost)
    if (!HTTPS && sanitized.contains(DOMAIN_PATH) && sanitized.contains("/public/")) {
      sanitized = sanitized.replaceAll("/public/", "/");
    }



    return sanitized;
  }
}