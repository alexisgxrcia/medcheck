import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/widgets/app_time_picker_sheet.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/schedule.dart';
import 'package:pill_reminder_app/providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  final _sc0 = ScrollController();
  final _sc1 = ScrollController();
  final _sc2 = ScrollController();
  double _gradientOpacity = 0.0;
  static const _gradientHeight = 32.0;
  static const _fadeInDistance = 60.0;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '8');

  FrequencyType _frequencyType = FrequencyType.daily;
  TimeOfDay _timeOfDay = TimeOfDay.now();
  List<int> _selectedDays = [0, 1, 2, 3, 4, 5, 6];
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sc0.addListener(_onScroll);
    _sc1.addListener(_onScroll);
    _sc2.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = switch (_currentStep) {
      0 => _sc0,
      1 => _sc1,
      _ => _sc2,
    };
    final opacity = (controller.offset / _fadeInDistance).clamp(0.0, 1.0);
    if (opacity != _gradientOpacity) {
      setState(() => _gradientOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sc0.removeListener(_onScroll);
    _sc1.removeListener(_onScroll);
    _sc2.removeListener(_onScroll);
    _sc0.dispose();
    _sc1.dispose();
    _sc2.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    return switch (_currentStep) {
      0 => _nameController.text.trim().isNotEmpty,
      1 => true,
      2 => true,
      _ => false,
    };
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _gradientOpacity = 0.0;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _gradientOpacity = 0.0;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final schedule = Schedule()
        ..frequencyType = _frequencyType
        ..timeOfDay =
            '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}'
        ..daysOfWeek = _frequencyType == FrequencyType.weekly
            ? ([..._selectedDays]..sort())
            : []
        ..intervalHours = _frequencyType == FrequencyType.interval
            ? int.tryParse(_intervalController.text)
            : null
        ..intervalDays = _frequencyType == FrequencyType.everyXDays
            ? int.tryParse(_intervalController.text)
            : null;

      await ref
          .read(medicationsProvider.notifier)
          .addMedication(
            name: _nameController.text.trim(),
            dosage: _dosageController.text.trim().isEmpty
                ? null
                : _dosageController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            schedule: schedule,
          );

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('No se pudo guardar: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _back,
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        color: AppColors.adaptiveTextPrimary(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _stepTitle,
                        style: tt.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.secondary.withValues(
                      alpha: 0.25,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Paso ${_currentStep + 1} de $_totalSteps',
                    style: tt.labelSmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildInfoStep(context, tt),
                        _buildScheduleStep(context, tt),
                        _buildDatesStep(context, tt),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _gradientHeight,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: _gradientOpacity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.adaptiveBackground(context),
                                  AppColors.adaptiveBackground(
                                    context,
                                  ).withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CupertinoButton(
                    borderRadius: BorderRadius.circular(16),
                    color: _canAdvance
                        ? AppColors.primary
                        : AppColors.secondary,
                    onPressed: _canAdvance ? _next : null,
                    child: _saving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            _currentStep < _totalSteps - 1
                                ? 'Siguiente'
                                : 'Crear medicamento',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    return switch (_currentStep) {
      0 => 'Información',
      1 => 'Horario',
      2 => 'Duración',
      _ => '',
    };
  }

  Widget _buildInfoStep(BuildContext context, TextTheme tt) {
    return ListView(
      controller: _sc0,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Nombre del medicamento', style: tt.titleSmall),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Ej. Ibuprofeno',
          padding: const EdgeInsets.all(14),
          decoration: _fieldDecoration(context),
          style: tt.bodyLarge,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Text('Dosis (opcional)', style: tt.titleSmall),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _dosageController,
          placeholder: 'Ej. 400mg',
          padding: const EdgeInsets.all(14),
          decoration: _fieldDecoration(context),
          style: tt.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text('Notas (opcional)', style: tt.titleSmall),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _notesController,
          placeholder: 'Ej. Tomar con alimentos',
          padding: const EdgeInsets.all(14),
          decoration: _fieldDecoration(context),
          style: tt.bodyLarge,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScheduleStep(BuildContext context, TextTheme tt) {
    return ListView(
      controller: _sc1,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Frecuencia', style: tt.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FrequencyType.values.map((ft) {
            final selected = ft == _frequencyType;
            return GestureDetector(
              onTap: () => setState(() => _frequencyType = ft),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.adaptiveTileBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.adaptiveTileBorder(context),
                  ),
                ),
                child: Text(
                  ft.label,
                  style: tt.bodyMedium?.copyWith(
                    color: selected
                        ? Colors.white
                        : AppColors.adaptiveTextPrimary(context),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (_frequencyType != FrequencyType.prn) ...[
          Text('Hora de toma', style: tt.titleSmall),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _fieldDecoration(context),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(_formatTime(_timeOfDay), style: tt.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_frequencyType == FrequencyType.weekly) ...[
          Text('Días de la semana', style: tt.titleSmall),
          const SizedBox(height: 12),
          _buildDaySelector(context, tt),
          const SizedBox(height: 24),
        ],
        if (_frequencyType == FrequencyType.interval) ...[
          Text('Intervalo (horas)', style: tt.titleSmall),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _intervalController,
            placeholder: 'Ej. 8',
            padding: const EdgeInsets.all(14),
            decoration: _fieldDecoration(context),
            style: tt.bodyLarge,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
        ],
        if (_frequencyType == FrequencyType.everyXDays) ...[
          Text('Cada cuántos días', style: tt.titleSmall),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _intervalController,
            placeholder: 'Ej. 3',
            padding: const EdgeInsets.all(14),
            decoration: _fieldDecoration(context),
            style: tt.bodyLarge,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context, TextTheme tt) {
    const labels = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final selected = _selectedDays.contains(i);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                if (_selectedDays.length == 1) return;
                _selectedDays.remove(i);
              } else {
                _selectedDays.add(i);
                _selectedDays.sort();
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.adaptiveTileBackground(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.adaptiveTileBorder(context),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[i],
              style: tt.labelLarge?.copyWith(
                color: selected
                    ? Colors.white
                    : AppColors.adaptiveTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDatesStep(BuildContext context, TextTheme tt) {
    return ListView(
      controller: _sc2,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Fecha de inicio', style: tt.titleSmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(isStart: true),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _fieldDecoration(context),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat("d 'de' MMMM, yyyy", 'es').format(_startDate),
                  style: tt.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Fecha de fin (opcional)', style: tt.titleSmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(isStart: false),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _fieldDecoration(context),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: _endDate != null
                      ? AppColors.primary
                      : AppColors.adaptiveTextSecondary(
                          context,
                        ).withValues(alpha: 0.4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _endDate != null
                        ? DateFormat(
                            "d 'de' MMMM, yyyy",
                            'es',
                          ).format(_endDate!)
                        : 'Sin fecha de fin',
                    style: _endDate != null
                        ? tt.bodyLarge
                        : tt.bodyLarge?.copyWith(
                            color: AppColors.adaptiveTextSecondary(context),
                          ),
                  ),
                ),
                if (_endDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _endDate = null),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 18,
                      color: AppColors.adaptiveTextSecondary(
                        context,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _fieldDecoration(BuildContext context) => BoxDecoration(
    color: AppColors.adaptiveTileBackground(context),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.adaptiveTileBorder(context)),
  );

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePickerSheet(
      context: context,
      initialTime: _timeOfDay,
    );
    if (picked != null && mounted) {
      setState(() => _timeOfDay = picked);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? _startDate
        : (_endDate ?? _startDate.add(const Duration(days: 1)));
    final firstAllowed = isStart ? DateTime(2020) : _startDate;

    final picked = await showDialog<DateTime>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _DatePickerDialog(
        initialDate: initial.isBefore(firstAllowed) ? firstAllowed : initial,
        firstDate: firstAllowed,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

class _DatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  const _DatePickerDialog({required this.initialDate, this.firstDate});

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.adaptiveBackground(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surface: AppColors.adaptiveTileBackground(context),
                    onSurface: AppColors.adaptiveTextPrimary(context),
                  ),
                ),
                child: Localizations.override(
                  context: context,
                  locale: const Locale('es'),
                  child: CalendarDatePicker(
                    initialDate: _selected,
                    firstDate: widget.firstDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (d) => setState(() => _selected = d),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Seleccionar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selected),
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
