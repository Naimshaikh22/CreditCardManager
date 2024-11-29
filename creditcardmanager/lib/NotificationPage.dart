import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<CreditCard>> fetchCardsDueTomorrow() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final formattedTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    try {
      final snapshot = await firestore.collection('credit_cards').get();

      return snapshot.docs.map((doc) {
        return CreditCard.fromFirestore(doc.data() as Map<String, dynamic>);
      }).where((card) {
        final cardDueDate = DateTime(
          card.dueDate.year,
          card.dueDate.month,
          card.dueDate.day,
        );
        return cardDueDate == formattedTomorrow;
      }).toList();
    } catch (e) {
      print('Error fetching cards due tomorrow: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<CreditCard>>(
        future: fetchCardsDueTomorrow(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No cards due tomorrow.'));
          }

          final creditCards = snapshot.data!;
          creditCards.sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return ListView.builder(
            itemCount: creditCards.length,
            itemBuilder: (context, index) {
              final card = creditCards[index];
              return NotificationCard(creditCard: card);
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final CreditCard creditCard;

  const NotificationCard({Key? key, required this.creditCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 6,
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
                  creditCard.company.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.credit_card,
                  color: Colors.white.withOpacity(0.8),
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              creditCard.cardNumber.replaceAllMapped(
                  RegExp(r'.{4}'), (match) => '${match.group(0)} '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DUE DATE',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      DateFormat.yMMMd().format(creditCard.dueDate),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT DUE',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\$${creditCard.currentDueAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL DUE',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\$${creditCard.totalDueAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


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
      dueDate = dueDateField.toDate(); // Convert Firestore Timestamp to DateTime
    } else if (dueDateField is String) {
      dueDate = DateTime.parse(dueDateField); // Parse ISO8601 date string
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
}
