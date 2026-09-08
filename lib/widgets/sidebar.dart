import 'package:flutter/material.dart';
import '../app.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onSelect;
  final VoidCallback onLogout;

  const Sidebar({super.key, required this.currentPage, required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jalon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('recherche ingénieur', style: monoStyle(size: 11)),
          const SizedBox(height: 36),
          _NavItem(label: 'Profil', icon: Icons.person_outline, selected: currentPage == AppPage.profil, onTap: () => onSelect(AppPage.profil)),
          _NavItem(label: 'Nouvelle candidature', icon: Icons.auto_awesome_outlined, selected: currentPage == AppPage.candidature, onTap: () => onSelect(AppPage.candidature)),
          _NavItem(label: 'Suivi', icon: Icons.grid_view_outlined, selected: currentPage == AppPage.suivi, onTap: () => onSelect(AppPage.suivi)),
          const Spacer(),
          _NavItem(label: 'Déconnexion', icon: Icons.logout, selected: false, muted: true, onTap: onLogout),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : (muted ? AppColors.inkFaint : AppColors.inkSoft);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.blueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
