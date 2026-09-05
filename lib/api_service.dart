import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'HARVESTHUB_API_URL',
    defaultValue: 'https://maphric-express-api.onrender.com/api/v1',
  );
  String? token;
  Map<String, dynamic> currentUser = {};

  Future<bool> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString('harvesthub_token');
    final savedUser = preferences.getString('harvesthub_user');
    if (savedUser != null) {
      try {
        currentUser = Map<String, dynamic>.from(jsonDecode(savedUser));
      } on FormatException {
        await preferences.remove('harvesthub_token');
        await preferences.remove('harvesthub_user');
        token = null;
        currentUser = {};
      }
    }
    return token != null;
  }

  Future<void> saveSession(
    String value,
    Map<String, dynamic> authenticatedUser,
  ) async {
    token = value;
    currentUser = authenticatedUser;
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString('harvesthub_token', value),
      preferences.setString('harvesthub_user', jsonEncode(authenticatedUser)),
    ]);
  }

  Future<void> logout() async {
    token = null;
    currentUser = {};
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove('harvesthub_token'),
      preferences.remove('harvesthub_user'),
    ]);
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Map<String, String> get publicHeaders => {'Content-Type': 'application/json'};

  dynamic decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ApiException('The server returned an unreadable response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (body is Map) {
        throw ApiException(
          (body['detail'] ?? body['error'] ?? body.values.first).toString(),
        );
      }
      throw ApiException('Request failed (${response.statusCode})');
    }
    return body;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/accounts/users/login/'),
          headers: publicHeaders,
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 70));
    final data = Map<String, dynamic>.from(decode(response));
    final authenticatedUser = Map<String, dynamic>.from(data['user']);
    await saveSession(data['token'] as String, authenticatedUser);
    return authenticatedUser;
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final names = name.trim().split(RegExp(r'\s+'));
    final username =
        '${email.split('@').first.replaceAll(RegExp('[^a-zA-Z0-9]'), '')}${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final response = await http
        .post(
          Uri.parse('$baseUrl/accounts/users/register/'),
          headers: publicHeaders,
          body: jsonEncode({
            'username': username,
            'email': email.trim().toLowerCase(),
            'phone_number': phone.trim(),
            'password': password,
            'password2': password,
            'first_name': names.first,
            'last_name': names.skip(1).join(' '),
          }),
        )
        .timeout(const Duration(seconds: 70));
    decode(response);
  }

  Future<List<Product>> products() async {
    final response = await http
        .get(Uri.parse('$baseUrl/products/products/'), headers: headers)
        .timeout(const Duration(seconds: 70));
    final data = decode(response);
    final rows = data is List ? data : (data['results'] as List);
    return rows
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CustomerOrder>> orders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/orders/'), headers: headers)
        .timeout(const Duration(seconds: 70));
    final data = decode(response);
    final rows = data is List ? data : (data['results'] as List);
    return rows
        .map((item) => CustomerOrder.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DeliverySettings> deliverySettings() async {
    final response = await http
        .get(Uri.parse('$baseUrl/orders/delivery-settings/'), headers: headers)
        .timeout(const Duration(seconds: 30));
    return DeliverySettings.fromJson(
      Map<String, dynamic>.from(decode(response)),
    );
  }

  Future<Map<int, int>> wishlist() async {
    final response = await http
        .get(Uri.parse('$baseUrl/products/wishlist/'), headers: headers)
        .timeout(const Duration(seconds: 30));
    final data = decode(response);
    final rows = data is List ? data : (data['results'] as List);
    return {
      for (final raw in rows)
        ((raw['product']['id']) as num).toInt(): (raw['id'] as num).toInt(),
    };
  }

  Future<void> addWishlist(int productId) async {
    decode(
      await http
          .post(
            Uri.parse('$baseUrl/products/wishlist/'),
            headers: headers,
            body: jsonEncode({'product_id': productId}),
          )
          .timeout(const Duration(seconds: 30)),
    );
  }

  Future<void> removeWishlist(int wishlistItemId) async {
    decode(
      await http
          .delete(
            Uri.parse('$baseUrl/products/wishlist/$wishlistItemId/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30)),
    );
  }

  Future<String> askAssistant(
    String message,
    List<Map<String, String>> history,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/ai/chat/'),
          headers: headers,
          body: jsonEncode({'message': message, 'history': history}),
        )
        .timeout(const Duration(seconds: 45));
    return Map<String, dynamic>.from(decode(response))['answer'] as String;
  }

  Future<void> initiateEcoCash(int orderId, String phone) async {
    decode(
      await http
          .post(
            Uri.parse('$baseUrl/payments/initiate/'),
            headers: headers,
            body: jsonEncode({
              'order_id': orderId,
              'method': 'ecocash',
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 45)),
    );
  }

  Future<bool> paymentPaid(int orderId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/payments/status/$orderId/'), headers: headers)
        .timeout(const Duration(seconds: 30));
    return Map<String, dynamic>.from(decode(response))['paid'] == true;
  }

  Future<void> addToCart(int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/items/'),
      headers: headers,
      body: jsonEncode({'product_id': productId, 'quantity': 1}),
    );
    decode(response);
  }

  Future<Map<int, int>> cart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart/items/'),
      headers: headers,
    );
    final data = decode(response);
    final rows = data is List ? data : (data['results'] as List);
    return {
      for (final item in rows)
        ((item['product'] is Map ? item['product']['id'] : item['product'])
                as num)
            .toInt(): (item['quantity'] as num)
            .toInt(),
    };
  }

  Future<void> setCartQuantity(int productId, int quantity) async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart/items/'),
      headers: headers,
    );
    final data = decode(response);
    final rows = data is List ? data : (data['results'] as List);
    Map<String, dynamic>? cartItem;
    for (final rawItem in rows) {
      final item = Map<String, dynamic>.from(rawItem);
      final product = item['product'];
      final itemProductId = product is Map ? product['id'] : product;
      if ((itemProductId as num).toInt() == productId) {
        cartItem = item;
        break;
      }
    }
    if (cartItem == null) {
      if (quantity <= 0) return;
      decode(
        await http.post(
          Uri.parse('$baseUrl/cart/items/'),
          headers: headers,
          body: jsonEncode({'product_id': productId, 'quantity': quantity}),
        ),
      );
      return;
    }
    final itemUrl = Uri.parse('$baseUrl/cart/items/${cartItem['id']}/');
    if (quantity <= 0) {
      decode(await http.delete(itemUrl, headers: headers));
    } else {
      decode(
        await http.patch(
          itemUrl,
          headers: headers,
          body: jsonEncode({'quantity': quantity}),
        ),
      );
    }
  }

  Future<CustomerOrder> checkout({
    required String name,
    required String phone,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/checkout/'),
      headers: headers,
      body: jsonEncode({
        'shipping_name': name,
        'shipping_phone': phone,
        'shipping_address': address,
      }),
    );
    return CustomerOrder.fromJson(Map<String, dynamic>.from(decode(response)));
  }
}
