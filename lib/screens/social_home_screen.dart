import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'social_feed_screen.dart';
import 'groups_screen.dart';
import 'social_profile_screen.dart';
import 'home_screen.dart' show HomeScreen;

/// Shell baru untuk pengalaman sosial.
/// Tab Marketplace tetap tersedia sehingga fitur lama tidak dihapus.
class SocialHomeScreen extends StatefulWidget {
  const SocialHomeScreen({super.key});
  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const SocialFeedScreen(),
      const GroupsScreen(),
      const HomeScreen(),
      const SocialProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF2FF),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: 'Grup'),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: 'Belanja'),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Widget kecil yang bisa dipakai jika nanti header shell membutuhkan judul.
class SocialSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SocialSectionTitle({super.key, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
      if (subtitle != null) Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
    ]),
  );
}
