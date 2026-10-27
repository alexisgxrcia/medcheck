import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class SelectOption<T> {
  final T value;
  final String label;

  const SelectOption({required this.value, required this.label});
}

class AppSelectSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectOption<T>> options;
  final T selected;

  const AppSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.adaptiveTileBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.adaptiveTileBorder(context),
              ),
              itemBuilder: (_, i) {
                final option = options[i];
                final isSelected = option.value == selected;
                return _SelectOptionTile<T>(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(option.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectOptionTile<T> extends StatelessWidget {
  final SelectOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: tt.bodyLarge?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.adaptiveTextPrimary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AppSelectSheet<T>(title: title, options: options, selected: selected),
  );
}
