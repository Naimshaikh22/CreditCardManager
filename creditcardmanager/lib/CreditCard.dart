import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCard {
  final String cardNumber;
  final String company;
  final DateTime dueDate;
  final double currentDueAmount;
  final double totalDueAmount;

  CreditCard({
    required this.cardNumber,
    required this.company,
    required this.dueDate,
    required this.currentDueAmount,
    required this.totalDueAmount,
  });

  factory CreditCard.fromFirestore(Map<String, dynamic> data) {
    final dueDateField = data['dueDate'];

    DateTime dueDate;
    if (dueDateField is Timestamp) {
      dueDate = dueDateField.toDate();
    } else if (dueDateField is String) {
      dueDate = DateTime.parse(dueDateField);
    } else {
      throw FormatException("Invalid due date format");
    }

    return CreditCard(
      cardNumber: data['cardNumber'] as String,
      company: data['company'] as String,
      dueDate: dueDate,
      currentDueAmount: (data['currentDueAmount'] as num).toDouble(),
      totalDueAmount: (data['totalDueAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'company': company,
      'dueDate': dueDate.toIso8601String(),
      'currentDueAmount': currentDueAmount,
      'totalDueAmount': totalDueAmount,
    };
  }
}
