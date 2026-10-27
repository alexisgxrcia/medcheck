import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/models/intake.dart';
import 'package:pill_reminder_app/models/medication.dart';

class MedicationActionSheet extends StatefulWidget {
  final Medication medication;
  final Intake? intake;
  final DateTime selectedDate;
  final DateTime scheduledTime;
  final Future<void> Function(DateTime takenAt) onComplete;
  final Future<void> Function() onSkip;
  final Future<void> Function() onUndo;

  const MedicationActionSheet({
    super.key,
    required this.medication,
    required this.intake,
    required this.selectedDate,
    required this.scheduledTime,
    required this.onComplete,
    required this.onSkip,
    required this.onUndo,
  });

  @override
  State<MedicationActionSheet> createState() => _MedicationActionSheetState();
}

enum _SheetView { actions, timePicker, success }

class _MedicationActionSheetState extends State<MedicationActionSheet> {
  _SheetView _view = _SheetView.actions;
  late DateTime _pickedTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.intake?.takenAt != null) {
      _pickedTime = widget.intake!.takenAt!;
    } else {
      _pickedTime = DateTime.now();
    }
  }

  IntakeStatus? get _status => widget.intake?.status;

  String get _timeLabel => DateFormat.Hm('es').format(_pickedTime);

  Future<void> _doAction(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    await action();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _doComplete(DateTime takenAt) async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onComplete(takenAt);
    if (mounted) {
      setState(() {
        _saving = false;
        _view = _SheetView.success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildHeader(tt),
                const SizedBox(height: 24),
                if (_view == _SheetView.actions) _buildActionsView(tt),
                if (_view == _SheetView.timePicker) _buildTimePickerView(tt),
                if (_view == _SheetView.success) _buildSuccessView(tt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/medicine.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.medication.name,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.medication.dosage != null)
                  Text(widget.medication.dosage!, style: tt.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsView(TextTheme tt) {
    if (_status == IntakeStatus.skipped) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: 'Deshacer',
            icon: CupertinoIcons.arrow_uturn_left,
            color: AppColors.primary,
            outlined: false,
            enabled: !_saving,
            onTap: () => _doAction(widget.onUndo),
          ),
        ),
      );
    }

    if (_status == IntakeStatus.taken) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Cambiar hora',
                icon: CupertinoIcons.clock,
                color: AppColors.primary,
                outlined: true,
                enabled: !_saving,
                onTap: () => setState(() => _view = _SheetView.timePicker),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Deshacer',
                icon: CupertinoIcons.arrow_uturn_left,
                color: const Color(0xFFE53935),
                outlined: true,
                enabled: !_saving,
                onTap: () => _doAction(widget.onUndo),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Saltar',
              icon: CupertinoIcons.minus_circle,
              color: AppColors.adaptiveTextSecondary(context),
              outlined: true,
              enabled: !_saving,
              onTap: () => _doAction(widget.onSkip),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'Completar',
              icon: CupertinoIcons.checkmark_circle,
              color: AppColors.taken,
              outlined: false,
              enabled: !_saving,
              onTap: () => setState(() => _view = _SheetView.timePicker),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerView(TextTheme tt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _status == IntakeStatus.taken
                  ? 'Nueva hora de toma'
                  : '¿A qué hora lo tomaste?',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            initialDateTime: _pickedTime,
            onDateTimeChanged: (dt) => setState(() => _pickedTime = dt),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: CupertinoButton(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.taken,
              onPressed: _saving
                  ? null
                  : () {
                      final takenAt = DateTime(
                        widget.selectedDate.year,
                        widget.selectedDate.month,
                        widget.selectedDate.day,
                        _pickedTime.hour,
                        _pickedTime.minute,
                      );
                      if (_status == IntakeStatus.taken) {
                        _doAction(() => widget.onComplete(takenAt));
                      } else {
                        _doComplete(takenAt);
                      }
                    },
              child: _saving
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      _status == IntakeStatus.taken
                          ? 'Guardar a las $_timeLabel'
                          : 'Completar a las $_timeLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          onPressed: () => setState(() => _view = _SheetView.actions),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSuccessView(TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lotties/check.json',
            width: 160,
            height: 160,
            repeat: false,
          ),
          const SizedBox(height: 4),
          Text(
            '¡Completado!',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.medication.name} registrada.\n¡Bien hecho, sigue así!',
            style: tt.bodyLarge?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CupertinoButton(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.taken,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Listo',
                style: tt.labelLarge?.copyWith(
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.outlined,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: outlined ? AppColors.adaptiveTileBackground(context) : color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: outlined ? color.withValues(alpha: 0.4) : color,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: outlined ? color : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: outlined ? color : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
