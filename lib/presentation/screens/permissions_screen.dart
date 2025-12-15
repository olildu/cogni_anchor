import 'package:flutter/material.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool locationEnabled = true;
  bool microphoneEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // 🔶 TOP APP BAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA866),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Turn on live location and\nmicrophone',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balance for back icon
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 LOCATION TOGGLE
            _permissionTile(
              title: 'Allow app to access your location',
              value: locationEnabled,
              onChanged: (val) {
                setState(() {
                  locationEnabled = val;
                });
              },
            ),

            const SizedBox(height: 20),

            // 🔹 MICROPHONE TOGGLE
            _permissionTile(
              title: 'Allow app to access your microphone',
              value: microphoneEnabled,
              onChanged: (val) {
                setState(() {
                  microphoneEnabled = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 REUSABLE TOGGLE TILE
  Widget _permissionTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2ED573), // green toggle
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

