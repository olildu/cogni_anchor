import 'package:cogni_anchor/data/services/pair_context.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DementiaProfileScreen extends StatefulWidget {
  const DementiaProfileScreen({super.key});

  @override
  State<DementiaProfileScreen> createState() => _DementiaProfileScreenState();
}

class _DementiaProfileScreenState extends State<DementiaProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic>? _patientData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _showMsg("Not logged in");
        return;
      }

      String? pairId = PairContext.pairId;

      if (pairId == null) {
        final pair = await _client
            .from('pairs')
            .select()
            .or(
              'patient_user_id.eq.${user.id},caretaker_user_id.eq.${user.id}',
            )
            .maybeSingle();

        if (pair == null) {
          _showMsg("No patient connected");
          setState(() => _loading = false);
          return;
        }

        final fetchedPairId = pair['id'] as String;
        pairId = fetchedPairId;
        PairContext.set(fetchedPairId);
      }

      final pair = await _client
          .from('pairs')
          .select('patient_user_id')
          .eq('id', pairId)
          .single();

      final patientUserId = pair['patient_user_id'];

      if (patientUserId == null) {
        _showMsg("Patient profile not available");
        setState(() => _loading = false);
        return;
      }

      final patient =
          await _client.from('users').select().eq('id', patientUserId).single();

      setState(() {
        _patientData = patient;
        _loading = false;
      });
    } catch (e) {
      _showMsg("Failed to load person");
      setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_patientData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          title: const Text("Person Living With Dementia"),
          backgroundColor: const Color(0xFFFF653A),
        ),
        body: const Center(
          child: Text("No patient data available"),
        ),
      );
    }

    final name = _patientData?['name'] ?? '-';
    final contact = _patientData?['contact'] ?? '-';
    final gender = _patientData?['gender'] ?? '-';
    final dobRaw = _patientData?['date_of_birth'];

    final dob = dobRaw != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(dobRaw))
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _readonlyField("Name", name),
                    _readonlyField("Contact", contact),
                    _readonlyField("Gender", gender),
                    _readonlyField("Date of Birth", dob),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFF653A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text(
              "Person Living With Dementia",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _readonlyField(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(value),
          ),
          const SizedBox(height: 16),
        ],
      );
}
