import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class CancelPatientRequestSheet extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const CancelPatientRequestSheet({super.key, required this.onConfirm});

  @override
  State<CancelPatientRequestSheet> createState() =>
      _CancelPatientRequestSheetState();
}

class _CancelPatientRequestSheetState extends State<CancelPatientRequestSheet> {
  bool _loading = false;

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
                '¿Cancelar vinculación?',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Se cancelará la solicitud enviada a este paciente.',
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
                      onTap: _loading ? null : () => Navigator.of(context).pop(),
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
                          'Volver',
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
                      onTap: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              try {
                                await widget.onConfirm();
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                setState(() => _loading = false);
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
                        child: _loading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Cancelar solicitud',
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
