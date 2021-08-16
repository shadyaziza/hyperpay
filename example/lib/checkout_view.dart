import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyperpay/hyperpay.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({
    Key? key,
  }) : super(key: key);

  @override
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  TextEditingController holderNameController = TextEditingController();
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryController = TextEditingController();
  TextEditingController cvvController = TextEditingController();

  BrandType brandType = BrandType.none;
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  bool isLoading = false;

  /// Initialize HyperPay session
  void initPaymentSession(
    BrandType brandType,
    double amount,
  ) {
    CheckoutSettings _checkoutSettings = CheckoutSettings(
      brand: brandType,
      amount: amount,
      additionalParams: {
        'merchantTransactionId': '#123456',
      },
    );

    HyperpayPlugin.instance.initSession(checkoutSetting: _checkoutSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            autovalidateMode: autovalidateMode,
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    SizedBox(height: 10),
                    // Holder
                    TextFormField(
                      controller: holderNameController,
                      decoration: _inputDecoration(
                        label: "Card Holder",
                        hint: "Jane Jones",
                        icon: Icons.account_circle_rounded,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Number
                    TextFormField(
                      controller: cardNumberController,
                      decoration: _inputDecoration(
                        label: "Card Number",
                        hint: "0000 0000 0000 0000",
                        icon: 'assets/images/${brandType.asString}.png',
                      ),
                      onChanged: (value) {
                        setState(() {
                          brandType = value.detectBrand;
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(brandType.maxLength),
                        CardNumberInputFormatter()
                      ],
                      validator: (String? number) => brandType.validateNumber(number ?? ""),
                    ),
                    SizedBox(height: 10),
                    // Expiry date
                    TextFormField(
                      controller: expiryController,
                      decoration: _inputDecoration(
                        label: "Expiry Date",
                        hint: "MM/YY",
                        icon: Icons.date_range_rounded,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        CardMonthInputFormatter(),
                      ],
                      validator: (String? date) => CardInfo.validateDate(date ?? ""),
                    ),
                    SizedBox(height: 10),
                    // CVV
                    TextFormField(
                      controller: cvvController,
                      decoration: _inputDecoration(
                        label: "CVV",
                        hint: "000",
                        icon: Icons.confirmation_number_rounded,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (String? cvv) => CardInfo.validateCVV(cvv ?? ""),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final bool valid = Form.of(context)?.validate() ?? false;
                                if (valid) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  // Make a CardInfo from the controllers
                                  CardInfo card = CardInfo(
                                    holder: holderNameController.text,
                                    cardNumber: cardNumberController.text.replaceAll(' ', ''),
                                    cvv: cvvController.text,
                                    expiryMonth: expiryController.text.split('/')[0],
                                    expiryYear: '20' + expiryController.text.split('/')[1],
                                  );

                                  initPaymentSession(
                                    brandType,
                                    10.0,
                                  );

                                  try {
                                    // Start transaction
                                    await HyperpayPlugin.instance.pay(card);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment approved 🎉'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } on HyperpayException catch (exception) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(exception.details ?? exception.message),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } catch (exception) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$exception'),
                                      ),
                                    );
                                  }

                                  setState(() {
                                    isLoading = false;
                                  });
                                } else {
                                  setState(() {
                                    autovalidateMode = AutovalidateMode.onUserInteraction;
                                  });
                                }
                              },
                        child: Text(
                          isLoading ? 'Processing your request, please wait...' : 'PAY',
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? label, String? hint, dynamic icon}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
      prefixIcon: icon is IconData
          ? Icon(icon)
          : Container(
              padding: EdgeInsets.all(6),
              width: 10,
              child: Image.asset(
                icon,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.credit_card),
              ),
            ),
    );
  }
}