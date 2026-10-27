import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';
import 'package:pill_reminder_app/router/router.dart';
import 'package:pill_reminder_app/widgets/app_date_picker_sheet.dart';
import 'package:pill_reminder_app/widgets/app_measurement_picker_sheet.dart';
import 'package:pill_reminder_app/widgets/app_select_sheet.dart';

class OnboardingConfigScreen extends ConsumerStatefulWidget {
  const OnboardingConfigScreen({super.key});

  @override
  ConsumerState<OnboardingConfigScreen> createState() =>
      _OnboardingConfigScreenState();
}

class _OnboardingConfigScreenState
    extends ConsumerState<OnboardingConfigScreen> {
  int _step = 0;
  UserRole _role = UserRole.patient;
  DateTime? _birthDate;
  int? _weightKg;
  int? _heightCm;
  bool _saving = false;

  static const _totalSteps = 4;

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _skip() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(currentUserProvider.notifier)
          .updateUser(
            role: _role,
            birthDate: _birthDate,
            weightKg: _weightKg?.toDouble(),
            heightCm: _heightCm?.toDouble(),
          );
      await ref.read(isarServiceProvider).markOnboardingDone();
      if (mounted) context.goNamed(AppRoutes.onboardingNotificationsName);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(_totalSteps, (i) {
                      final isActive = i <= _step;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.adaptiveTileBorder(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    _buildStepContent(tt, context),
                    const Spacer(flex: 3),
                    _buildButtons(tt),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(TextTheme tt, BuildContext context) {
    switch (_step) {
      case 0:
        return _buildRoleStep(tt, context);
      case 1:
        return _buildBirthDateStep(tt, context);
      case 2:
        return _buildWeightStep(tt, context);
      case 3:
        return _buildHeightStep(tt, context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoleStep(TextTheme tt, BuildContext context) {
    return Column(
      children: [
        const Icon(
          CupertinoIcons.person_2_fill,
          color: AppColors.primary,
          size: 44,
        ),
        const SizedBox(height: 32),
        Text(
          '¿Cómo usarás la app?',
          style: tt.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Esto nos ayuda a personalizar tu experiencia.',
          style: tt.bodyLarge?.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _showRolePicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTileBackground(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adaptiveTileBorder(context)),
            ),
            child: Row(
              children: [
                Icon(
                  _role == UserRole.patient
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.person_2_fill,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _role == UserRole.patient ? 'Paciente' : 'Cuidador',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateStep(TextTheme tt, BuildContext context) {
    String _formatDate(DateTime? d) {
      if (d == null) return 'Sin especificar';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return Column(
      children: [
        const Icon(CupertinoIcons.calendar, color: AppColors.primary, size: 44),
        const SizedBox(height: 32),
        Text(
          '¿Cuándo naciste?',
          style: tt.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Opcional. Esto nos ayuda a personalizar tu experiencia.',
          style: tt.bodyLarge?.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _showBirthDatePicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTileBackground(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adaptiveTileBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(_birthDate),
                  style: tt.headlineMedium?.copyWith(
                    color: _birthDate != null
                        ? AppColors.primary
                        : AppColors.adaptiveTextSecondary(context),
                    fontWeight: _birthDate != null ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: _birthDate != null
                      ? AppColors.primary
                      : AppColors.adaptiveTextSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightStep(TextTheme tt, BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary,
          size: 44,
        ),
        const SizedBox(height: 32),
        Text(
          '¿Cuánto pesas?',
          style: tt.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Opcional. Esto nos ayuda a darte mejor información.',
          style: tt.bodyLarge?.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _showWeightPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTileBackground(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adaptiveTileBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weightKg != null ? '$_weightKg kg' : 'Sin especificar',
                  style: tt.headlineMedium?.copyWith(
                    color: _weightKg != null
                        ? AppColors.primary
                        : AppColors.adaptiveTextSecondary(context),
                    fontWeight: _weightKg != null ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: _weightKg != null
                      ? AppColors.primary
                      : AppColors.adaptiveTextSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeightStep(TextTheme tt, BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.height_rounded, color: AppColors.primary, size: 44),
        const SizedBox(height: 32),
        Text(
          '¿Cuánto mides?',
          style: tt.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Opcional. Esto nos ayuda a darte mejor información.',
          style: tt.bodyLarge?.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _showHeightPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTileBackground(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adaptiveTileBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _heightCm != null ? '$_heightCm cm' : 'Sin especificar',
                  style: tt.headlineMedium?.copyWith(
                    color: _heightCm != null
                        ? AppColors.primary
                        : AppColors.adaptiveTextSecondary(context),
                    fontWeight: _heightCm != null ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: _heightCm != null
                      ? AppColors.primary
                      : AppColors.adaptiveTextSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(TextTheme tt) {
    final isLastStep = _step == _totalSteps - 1;
    final canSkip = _step > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          color: _saving ? AppColors.secondary : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: _saving ? null : _next,
          child: _saving
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  isLastStep ? 'Continuar' : 'Siguiente',
                  style: tt.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (canSkip) ...[
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _saving ? null : _skip,
            child: Text(
              'Omitir',
              style: tt.labelLarge?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showRolePicker(BuildContext context) async {
    final picked = await showSelectSheet<UserRole>(
      context: context,
      title: 'Selecciona tu rol',
      options: const [
        SelectOption(value: UserRole.patient, label: 'Paciente'),
        SelectOption(value: UserRole.caregiver, label: 'Cuidador'),
      ],
      selected: _role,
    );
    if (picked != null) setState(() => _role = picked);
  }

  void _showWeightPicker(BuildContext context) async {
    final result = await showMeasurementPickerSheet(
      context: context,
      title: 'Peso',
      unit: 'kg',
      initialValue: _weightKg ?? 70,
      min: 20,
      max: 300,
    );
    if (result != null) setState(() => _weightKg = result);
  }

  void _showHeightPicker(BuildContext context) async {
    final result = await showMeasurementPickerSheet(
      context: context,
      title: 'Altura',
      unit: 'cm',
      initialValue: _heightCm ?? 170,
      min: 50,
      max: 250,
    );
    if (result != null) setState(() => _heightCm = result);
  }

  void _showBirthDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDatePickerSheet(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, 1, 1),
      maxDate: now,
      minDate: DateTime(1920, 1, 1),
    );
    if (result != null) setState(() => _birthDate = result);
  }
}
