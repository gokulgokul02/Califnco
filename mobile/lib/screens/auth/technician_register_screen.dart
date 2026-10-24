import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class TechnicianRegisterScreen extends StatefulWidget {
  const TechnicianRegisterScreen({super.key});

  @override
  State<TechnicianRegisterScreen> createState() => _TechnicianRegisterScreenState();
}

class _TechnicianRegisterScreenState extends State<TechnicianRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  int _yearsExperience = 3;
  String _specialization = 'Domestic RO & UV Purifiers';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create auth user
      await FirebaseService.instance.registerCustomer(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      // 2. Submit technician application
      await FirebaseService.instance.submitTechnicianApplication(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        yearsExperience: _yearsExperience,
        specialization: _specialization,
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
              'Your Field Service Engineer registration has been submitted to Califnco Operations.\n\n'
              'Our operations desk verifies certifications and service regions. Once approved in the Admin Console, field service assignments and job dispatch will unlock automatically.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
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
        title: const Text('Apply as Service Technician'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  children: [
                    Icon(Icons.engineering, color: primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Join Califnco Certified Field Engineering Fleet. Service RO purifiers, conduct TDS audits, and earn per ticket.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xff0f2b3e), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Technician Full Name *', prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Phone *', prefixIcon: Icon(Icons.phone)),
                validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit number' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Account Password *', prefixIcon: Icon(Icons.lock)),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City *', prefixIcon: Icon(Icons.location_city)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _areaCtrl,
                      decoration: const InputDecoration(labelText: 'Service Region / Hub *', prefixIcon: Icon(Icons.map)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _specialization,
                decoration: const InputDecoration(
                  labelText: 'Purifier Technical Specialization',
                  prefixIcon: Icon(Icons.handyman),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Domestic RO & UV Purifiers',
                    child: Text('Domestic RO & UV Purifiers', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Commercial 50 LPH RO Plants',
                    child: Text('Commercial 50 LPH RO Plants', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Membrane Replacement & Descaling',
                    child: Text('Membrane Replacement & Descaling', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Water Softeners & Booster Pumps',
                    child: Text('Water Softeners & Booster Pumps', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (v) => setState(() => _specialization = v!),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Text('Field Experience:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _yearsExperience.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '$_yearsExperience Years',
                      onChanged: (v) => setState(() => _yearsExperience = v.round()),
                    ),
                  ),
                  Text('$_yearsExperience Yrs', style: const TextStyle(fontWeight: FontWeight.bold, color: primary)),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],

              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(16)),
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application for Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
