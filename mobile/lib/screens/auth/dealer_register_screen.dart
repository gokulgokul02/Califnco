import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class DealerRegisterScreen extends StatefulWidget {
  const DealerRegisterScreen({super.key});

  @override
  State<DealerRegisterScreen> createState() => _DealerRegisterScreenState();
}

class _DealerRegisterScreenState extends State<DealerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Tamil Nadu');
  final _pincodeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int _yearsInBusiness = 3;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _fillSampleDealerData() {
    setState(() {
      _businessNameCtrl.text = 'AquaTech Purifiers & Spares';
      _contactPersonCtrl.text = 'Rajesh Kumar';
      _emailCtrl.text = 'rajesh.aquatech@gmail.com';
      _phoneCtrl.text = '9840123456';
      _gstinCtrl.text = '33AABCA1234D1ZP';
      _addressCtrl.text = 'Shop 14, Mount Road Electronics Hub';
      _cityCtrl.text = 'Chennai';
      _stateCtrl.text = 'Tamil Nadu';
      _pincodeCtrl.text = '600002';
      _passwordCtrl.text = 'Dealer@1234';
      _yearsInBusiness = 5;
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create or ensure user account
      UserCredential userCred;
      try {
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );
        } else {
          rethrow;
        }
      }

      await userCred.user?.updateDisplayName(_businessNameCtrl.text.trim());

      // 2. Submit application into dealers collection
      await FirebaseService.instance.submitDealerApplication(
        businessName: _businessNameCtrl.text.trim(),
        contactPerson: _contactPersonCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().toUpperCase(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        yearsInBusiness: _yearsInBusiness,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Application Submitted'),
              ],
            ),
            content: const Text(
              'Your dealer wholesale application has been submitted to Califnco Operations.\n\n'
              'Our team reviews GSTIN and business credentials. Once approved in the Admin Dashboard, wholesale pricing (25-35% off retail) and bulk volume orders will unlock automatically.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back to auth
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Wholesale Registration'),
        actions: [
          TextButton.icon(
            onPressed: _fillSampleDealerData,
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text('Fill Sample'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Califnco Dealer Benefits:\n• Tier-1 Wholesale Prices (Save up to 35%)\n• Bulk Ordering & Priority Dispatch\n• Dedicated Technical Service Desk Support',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Business Details
                  Text('Business Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessNameCtrl,
                    decoration: const InputDecoration(labelText: 'Business / Enterprise Name *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter business name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPersonCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Person Name *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter contact person' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstinCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN Number *',
                      hintText: 'e.g. 33AAAAA0000A1Z5',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.length < 15 ? 'Enter valid 15-digit GSTIN' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Expanded(child: Text('Years in Water Purifier Business:')),
                      DropdownButton<int>(
                        value: _yearsInBusiness,
                        items: [1, 2, 3, 5, 8, 10, 15]
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y years')))
                            .toList(),
                        onChanged: (v) => setState(() => _yearsInBusiness = v ?? 1),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Contact & Address
                  Text('Contact & Warehouse Address', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Dealer Official Email *', border: OutlineInputBorder()),
                    validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Business Mobile / WhatsApp *', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 10 ? 'Enter valid phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Shop / Warehouse Address *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter address' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'PIN Code *', border: OutlineInputBorder()),
                          validator: (v) => v!.length != 6 ? '6 digits' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Create Dealer Portal Password *', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      onPressed: _isLoading ? null : _submitApplication,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Dealer Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
