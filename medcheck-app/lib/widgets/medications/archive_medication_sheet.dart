import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class ArchiveMedicationSheet extends StatefulWidget {
  final String medicationName;
  final Future<void> Function() onConfirm;

  const ArchiveMedicationSheet({
    super.key,
    required this.medicationName,
    required this.onConfirm,
  });

  @override
  State<ArchiveMedicationSheet> createState() => _ArchiveMedicationSheetState();
}

class _ArchiveMedicationSheetState extends State<ArchiveMedicationSheet> {
  bool _archiving = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¿Archivar medicamento?',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '"${widget.medicationName}" se moverá a la lista de archivados. Podrás recuperarlo después.',
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _archiving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.adaptiveTileBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.adaptiveTileBorder(context),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _archiving
                          ? null
                          : () async {
                              setState(() => _archiving = true);
                              await widget.onConfirm();
                              if (mounted) Navigator.of(context).pop(true);
                            },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: _archiving
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Archivar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
