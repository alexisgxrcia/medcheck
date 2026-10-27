import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pill_reminder_app/config/colors.dart';

class SignOutSheet extends StatefulWidget {
  final bool hasConnection;
  final bool hasPendingChanges;
  final int pendingChangeCount;
  final Future<void> Function() onConfirm;

  const SignOutSheet({
    super.key,
    required this.hasConnection,
    required this.hasPendingChanges,
    required this.pendingChangeCount,
    required this.onConfirm,
  });

  @override
  State<SignOutSheet> createState() => _SignOutSheetState();
}

class _SignOutSheetState extends State<SignOutSheet> {
  bool _isSubmitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final canConfirm = !_isSubmitting;
    final title = _titleText();
    final message = _messageText();
    final icon = _leadingIcon();
    final iconColor = _iconColor();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
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
              const SizedBox(height: 20),
              Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE62727).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE62727).withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: tt.bodySmall?.copyWith(
                      color: const Color(0xFFE62727),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmitting
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
                          style: tt.titleSmall?.copyWith(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: canConfirm ? _onConfirm : null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: canConfirm ? 1 : 0.6,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Cerrar sesión',
                                  style: tt.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
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

  Future<void> _onConfirm() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _titleText() {
    if (!widget.hasConnection && widget.hasPendingChanges) {
      return 'Cerrar sesión con cambios pendientes';
    }
    if (!widget.hasConnection) {
      return 'Cerrar sesión sin internet';
    }
    if (widget.hasPendingChanges) {
      return '¿Cerrar sesión?';
    }
    return '¿Cerrar sesión?';
  }

  String _messageText() {
    if (!widget.hasConnection && widget.hasPendingChanges) {
      return 'Tienes ${_pendingLabel()} sin sincronizar y no hay internet. Si sales ahora, esos cambios se perderán de este dispositivo.';
    }
    if (!widget.hasConnection) {
      return 'No hay internet, pero puedes cerrar sesión de todos modos.';
    }
    if (widget.hasPendingChanges) {
      return 'Intentaremos sincronizar ${_pendingLabel()} antes de salir. Si no se puede, cerraremos sesión de todos modos y esos cambios se perderán de este dispositivo.';
    }
    return 'Cerraremos tu sesión en este dispositivo.';
  }

  IconData _leadingIcon() {
    if (!widget.hasConnection || widget.hasPendingChanges) {
      return CupertinoIcons.exclamationmark_triangle;
    }
    return CupertinoIcons.square_arrow_left;
  }

  Color _iconColor() {
    if (!widget.hasConnection || widget.hasPendingChanges) {
      return const Color(0xFFE62727);
    }
    return AppColors.primary;
  }

  String _pendingLabel() {
    final count = widget.pendingChangeCount;
    if (count == 1) return '1 cambio';
    return '$count cambios';
  }
}
