import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/config/colors.dart';
import 'package:pill_reminder_app/providers/patient_medication_provider.dart';
import 'package:pill_reminder_app/providers/sync_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfReportViewer extends ConsumerStatefulWidget {
  final int? linkId;
  final String patientName;
  final bool isOwnReport;

  const PdfReportViewer({
    super.key,
    this.linkId,
    required this.patientName,
    this.isOwnReport = false,
  });

  @override
  ConsumerState<PdfReportViewer> createState() => _PdfReportViewerState();
}

class _PdfReportViewerState extends ConsumerState<PdfReportViewer> {
  String? _filePath;
  String? _error;
  bool _isLoading = true;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadReport();
  }

  Future<void> _downloadReport() async {
    try {
      final syncService = ref.read(syncServiceProvider);
      final path = widget.isOwnReport
          ? await syncService.downloadOwnPatientReport(
              patientName: widget.patientName,
            )
          : await () async {
              final link = await ref.read(
                patientLinkProvider(widget.linkId!).future,
              );
              return syncService.downloadPatientReport(
                linkRemoteId: link.remoteId!,
                patientName: widget.patientName,
              );
            }();
      setState(() {
        _filePath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_filePath == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_filePath!)],
        text: 'Informe de ${widget.patientName}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.adaptiveBackground(context),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(
            CupertinoIcons.chevron_left,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        middle: Text(
          'Informe PDF',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        trailing: _filePath != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _sharePdf,
                child: Icon(CupertinoIcons.share, color: AppColors.primary),
              )
            : null,
      ),
      child: SafeArea(bottom: false, child: _buildBody(tt)),
    );
  }

  Widget _buildBody(TextTheme tt) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 16,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Descargando informe...',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: const Color(0xFFE62727),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el informe',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.adaptiveTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _downloadReport();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Reintentar',
                    style: tt.titleSmall?.copyWith(
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

    return Column(
      children: [
        Expanded(
          child: PDF(
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? 0;
              });
            },
          ).fromPath(_filePath!),
        ),
        if (_totalPages > 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.adaptiveTileBackground(context),
              border: Border(
                top: BorderSide(color: AppColors.adaptiveTileBorder(context)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Página ${_currentPage + 1} de $_totalPages',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
