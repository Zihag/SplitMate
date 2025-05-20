import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final int amount;
  final String description;
  final DateTime createdAt;
  final String createdBy;
  final List<String> participants;
  final bool isCheckPoint;

  Expense(
      {required this.id,
      required this.amount,
      required this.description,
      required this.createdAt,
      required this.createdBy,
      required this.participants,
      this.isCheckPoint = false});

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'participants': participants,
      'isCheckPoint': isCheckPoint,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      amount: map['amount'],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'],
      participants: List<String>.from(
        map['participants'],
      ),
      isCheckPoint: map['isCheckPoint'] ?? false,
    );
  }
}
