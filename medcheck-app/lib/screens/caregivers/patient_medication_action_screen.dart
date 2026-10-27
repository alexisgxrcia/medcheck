import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/patient_medication.dart';
import 'package:pill_reminder_app/providers/patient_medication_provider.dart';
import 'package:pill_reminder_app/widgets/app_time_picker_sheet.dart';
import 'package:pill_reminder_app/widgets/friendly_error_state.dart';

class PatientMedicationActionScreen extends ConsumerStatefulWidget {
  final int linkId;
  final String? medicationId;

  const PatientMedicationActionScreen({
    super.key,
    required this.linkId,
    this.medicationId,
  });

  @override
  ConsumerState<PatientMedicationActionScreen> createState() =>
      _PatientMedicationActionScreenState();
}

class _PatientMedicationActionScreenState
    extends ConsumerState<PatientMedicationActionScreen> {
  bool _initialized = false;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '8');
  final _scrollController = ScrollController();

  FrequencyType _frequencyType = FrequencyType.daily;
  TimeOfDay _timeOfDay = TimeOfDay.now();
  List<int> _selectedDays = [0, 1, 2, 3, 4, 5, 6];
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _endDate;
  double _gradientOpacity = 0.0;

  bool get _isEditing => widget.medicationId != null;
  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final opacity = (_scrollController.offset / 60).clamp(0.0, 1.0);
    if (opacity != _gradientOpacity) {
      setState(() => _gradientOpacity = opacity);
    }
  }

  void _initFromMedication(PatientMedication med) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = med.name;
    _dosageController.text = med.dosage ?? '';
    _notesController.text = med.notes ?? '';
    _startDate = med.startDate ?? _startDate;
    _endDate = med.endDate;

    if (med.schedules.isNotEmpty) {
      final schedule = med.schedules.first;
      _frequencyType = schedule.frequencyType;
      if (schedule.timeOfDay != null) {
        final parts = schedule.timeOfDay!.split(':');
        if (parts.length == 2) {
          _timeOfDay = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      _selectedDays = schedule.daysOfWeek.isEmpty
          ? [0, 1, 2, 3, 4, 5, 6]
          : List<int>.from(schedule.daysOfWeek);
      _intervalController.text =
          (schedule.intervalHours ?? schedule.intervalDays ?? 8).toString();
    }
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    setState(() => _saving = true);

    final payload = PatientSchedulePayload(
      frequencyType: _frequencyType,
      timeOfDay: _frequencyType == FrequencyType.prn ? null : _timeString,
      daysOfWeek: _frequencyType == FrequencyType.weekly ? _selectedDays : [],
      intervalHours: _frequencyType == FrequencyType.interval
          ? int.tryParse(_intervalController.text)
          : null,
      intervalDays: _frequencyType == FrequencyType.everyXDays
          ? int.tryParse(_intervalController.text)
          : null,
    );

    try {
      final notifier = ref.read(
        patientMedicationsProvider(widget.linkId).notifier,
      );
      if (_isEditing) {
        await notifier.updateMedication(
          medicationId: widget.medicationId!,
          name: _nameController.text.trim(),
          dosage: _emptyToNull(_dosageController.text),
          notes: _emptyToNull(_notesController.text),
          startDate: _startDate,
          endDate: _endDate,
          schedule: payload,
        );
      } else {
        await notifier.createMedication(
          name: _nameController.text.trim(),
          dosage: _emptyToNull(_dosageController.text),
          notes: _emptyToNull(_notesController.text),
          startDate: _startDate,
          endDate: _endDate,
          schedule: payload,
        );
      }

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) _showError(friendlyErrorCopy(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _timeString =>
      '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}';

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final medicationsAsync = ref.watch(
      patientMedicationsProvider(widget.linkId),
    );

    if (_isEditing) {
      return medicationsAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => _loadingScaffold(),
        error: (e, _) => _errorScaffold(e),
        data: (medications) {
          final med = medications
              .where((m) => m.id == widget.medicationId)
              .firstOrNull;
          if (med == null) {
            return CupertinoPageScaffold(
              backgroundColor: AppColors.adaptiveBackground(context),
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => context.pop(),
                              child: Icon(
                                CupertinoIcons.chevron_left,
                                color: AppColors.adaptiveTextPrimary(context),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Editar medicamento',
                                style: tt.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Medicamento no encontrado',
                            style: tt.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          _initFromMedication(med);
          return _buildForm(tt);
        },
      );
    }

    return _buildForm(tt);
  }

  Widget _loadingScaffold() {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: const SafeArea(child: Center(child: CupertinoActivityIndicator())),
    );
  }

  Widget _errorScaffold(Object error) {
    final copy = friendlyErrorCopy(error);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      child: SafeArea(
        child: FriendlyErrorState(
          title: copy.title,
          message: copy.message,
          onRetry: () =>
              ref.invalidate(patientMedicationsProvider(widget.linkId)),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme tt) {
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
                      onPressed: () => context.pop(),
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        color: AppColors.adaptiveTextPrimary(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Editar medicamento'
                            : 'Agregar medicamento',
                        style: tt.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildSectionHeader('Información', tt),
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
                        const SizedBox(height: 32),
                        _buildSectionHeader('Horario', tt),
                        Text('Frecuencia', style: tt.titleSmall),
                        const SizedBox(height: 12),
                        _buildFrequencyChips(tt),
                        const SizedBox(height: 24),
                        if (_frequencyType != FrequencyType.prn) ...[
                          Text('Hora de toma', style: tt.titleSmall),
                          const SizedBox(height: 8),
                          _buildTimePicker(tt),
                          const SizedBox(height: 24),
                        ],
                        if (_frequencyType == FrequencyType.weekly) ...[
                          Text('Días de la semana', style: tt.titleSmall),
                          const SizedBox(height: 12),
                          _buildDaySelector(tt),
                          const SizedBox(height: 24),
                        ],
                        if (_frequencyType == FrequencyType.interval) ...[
                          Text('Intervalo (horas)', style: tt.titleSmall),
                          const SizedBox(height: 8),
                          _buildIntervalField(tt, 'Ej. 8'),
                          const SizedBox(height: 24),
                        ],
                        if (_frequencyType == FrequencyType.everyXDays) ...[
                          Text('Cada cuántos días', style: tt.titleSmall),
                          const SizedBox(height: 8),
                          _buildIntervalField(tt, 'Ej. 3'),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionHeader('Duración', tt),
                        Text('Fecha de inicio', style: tt.titleSmall),
                        const SizedBox(height: 8),
                        _buildStartDatePicker(tt),
                        const SizedBox(height: 24),
                        Text('Fecha de fin (opcional)', style: tt.titleSmall),
                        const SizedBox(height: 8),
                        _buildEndDatePicker(tt),
                        const SizedBox(height: 32),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 32,
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
                    color: _canSave ? AppColors.primary : AppColors.secondary,
                    onPressed: _canSave ? _save : null,
                    child: _saving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            _isEditing
                                ? 'Guardar cambios'
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

  Widget _buildSectionHeader(String title, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tt.headlineSmall),
          const SizedBox(height: 8),
          Divider(
            color: AppColors.adaptiveTextSecondary(
              context,
            ).withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChips(TextTheme tt) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FrequencyType.values.map((ft) {
        final selected = ft == _frequencyType;
        return GestureDetector(
          onTap: () => setState(() => _frequencyType = ft),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Widget _buildTimePicker(TextTheme tt) {
    return GestureDetector(
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
    );
  }

  Widget _buildDaySelector(TextTheme tt) {
    const labels = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final selected = _selectedDays.contains(i);
        return GestureDetector(
          onTap: () {
            setState(() {
              selected ? _selectedDays.remove(i) : _selectedDays.add(i);
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

  Widget _buildIntervalField(TextTheme tt, String placeholder) {
    return CupertinoTextField(
      controller: _intervalController,
      placeholder: placeholder,
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
    );
  }

  Widget _buildStartDatePicker(TextTheme tt) {
    return GestureDetector(
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
    );
  }

  Widget _buildEndDatePicker(TextTheme tt) {
    return GestureDetector(
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
                    ? DateFormat("d 'de' MMMM, yyyy", 'es').format(_endDate!)
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

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text(
                      'Seleccionar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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
