import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'database_helper.dart';

class AddCreditCardPage extends StatefulWidget {
  const AddCreditCardPage({Key? key}) : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController currentDueController = TextEditingController();
  final TextEditingController totalDueController = TextEditingController();

  bool _isProcessing = false;
  final firestore = FirebaseFirestore.instance;
  final localDatabase = LocalDatabase.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Add Credit Card',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.black,
      ),
       body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Card Company Field
                _buildTextField(
                  controller: companyController,
                  labelText: "Card Company",
                  icon: Icons.corporate_fare,
                  validatorMessage: "Please enter card company",
                ),
                const SizedBox(height: 10),

                // Card Number Field
                _buildTextField(
                  controller: cardNumberController,
                  labelText: "Card Number",
                  icon: Icons.credit_card,
                  isNumeric: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    if (value.length != 16 ||
                        !RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Enter a valid 16-digit card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Due Date Field
                _buildDateField(
                  controller: dueDateController,
                  labelText: "Due Date (YYYY-MM-DD)",
                  icon: Icons.date_range,
                  validatorMessage: "Please enter due date",
                ),
                const SizedBox(height: 10),

                // Current Due Field
                _buildTextField(
                  controller: currentDueController,
                  labelText: "Current Due Amount",
                  icon: Icons.money,
                  isNumeric: true,
                  validatorMessage: "Please enter current due amount",
                ),
                const SizedBox(height: 10),

                // Total Due Field
                _buildTextField(
                  controller: totalDueController,
                  labelText: "Total Due Amount",
                  icon: Icons.money,
                  isNumeric: true,
                  validatorMessage: "Please enter total due amount",
                ),
                const SizedBox(height: 25),

                // Submit Button
                _isProcessing
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed:  _saveCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Add Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isNumeric = false,
    String? validatorMessage,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelText: labelText,
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator:
          validator ?? (value) => value!.isEmpty ? validatorMessage : null,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String validatorMessage,
  }) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) {
          controller.text = "${selectedDate.toLocal()}".split(' ')[0];
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(
          controller: controller,
          labelText: labelText,
          icon: icon,
          validatorMessage: validatorMessage,
        ),
      ),
    );
  }
  

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      final cardData = {
        'cardNumber': cardNumberController.text,
        'company': companyController.text,
        'dueDate': dueDateController.text,
        'currentDueAmount': double.parse(currentDueController.text),
        'totalDueAmount': double.parse(totalDueController.text),
        'synced': 0,
      };

      try {
        if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
          await localDatabase.insertCard(cardData);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card added successfully!'),
            backgroundColor: Colors.green,
          ));
        } else {
          await firestore.collection('credit_cards').add(cardData);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card added successfully!'),
            backgroundColor: Colors.green,
          ));
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
