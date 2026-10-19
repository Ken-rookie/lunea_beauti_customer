import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _postal = TextEditingController();

  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  bool _saving = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadAddresses(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _barangay.dispose();
    _city.dispose();
    _province.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Please sign in again.');

      final result = await _supabase
          .from('customer_addresses')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _addresses = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load addresses: $e')));
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Please sign in again.');

      await _supabase.from('customer_addresses').insert({
        'user_id': user.id,
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address_line': _address.text.trim(),
        'barangay': _barangay.text.trim(),
        'city': _city.text.trim(),
        'province': _province.text.trim(),
        'postal_code': _postal.text.trim().isEmpty ? null : _postal.text.trim(),
        'is_default': _addresses.isEmpty,
      });

      if (!mounted) return;

      _name.clear();
      _phone.clear();
      _address.clear();
      _barangay.clear();
      _city.clear();
      _province.clear();
      _postal.clear();

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );

      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save address: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _supabase.from('customer_addresses').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address deleted.')));

      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete address: $e')));
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.streetAddress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Please enter $label'
            : null,
      ),
    );
  }

  void _showAddAddressForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add delivery address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _field('Full Name', _name),
                  _field(
                    'Phone Number',
                    _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _field('House No. / Street', _address),
                  _field('Barangay', _barangay),
                  _field('City / Municipality', _city),
                  _field('Province', _province),
                  _field(
                    'Postal Code (optional)',
                    _postal,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setSheetState(() => _saving = true);
                              await _saveAddress();
                              if (sheetContext.mounted) {
                                setSheetState(() => _saving = false);
                              }
                            },
                      child: Text(_saving ? 'Saving...' : 'Save Address'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            onPressed: _loadAddresses,
            tooltip: 'Refresh addresses',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAddresses,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Your saved delivery addresses',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (_addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 35),
                      child: Column(
                        children: [
                          Icon(Icons.location_on_outlined, size: 55),
                          SizedBox(height: 12),
                          Text('No saved addresses yet.'),
                        ],
                      ),
                    ),
                  ..._addresses.map((address) {
                    final id = address['id'].toString();
                    final fullAddress =
                        [
                              address['address_line'],
                              'Barangay ${address['barangay']}',
                              address['city'],
                              address['province'],
                              address['postal_code'],
                            ]
                            .where(
                              (part) =>
                                  part != null &&
                                  part.toString().trim().isNotEmpty,
                            )
                            .join(', ');

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xfff0e5e3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xffffeff0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: Color(0xff98445c),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                address['full_name'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (address['is_default'] == true) ...[
                              const SizedBox(width: 8),
                              const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Color(0xff98445c),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '$fullAddress\n${address['phone']}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Delete address',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteAddress(id),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }
}
