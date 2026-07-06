import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Security Settings',
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard([
            _buildSettingsTile(Icons.lock_outline, 'Change Password',
                'Update your account password'),
            _buildSettingsTile(Icons.fingerprint, 'Biometric Login',
                'Enable Face ID or Fingerprint',
                isToggle: true, toggleValue: true),
            _buildSettingsTile(Icons.security, 'Two-Factor Authentication',
                'Add an extra layer of security'),
          ]),
          const SizedBox(height: 32),
          Text(
            'Data & Privacy',
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard([
            _buildSettingsTile(Icons.share_outlined, 'Data Sharing',
                'Manage who can see your health data'),
            _buildSettingsTile(Icons.download_outlined, 'Download My Data',
                'Get a copy of your medical history'),
            _buildSettingsTile(Icons.delete_outline, 'Delete Account',
                'Permanently remove your data',
                isDestructive: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle,
      {bool isToggle = false,
      bool toggleValue = false,
      bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDestructive ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isDestructive
                ? const Color(0xFFEF4444)
                : const Color(0xFF14B8A6),
            size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDestructive
                ? const Color(0xFFEF4444)
                : const Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF94A3B8)),
      ),
      trailing: isToggle
          ? Switch(
              value: toggleValue,
              onChanged: (val) {},
              activeColor: const Color(0xFF14B8A6),
            )
          : const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      onTap: () {},
    );
  }
}
