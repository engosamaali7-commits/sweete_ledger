class WalletModel {
  final int? id;
  final String name;
  final bool isActive;
  final String? createdAt;

  WalletModel({
    this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }
}