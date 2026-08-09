class TransactionModel {
  final int? id;
  final int dailyRecordId;
  final int walletId;
  final String category;
  final double amount;
  final String? note;
  final String? createdAt;

  TransactionModel({
    this.id,
    required this.dailyRecordId,
    required this.walletId,
    required this.category,
    required this.amount,
    this.note,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'daily_record_id': dailyRecordId,
      'wallet_id': walletId,
      'category': category,
      'amount': amount,
      'note': note,
      'created_at': createdAt,
    };
  }
}