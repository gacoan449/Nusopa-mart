import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'social_feed_screen.dart';
import 'groups_screen.dart';
import 'social_profile_screen.dart';

/// Shell utama pengalaman sosial Nusopa.Mart.
/// Beranda dibuat sebagai Feed ala Facebook; marketplace/Rekber tidak menjadi tab utama.
class SocialHomeScreen extends StatefulWidget {
  const SocialHomeScreen({super.key});
  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[SocialFeedScreen(), GroupsScreen(), SocialProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF2FF),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Grup'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Judul section reusable untuk halaman sosial.
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
