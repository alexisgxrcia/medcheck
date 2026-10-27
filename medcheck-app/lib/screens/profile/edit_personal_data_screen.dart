import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/widgets/app_date_picker_sheet.dart';
import 'package:pill_reminder_app/widgets/app_measurement_picker_sheet.dart';
import 'package:pill_reminder_app/widgets/app_select_sheet.dart';

class EditPersonalDataScreen extends ConsumerStatefulWidget {
  const EditPersonalDataScreen({super.key});

  @override
  ConsumerState<EditPersonalDataScreen> createState() =>
      _EditPersonalDataScreenState();
}

class _EditPersonalDataScreenState
    extends ConsumerState<EditPersonalDataScreen> {
  final _scrollController = ScrollController();
  double _gradientOpacity = 0.0;

  static const _rowTopPadding = 16.0;
  static const _rowHeight = 48.0;
  static const _fadeTailHeight = 40.0;
  static const _solidContentHeight = _rowTopPadding + _rowHeight;
  static const _fadeInDistance = 80.0;

  String _displayName = '';
  UserRole _role = UserRole.patient;
  DateTime? _birthDate;
  int? _weightKg;
  int? _heightCm;
  bool _saving = false;

  static const _roleOptions = [
    SelectOption(value: UserRole.patient, label: 'Paciente'),
    SelectOption(value: UserRole.caregiver, label: 'Cuidador'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final user = ref.read(currentUserProvider).asData?.value;
    _displayName = user?.displayName ?? '';
    _role = user?.role ?? UserRole.patient;
    _birthDate = user?.birthDate;
    _weightKg = user?.weightKg?.round();
    _heightCm = user?.heightCm?.round();
  }

  void _onScroll() {
    final opacity = (_scrollController.offset / _fadeInDistance).clamp(
      0.0,
      1.0,
    );
    if (opacity != _gradientOpacity) {
      setState(() => _gradientOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'No especificado';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(currentUserProvider.notifier)
          .updateUser(
            displayName: _displayName.trim().isEmpty
                ? null
                : _displayName.trim(),
            role: _role,
            birthDate: _birthDate,
            weightKg: _weightKg?.toDouble(),
            heightCm: _heightCm?.toDouble(),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showNameSheet() {
    final ctr = TextEditingController(text: _displayName);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNameSheet(
        controller: ctr,
        onSave: () {
          setState(() => _displayName = ctr.text.trim());
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bg = AppColors.adaptiveBackground(context);
    final topInset = MediaQuery.of(context).padding.top;
    final overlayTotalHeight = topInset + _solidContentHeight + _fadeTailHeight;
    final solidStop = (topInset + _solidContentHeight) / overlayTotalHeight;

    return Material(
      color: bg,
      child: CupertinoPageScaffold(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  _solidContentHeight + _fadeTailHeight,
                  20,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                children: [
                  _buildField(
                    context,
                    tt,
                    label: 'Nombre',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showNameSheet,
                      child: Text(
                        _displayName.trim().isEmpty
                            ? 'Tu nombre'
                            : _displayName.trim(),
                        style: tt.bodyMedium?.copyWith(
                          color: _displayName.trim().isEmpty
                              ? AppColors.adaptiveTextSecondary(context)
                              : AppColors.adaptiveTextPrimary(context),
                          fontWeight: _displayName.trim().isEmpty
                              ? null
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    tt,
                    label: 'Rol',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final picked = await showSelectSheet<UserRole>(
                          context: context,
                          title: 'Rol',
                          options: _roleOptions,
                          selected: _role,
                        );
                        if (picked != null) setState(() => _role = picked);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _role == UserRole.patient ? 'Paciente' : 'Cuidador',
                            style: tt.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    tt,
                    label: 'Fecha de nacimiento',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final now = DateTime.now();
                        final result = await showDatePickerSheet(
                          context: context,
                          initialDate:
                              _birthDate ?? DateTime(now.year - 30, 1, 1),
                          maxDate: now,
                          minDate: DateTime(1920, 1, 1),
                        );
                        if (result != null) {
                          setState(() => _birthDate = result);
                        }
                      },
                      child: Text(
                        _formatDate(_birthDate),
                        style: tt.bodyMedium?.copyWith(
                          color: _birthDate != null
                              ? AppColors.primary
                              : AppColors.adaptiveTextSecondary(context),
                          fontWeight: _birthDate != null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    tt,
                    label: 'Peso',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await showMeasurementPickerSheet(
                          context: context,
                          title: 'Peso',
                          unit: 'kg',
                          initialValue: _weightKg ?? 70,
                          min: 20,
                          max: 300,
                        );
                        if (result != null) {
                          setState(() => _weightKg = result);
                        }
                      },
                      child: Text(
                        _weightKg != null ? '$_weightKg kg' : 'No especificado',
                        style: tt.bodyMedium?.copyWith(
                          color: _weightKg != null
                              ? AppColors.primary
                              : AppColors.adaptiveTextSecondary(context),
                          fontWeight: _weightKg != null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    context,
                    tt,
                    label: 'Altura',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await showMeasurementPickerSheet(
                          context: context,
                          title: 'Altura',
                          unit: 'cm',
                          initialValue: _heightCm ?? 170,
                          min: 50,
                          max: 250,
                        );
                        if (result != null) {
                          setState(() => _heightCm = result);
                        }
                      },
                      child: Text(
                        _heightCm != null ? '$_heightCm cm' : 'No especificado',
                        style: tt.bodyMedium?.copyWith(
                          color: _heightCm != null
                              ? AppColors.primary
                              : AppColors.adaptiveTextSecondary(context),
                          fontWeight: _heightCm != null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: overlayTotalHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _gradientOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bg, bg, bg.withValues(alpha: 0)],
                        stops: [0.0, solidStop, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topInset + _rowTopPadding,
              left: 20,
              right: 20,
              height: _rowHeight,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      color: AppColors.adaptiveTextPrimary(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Datos personales', style: tt.displaySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    TextTheme tt, {
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveTileBorder(context)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _EditNameSheet extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _EditNameSheet({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            '¿Cómo te llamas?',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          CupertinoTextField(
            controller: controller,
            placeholder: 'Tu nombre',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.adaptiveBackground(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.adaptiveTileBorder(context)),
            ),
            style: tt.bodyLarge,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              onPressed: onSave,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
