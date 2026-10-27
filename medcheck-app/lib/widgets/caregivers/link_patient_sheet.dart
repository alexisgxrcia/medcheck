import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkPatientSheet extends StatefulWidget {
  final String? userEmail;
  final Future<void> Function({required String email}) onLink;

  const LinkPatientSheet({super.key, this.userEmail, required this.onLink});

  @override
  State<LinkPatientSheet> createState() => _LinkPatientSheetState();
}

class _LinkPatientSheetState extends State<LinkPatientSheet> {
  final _emailCtr = TextEditingController();
  bool _saving = false;
  bool _showQr = false;
  bool _showScanner = false;
  String? _error;

  bool get _emailValid {
    final email = _emailCtr.text.trim();
    if (email.isEmpty) return false;
    final parts = email.split('@');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].contains('.');
  }

  @override
  void initState() {
    super.initState();
    _emailCtr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtr.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onLink(email: email);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_showScanner) {
      return _buildScanner(context, tt);
    }

    if (_showQr) {
      return _buildQrSection(context, tt);
    }

    return _buildForm(context, tt);
  }

  Widget _buildForm(BuildContext context, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
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
              'Vincular paciente',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el correo del paciente para enviarle una invitación, o comparte tu código QR.',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtr,
              keyboardType: TextInputType.emailAddress,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Correo electrónico *',
                labelStyle: tt.bodySmall?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                filled: true,
                fillColor: AppColors.adaptiveBackground(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.adaptiveTileBorder(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.adaptiveTileBorder(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: Icon(
                  CupertinoIcons.mail,
                  size: 20,
                  color: AppColors.adaptiveTextSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showQr = true),
                icon: const Icon(CupertinoIcons.qrcode, size: 18),
                label: const Text('Compartir código QR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(CupertinoIcons.viewfinder, size: 18),
                label: const Text('Escanear código QR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE62727).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE62727).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: tt.bodySmall?.copyWith(
                    color: const Color(0xFFE62727),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: _emailValid ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
                onPressed: (_emailValid && !_saving) ? _submit : null,
                child: _saving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Enviar invitación',
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
    );
  }

  Widget _buildQrSection(BuildContext context, TextTheme tt) {
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
            'Tu código QR',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Comparte este código con el paciente para que pueda vincularte.',
            style: tt.bodyMedium?.copyWith(
              color: AppColors.adaptiveTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data:
                  'pillreminder://link/caregiver/${widget.userEmail ?? 'unknown'}',
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              onPressed: () => setState(() => _showQr = false),
              child: const Text(
                'Cerrar',
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

  Widget _buildScanner(BuildContext context, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adaptiveTileBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showScanner = false),
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        color: AppColors.adaptiveTextPrimary(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Escanear QR',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode != null && barcode.rawValue != null) {
                  final raw = barcode.rawValue!;
                  final prefix = 'pillreminder://link/patient/';
                  if (raw.startsWith(prefix)) {
                    final email = raw.substring(prefix.length);
                    if (email.isNotEmpty && email.contains('@')) {
                      setState(() {
                        _emailCtr.text = email;
                        _showScanner = false;
                      });
                      Future.microtask(() => _submit());
                      return;
                    }
                  }
                  setState(() => _showScanner = false);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Text(
              'Apunta la cámara al código QR del paciente',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
