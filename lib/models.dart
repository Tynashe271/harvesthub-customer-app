class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.slug,
    required this.price,
    required this.stock,
    this.image = '',
    this.description = '',
    this.brand = '',
    this.rating,
  });

  final int id;
  final String name;
  final String category;
  final String slug;
  final double price;
  final int stock;
  final String image;
  final String description;
  final String brand;
  final double? rating;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    category: (json['category_name'] ?? 'Grocery') as String,
    slug: json['slug'] as String,
    price: double.parse(json['price'].toString()),
    stock: (json['stock_quantity'] ?? 0) as int,
    image: (json['image'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    brand: (json['brand'] ?? '') as String,
    rating: json['average_rating'] == null
        ? null
        : double.tryParse(json['average_rating'].toString()),
  );
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });
  final String productName;
  final double unitPrice;
  final int quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productName: (json['product_name'] ?? 'Grocery') as String,
    unitPrice: double.parse(json['unit_price'].toString()),
    quantity: (json['quantity'] as num).toInt(),
  );
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod = '',
    this.paymentStatus = 'unpaid',
    this.shippingName = '',
    this.shippingPhone = '',
    this.shippingAddress = '',
    this.items = const [],
  });

  final int id;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final List<OrderItem> items;

  String get number => 'MAP-${id.toString().padLeft(6, '0')}';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
    id: json['id'] as int,
    total: double.parse(json['total'].toString()),
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    paymentMethod: (json['payment_method'] ?? '') as String,
    paymentStatus: (json['payment_status'] ?? 'unpaid') as String,
    shippingName: (json['shipping_name'] ?? '') as String,
    shippingPhone: (json['shipping_phone'] ?? '') as String,
    shippingAddress: (json['shipping_address'] ?? '') as String,
    items: (json['items'] as List? ?? const [])
        .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );
}

class DeliverySettings {
  const DeliverySettings({
    required this.fee,
    required this.freeThreshold,
    required this.areas,
    required this.estimatedMinutes,
    required this.openingHours,
    required this.policy,
  });
  final double fee;
  final double freeThreshold;
  final String areas;
  final int estimatedMinutes;
  final String openingHours;
  final String policy;

  factory DeliverySettings.fromJson(Map<String, dynamic> json) =>
      DeliverySettings(
        fee: double.parse(json['delivery_fee'].toString()),
        freeThreshold: double.parse(json['free_delivery_threshold'].toString()),
        areas: (json['delivery_areas'] ?? '') as String,
        estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 55,
        openingHours: (json['opening_hours'] ?? '') as String,
        policy: (json['delivery_policy'] ?? '') as String,
      );

  static const fallback = DeliverySettings(
    fee: 0,
    freeThreshold: 0,
    areas: 'Bulawayo',
    estimatedMinutes: 55,
    openingHours: '',
    policy: 'Local delivery from our Bradfield store.',
  );
}
