class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final String type; // 'qr', 'phone', 'card', 'wallet'
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.isActive = true,
  });
}