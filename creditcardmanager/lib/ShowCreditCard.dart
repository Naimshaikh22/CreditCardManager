import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:creditcardmanager/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:creditcardmanager/database_helper.dart';
import 'package:creditcardmanager/AddCreditCard.dart';
import 'package:intl/intl.dart';

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
}

class CreditCardListPage extends StatefulWidget {
  @override
  _CreditCardListPageState createState() => _CreditCardListPageState();
}

class _CreditCardListPageState extends State<CreditCardListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final LocalDatabase localDatabase = LocalDatabase.instance;
  List<CreditCard> onlineCards = [];
  List<CreditCard> offlineCards = [];

  @override
  void initState() {
    super.initState();
    _loadCreditCards();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncUnsyncedData();
      }
    });
    checkDueDates(); // Check for due dates when the page loads
  }

  Future<void> syncUnsyncedData() async {
    final unsyncedCards = await localDatabase.fetchUnsyncedCards();
    for (final card in unsyncedCards) {
      try {
        await firestore.collection('credit_cards').add(card);
        await localDatabase.markAsSynced(card['id']);
      } catch (e) {
        print("Error syncing card: $e");
      }
    }
  }

  Future<void> _loadCreditCards() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // Offline mode: load from local database
      final offlineData = await localDatabase.fetchAllCards();
      offlineCards = offlineData.map((data) => CreditCard.fromFirestore(data)).toList();
      setState(() {});
    } else {
      // Online mode: load from Firestore and listen for real-time updates
      firestore.collection('credit_cards').snapshots().listen((snapshot) {
        onlineCards = snapshot.docs
            .map((doc) => CreditCard.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();
        setState(() {});
      });
    }
  }

  Future<void> checkDueDates() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final formattedTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    try {
      final snapshot = await firestore.collection('credit_cards').get();

      final cardsDueTomorrow = snapshot.docs.map((doc) {
        return CreditCard.fromFirestore(doc.data() as Map<String, dynamic>);
      }).where((card) {
        final cardDueDate = DateTime(
          card.dueDate.year,
          card.dueDate.month,
          card.dueDate.day,
        );
        return cardDueDate == formattedTomorrow;
      }).toList();

      if (cardsDueTomorrow.isNotEmpty) {
        showDueDateDialog(cardsDueTomorrow);
      }
    } catch (e) {
      print('Error checking due dates: $e');
    }
  }

  void showDueDateDialog(List<CreditCard> cardsDueTomorrow) {
    final cardDetails = cardsDueTomorrow
        .map((card) =>
            '${card.company} (****${card.cardNumber.substring(card.cardNumber.length - 4)})')
        .join('\n');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upcoming Due Dates'),
          content: Text(
            'The following cards have a due date tomorrow:\n\n$cardDetails',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCards = [...offlineCards, ...onlineCards];
    allCards.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Credit Card Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: allCards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCreditCards,
              child: ListView.builder(
                itemCount: allCards.length,
                itemBuilder: (context, index) {
                  final card = allCards[index];
                  return CreditCardWidget(creditCard: card);  // Use CreditCardWidget here
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCreditCardPage()),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CreditCardWidget extends StatelessWidget {
  final CreditCard creditCard;

  const CreditCardWidget({Key? key, required this.creditCard}) : super(key: key);

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
