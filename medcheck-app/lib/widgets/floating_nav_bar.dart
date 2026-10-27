import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final UserRole role;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = UserRole.patient,
  });

  static const double bottomClearance = 100.0;

  List<_NavItem> get _items {
    if (role == UserRole.caregiver) {
      return const [
        _NavItem(icon: CupertinoIcons.house_fill, label: 'Inicio'),
        _NavItem(icon: CupertinoIcons.person_fill, label: 'Perfil'),
      ];
    }
    return [
      const _NavItem(icon: CupertinoIcons.house_fill, label: 'Inicio'),
      _NavItem(svgAsset: 'assets/icons/medicine.svg', label: 'Medicinas'),
      const _NavItem(icon: CupertinoIcons.person_fill, label: 'Perfil'),
    ];
  }

  int get _effectiveIndex {
    if (role == UserRole.caregiver) {
      if (currentIndex == 0) return 0;
      if (currentIndex == 2) return 1;
      return 0;
    }
    return currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.adaptiveNavBarBackground(context),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.adaptiveTileBorder(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == _effectiveIndex;

              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: GestureDetector(
                  onTap: () {
                    if (role == UserRole.caregiver) {
                      onTap(i == 0 ? 0 : 2);
                    } else {
                      onTap(i);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 20 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          opacity: 1.0,
                          child: item.svgAsset != null
                              ? SvgPicture.asset(
                                  item.svgAsset!,
                                  width: 23,
                                  height: 23,
                                  colorFilter: ColorFilter.mode(
                                    isActive
                                        ? Colors.white
                                        : AppColors.adaptiveTextSecondary(
                                            context,
                                          ),
                                    BlendMode.srcIn,
                                  ),
                                )
                              : Icon(
                                  item.icon!,
                                  size: 23,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.adaptiveTextSecondary(
                                          context,
                                        ),
                                ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            reverseDuration: const Duration(milliseconds: 120),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: isActive
                                ? Row(
                                    key: const ValueKey('label'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 8),
                                      Text(
                                        item.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  const _NavItem({this.icon, this.svgAsset, required this.label})
    : assert(icon != null || svgAsset != null);
}
