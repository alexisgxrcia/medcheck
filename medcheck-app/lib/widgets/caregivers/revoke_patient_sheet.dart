import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class RevokePatientSheet extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const RevokePatientSheet({super.key, required this.onConfirm});

  @override
  State<RevokePatientSheet> createState() => _RevokePatientSheetState();
}

class _RevokePatientSheetState extends State<RevokePatientSheet> {
  bool _deleting = false;

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
                  color: AppColors.adaptiveTileBorder(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¿Desvincular paciente?',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Se revocará el vínculo con este paciente. Ya no podrás ver sus medicamentos ni recibirás notificaciones.',
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
                      onTap: _deleting
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
                      onTap: _deleting
                          ? null
                          : () async {
                              setState(() => _deleting = true);
                              try {
                                await widget.onConfirm();
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                setState(() => _deleting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: const Color(0xFFE62727),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE62727),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: _deleting
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Desvincular',
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
