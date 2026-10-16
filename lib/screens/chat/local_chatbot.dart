import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/local_chatbot_repository.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_details.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/order_repository.dart';

class LocalChatbotScreen extends StatefulWidget {
  const LocalChatbotScreen({super.key});

  @override
  State<LocalChatbotScreen> createState() => _LocalChatbotScreenState();
}

class ChatbotMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatbotMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}

// Custom class to hold parsed order information
class ParsedOrder {
  final String code;
  final int id;
  final String status;
  final String date;

  ParsedOrder({
    required this.code,
    required this.id,
    required this.status,
    required this.date,
  });
}

class _LocalChatbotScreenState extends State<LocalChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<ChatbotMessage>> _messages = ValueNotifier([]);
  final ValueNotifier<bool> _isTyping = ValueNotifier(false);
  bool _ordersLoaded = false;
  
  // Brand colors matching the website's chatbot
  final Color primaryGreen = const Color(0xff2B310A); // Dark Olive
  final Color lightGreenBg = const Color(0xffbbceb8); // Sage Green
  final Color bubbleBotBg = const Color(0xfff1f5f1);   // Light Gray-Green
  final String whatsappNumber = "+919277123454";
  final String chatbotLogoUrl = "https://idealtraders.co/public/uploads/all/su0mKYeUFqTPDupyyR0G7dHF1pPOY9oQl0jx8IzK.png";

  // Map to link order codes (e.g. 20260626-16243863) to native database IDs (e.g. 163)
  final Map<String, int> _orderCodeToIdMap = {};

  Future<void> _fetchOrderIdsMap() async {
    try {
      final orderResponse = await OrderRepository().getOrderList(page: 1);
      if (orderResponse != null && orderResponse.orders != null) {
        for (var order in orderResponse.orders) {
          if (order.code != null && order.id != null) {
            _orderCodeToIdMap[order.code!] = order.id!;
          }
        }
        debugPrint("Loaded order code-to-ID map: $_orderCodeToIdMap");
        // Rebuild screen to render native cards once map is loaded
        _messages.value = List.from(_messages.value);
      }
    } catch (e) {
      debugPrint("Error loading native orders mapping: $e");
    }
  }

  // Robust HTML parser to extract orders for native rendering
  List<ParsedOrder> _parseOrdersFromHtml(String html) {
    List<ParsedOrder> parsed = [];
    try {
      // Find all order codes (e.g. #20260626-16243863 or 20260626-16243863)
      final codeRegex = RegExp(r'#?([0-9]{8}-[0-9]+)');
      final codeMatches = codeRegex.allMatches(html).toList();

      // Find all dates (e.g. 26 Jun 2026)
      final dateRegex = RegExp(r'(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})');
      final dateMatches = dateRegex.allMatches(html).toList();

      // Find all statuses
      final statusRegex = RegExp(
        r'(Confirmed|Pending|On\s+Delivery|Delivered|Cancelled|On Delivery)',
        caseSensitive: false,
      );
      final statusMatches = statusRegex.allMatches(html).toList();

      final int count = codeMatches.length;
      for (int i = 0; i < count; i++) {
        final code = codeMatches[i].group(1) ?? '';
        
        // Resolve the database ID using our local map
        int? id = _orderCodeToIdMap[code];
        
        String date = '';
        if (i < dateMatches.length) {
          date = dateMatches[i].group(1) ?? '';
        }

        String status = 'Pending';
        if (i < statusMatches.length) {
          status = statusMatches[i].group(1) ?? 'Pending';
        }

        if (id != null) {
          parsed.add(ParsedOrder(
            code: code,
            id: id,
            status: status.trim(),
            date: date.trim(),
          ));
        }
      }
    } catch (e) {
      debugPrint("Error parsing orders from HTML: $e");
    }
    return parsed;
  }

  Widget _buildNativeOrderCard(ParsedOrder order) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time_rounded;
    
    final normalizedStatus = order.status.toLowerCase();
    if (normalizedStatus.contains('confirm')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (normalizedStatus.contains('deliver')) {
      statusColor = Colors.blue;
      statusIcon = Icons.local_shipping_outlined;
    } else if (normalizedStatus.contains('cancel')) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#${order.code}",
                style: const TextStyle(
                  fontFamily: "PublicSansSerif",
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    order.status,
                    style: TextStyle(
                      fontFamily: "PublicSansSerif",
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                order.date,
                style: TextStyle(
                  fontFamily: "PublicSansSerif",
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffE8181B), // Solid brand red
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                debugPrint("Tapped native View Details for order: ${order.id}");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetails(id: order.id),
                  ),
                );
              },
              child: const Text(
                "View Details",
                style: TextStyle(
                  fontFamily: "PublicSansSerif",
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Add initial welcome message
    String userGreeting = is_logged_in.$ 
        ? "Hello <b>${user_name.$ ?? ''}</b>!" 
        : "Hello there!";
    
    _messages.value = [
      ChatbotMessage(
        text: "$userGreeting I am your Ideal Traders assistant. How can I help you today?",
        isBot: true,
        timestamp: DateTime.now(),
      )
    ];

    // Auto-load orders and load mapping in background when logged-in user opens chatbot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (is_logged_in.$) {
        _fetchOrderIdsMap();
        if (!_ordersLoaded) {
          _ordersLoaded = true;
          _loadMyOrders();
        }
      }
    });
  }

  @override
  void dispose() {
    _messages.dispose();
    _isTyping.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.value = List.from(_messages.value)..add(ChatbotMessage(
      text: text,
      isBot: false,
      timestamp: DateTime.now(),
    ));
    _isTyping.value = true;
    
    _textController.clear();
    _scrollToBottom();

    // Call API
    final response = await LocalChatbotRepository().sendMessage(text);
    
    _isTyping.value = false;
    _messages.value = List.from(_messages.value)..add(ChatbotMessage(
      text: response["reply"] ?? "Sorry, I didn't get that.",
      isBot: true,
      timestamp: DateTime.now(),
    ));
    
    _scrollToBottom();
  }

  Future<void> _loadMyOrders() async {
    _isTyping.value = true;
    _scrollToBottom();

    // Fetch fresh mapping in background
    _fetchOrderIdsMap();

    final response = await LocalChatbotRepository().getMyOrders();

    _isTyping.value = false;
    if (response["reply"] != null) {
      _messages.value = List.from(_messages.value)..add(ChatbotMessage(
        text: response["reply"],
        isBot: true,
        timestamp: DateTime.now(),
      ));
    }

    _scrollToBottom();
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/$whatsappNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black12,
        backgroundColor: lightGreenBg,
        leading: UsefulElements.backButton(context),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                image: DecorationImage(
                  image: NetworkImage(chatbotLogoUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ideal Traders AI Assistant",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const Text(
                  "We're online to help!",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ValueListenableBuilder<List<ChatbotMessage>>(
              valueListenable: _messages,
              builder: (context, messages, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageRow(message);
                  },
                );
              },
            ),
          ),
          
          // Typing indicator
          ValueListenableBuilder<bool>(
            valueListenable: _isTyping,
            builder: (context, isTyping, _) {
              if (isTyping) return _buildTypingIndicator();
              return const SizedBox.shrink();
            },
          ),

          // Quick actions panel
          _buildQuickActions(),

          // Input field
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatbotMessage message) {
    // Print the raw HTML to the console so we can inspect its structure
    debugPrint("CHATBOT MESSAGE HTML: ${message.text}");

    if (message.isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(chatbotLogoUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bubbleBotBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: () {
                  final parsedOrders = _parseOrdersFromHtml(message.text);
                  if (parsedOrders.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              "📦 Your Recent Orders",
                              style: TextStyle(
                                fontFamily: "PublicSansSerif",
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        ...parsedOrders.map((order) => _buildNativeOrderCard(order)),
                      ],
                    );
                  }
                  
                  return Html(
                    data: message.text,
                  onLinkTap: (url, attributes, element) async {
                    // Debug log the tap, URL, and all HTML attributes
                    debugPrint("CHATBOT LINK TAPPED: url=$url");
                    debugPrint("HTML Attributes: $attributes");

                    if (url != null) {
                      final uri = Uri.parse(url);
                      
                      // 0. Check for Product and Category navigation links first
                      final productIndex = uri.pathSegments.indexOf('product');
                      final categoryIndex = uri.pathSegments.indexOf('category');

                      if (productIndex != -1 && uri.pathSegments.length > productIndex + 1) {
                        final slug = uri.pathSegments[productIndex + 1];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetails(slug: slug),
                          ),
                        );
                        return;
                      } else if (categoryIndex != -1 && uri.pathSegments.length > categoryIndex + 1) {
                        final slug = uri.pathSegments[categoryIndex + 1];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryProducts(slug: slug),
                          ),
                        );
                        return;
                      }
                    }

                    int? orderId;

                    // 1. Try to extract from the URL string
                    if (url != null) {
                      final uri = Uri.parse(url);
                      for (int i = 0; i < uri.pathSegments.length - 1; i++) {
                        final segment = uri.pathSegments[i].toLowerCase();
                        if (segment == 'purchase-history' ||
                            segment == 'purchase_history' ||
                            segment == 'purchase-history-details' ||
                            segment == 'purchase_history_details' ||
                            segment == 'order' ||
                            segment == 'orders' ||
                            segment == 'order-details' ||
                            segment == 'order_details') {
                          orderId = int.tryParse(uri.pathSegments[i + 1]);
                          if (orderId != null) break;
                        }
                      }
                    }
                    // 1.5. Fallback: if last segment of URL is a number and contains order keywords
                    if (orderId == null && url != null) {
                      try {
                        final uri = Uri.parse(url);
                        if (uri.pathSegments.isNotEmpty) {
                          final lastSegment = uri.pathSegments.last;
                          final parsedId = int.tryParse(lastSegment);
                          final lowerUrl = url.toLowerCase();
                          if (parsedId != null &&
                              (lowerUrl.contains('history') ||
                               lowerUrl.contains('order') ||
                               lowerUrl.contains('purchase') ||
                               lowerUrl.contains('details'))) {
                            orderId = parsedId;
                          }
                        }
                      } catch (_) {}
                    }

                    // 2. Try to extract from data-id or data-order-id attributes
                    if (orderId == null) {
                      if (attributes.containsKey('data-id')) {
                        orderId = int.tryParse(attributes['data-id'] ?? '');
                      }
                      if (orderId == null && attributes.containsKey('data-order-id')) {
                        orderId = int.tryParse(attributes['data-order-id'] ?? '');
                      }
                    }

                    // 3. Try to extract from any numerical value in the onclick attribute
                    if (orderId == null && attributes.containsKey('onclick')) {
                      final onclickVal = attributes['onclick'] ?? '';
                      // Look for pattern like purchase_history/163 or order/163 inside javascript
                      final regExp = RegExp(r'(?:purchase[-_]history|order|orders)[^0-9]*([0-9]+)', caseSensitive: false);
                      final match = regExp.firstMatch(onclickVal);
                      if (match != null) {
                        orderId = int.tryParse(match.group(1) ?? '');
                      }
                    }

                    // 4. If we found a valid order ID, navigate to OrderDetails native screen
                    if (orderId != null) {
                      debugPrint("Found Order ID: $orderId. Navigating to native OrderDetails...");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetails(id: orderId),
                        ),
                      );
                      return;
                    }

                    // Fallback to launching in browser if it's a regular external link
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(13.5),
                      color: Colors.black87,
                      fontFamily: "PublicSansSerif",
                    ),
                    "a": Style(
                      color: Colors.blue.shade800,
                      textDecoration: TextDecoration.underline,
                    ),
                    "b": Style(
                      fontWeight: FontWeight.bold,
                    ),
                  },
                );
              }(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontFamily: "PublicSansSerif",
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 15, right: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(chatbotLogoUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleBotBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(150),
                const SizedBox(width: 4),
                _buildDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (value * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            // Order button depending on login status
            if (is_logged_in.$)
              _buildQuickActionChip(
                label: "📦 My Orders",
                onTap: _loadMyOrders,
              )
            else
              _buildQuickActionChip(
                label: "📦 Track Order",
                onTap: () => _sendMessage("Track Order"),
              ),
            
            const SizedBox(width: 8),
            _buildQuickActionChip(
              label: "🔍 Search Products",
              onTap: () => _sendMessage("Search Products"),
            ),
            
            const SizedBox(width: 8),
            _buildQuickActionChip(
              label: "💬 WhatsApp",
              onTap: _openWhatsApp,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xff25D366) : Colors.white,
          border: Border.all(
            color: isHighlight ? const Color(0xff25D366) : primaryGreen.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isHighlight ? Colors.white : primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: "PublicSansSerif",
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
