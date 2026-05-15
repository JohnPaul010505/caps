import 'package:flutter/material.dart';
import '../core/app_theme.dart';

// ─── App Avatar ──────────────────────────────────────────────────────────────

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;

  const AppAvatar({super.key, required this.name, this.size = 40});

  Color get _color {
    const colors = [
      Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF059669),
      Color(0xFFD97706), Color(0xFFDC2626), Color(0xFF0891B2),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width:  size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _color.withOpacity(0.2),
      border: Border.all(color: _color.withOpacity(0.4), width: 1.5),
    ),
    alignment: Alignment.center,
    child: Text(
      _initials,
      style: TextStyle(
        color:      _color,
        fontWeight: FontWeight.w700,
        fontSize:   size * 0.33,
      ),
    ),
  );
}

// ─── Status Badge ────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg, text, border;
    switch (status.toLowerCase()) {
      case 'active':
        bg = AppColors.green.withOpacity(0.12);
        text = AppColors.green;
        border = AppColors.green.withOpacity(0.3);
        break;
      case 'expiring':
      case 'exp. soon':
        bg = AppColors.amber.withOpacity(0.12);
        text = AppColors.amber;
        border = AppColors.amber.withOpacity(0.3);
        break;
      case 'inactive':
      case 'expired':
        bg = Colors.grey.withOpacity(0.12);
        text = Colors.grey;
        border = Colors.grey.withOpacity(0.3);
        break;
      default:
        bg = AppColors.blue.withOpacity(0.12);
        text = AppColors.blue;
        border = AppColors.blue.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Fit Card ────────────────────────────────────────────────────────────────

class FitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const FitCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? AppColors.cardBorder.withOpacity(0.5),
      ),
    ),
    child: child,
  );
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        )),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!,
            style: const TextStyle(color: AppColors.purpleLight, fontSize: 13)),
        ),
    ],
  );
}

// ─── Gradient Progress Bar ───────────────────────────────────────────────────

class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final double height;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.purple,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
        Container(
          height: height,
          width: constraints.maxWidth * value.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ],
    ),
  );
}

// ─── Full-screen Loading ─────────────────────────────────────────────────────

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: CircularProgressIndicator(color: AppColors.purple),
    ),
  );
}

// ─── Bottom Nav Wrapper ──────────────────────────────────────────────────────

class FitBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const FitBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF13131E),
      border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      items: items,
      onTap: onTap,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

// ─── Stat Mini Card ──────────────────────────────────────────────────────────

class StatMiniCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color accentColor;

  const StatMiniCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.accentColor = AppColors.purple,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            )),
          const SizedBox(height: 2),
          Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subtext, fontSize: 10.5)),
        ],
      ),
    ),
  );
}
