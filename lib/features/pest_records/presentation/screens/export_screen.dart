import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/qgis_helper.dart';
import '../../domain/models/pest_record.dart';
import '../providers/pest_records_provider.dart';
import 'add_edit_record_screen.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> with SingleTickerProviderStateMixin {
  ExportFormat _selectedFormat = ExportFormat.qgisPackage;
  bool _exportFilteredOnly = false;
  bool _isExporting = false;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleShare(List<PestRecord> records) async {
    if (records.isEmpty) {
      _showEmptySnackBar();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final result = await ExportService.instance.exportAndShare(
        records: records,
        format: _selectedFormat,
      );

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Pronto para compartilhar!'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Erro ao exportar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha na exportação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleSaveToDevice(List<PestRecord> records) async {
    if (records.isEmpty) {
      _showEmptySnackBar();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await ExportService.instance.saveToDevice(
        records: records,
        format: _selectedFormat,
      );

      if (mounted) {
        if (result.isSuccess) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Arquivo Salvo!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('O arquivo foi salvo na memória do dispositivo:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      result.filePath ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.filePath ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caminho copiado!')),
                    );
                  },
                  child: const Text('Copiar Caminho'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Erro ao salvar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _copyContentToClipboard(List<PestRecord> records) {
    if (records.isEmpty) {
      _showEmptySnackBar();
      return;
    }

    final content = ExportService.instance.getContentForFormat(records, _selectedFormat);
    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados copiados para a área de transferência!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showEmptySnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhum registro disponível para exportação.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecordsAsync = ref.watch(pestRecordsProvider);
    final allRecords = allRecordsAsync.value ?? [];
    final filteredRecords = ref.watch(filteredPestRecordsProvider);
    final filter = ref.watch(pestFilterProvider);

    final recordsToExport = _exportFilteredOnly ? filteredRecords : allRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar para QGIS & SIG'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.file_upload_outlined), text: 'Exportar'),
            Tab(icon: Icon(Icons.menu_book), text: 'Tutorial QGIS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(recordsToExport, allRecords.length, filteredRecords.length, filter.hasActiveFilters),
          _buildQgisTutorialTab(),
        ],
      ),
    );
  }

  Widget _buildExportTab(
    List<PestRecord> recordsToExport,
    int totalCount,
    int filteredCount,
    bool hasFilters,
  ) {
    if (recordsToExport.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.layers_clear_outlined, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nenhum Ponto para Exportar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre seus primeiros pontos de monitoramento no campo para poder gerar e exportar arquivos compatíveis com o QGIS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEditRecordScreen()),
                  );
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Cadastrar Ponto Agora'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pronto para exportar ${recordsToExport.length} pontos',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Arquivos com coordenadas GPS (WGS84), quantidades de pragas e compatibilidade total com o QGIS.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter Scope Toggle (if filters active)
        if (hasFilters) ...[
          SwitchListTile(
            title: const Text('Exportar apenas registros filtrados'),
            subtitle: Text('$filteredCount registros filtrados de um total de $totalCount'),
            value: _exportFilteredOnly,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _exportFilteredOnly = val),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
        ],

        // Format Selection
        const Text(
          'Selecione o Formato de Exportação:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 1. QGIS Package (GeoJSON + QML Style)
        _buildFormatTile(
          format: ExportFormat.qgisPackage,
          title: 'Pacote QGIS Completo (.geojson + .qml)',
          badge: 'RECOMENDADO',
          badgeColor: AppColors.primary,
          subtitle: 'Exporta os dados espaciais GeoJSON com estilo QML para carregar círculos graduados por quantidade.',
          icon: Icons.layers,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 10),

        // 2. Standard GeoJSON
        _buildFormatTile(
          format: ExportFormat.geoJson,
          title: 'GeoJSON (.geojson)',
          badge: 'PADRÃO OGC',
          badgeColor: Colors.blue.shade700,
          subtitle: 'Formato padrão para SIGs modernos. Arraste direto para o QGIS.',
          icon: Icons.public,
          iconColor: Colors.blue.shade700,
        ),
        const SizedBox(height: 10),

        // 3. CSV with WKT
        _buildFormatTile(
          format: ExportFormat.csv,
          title: 'Tabela CSV (.csv)',
          badge: 'PLANILHA / SIG',
          badgeColor: Colors.orange.shade800,
          subtitle: 'Compatível com Excel e QGIS com coluna de geometria WKT.',
          icon: Icons.table_view,
          iconColor: Colors.orange.shade800,
        ),
        const SizedBox(height: 10),

        // 4. KML
        _buildFormatTile(
          format: ExportFormat.kml,
          title: 'Google Earth / KML (.kml)',
          badge: '3D / EARTH',
          badgeColor: Colors.teal.shade700,
          subtitle: 'Abra no Google Earth ou QGIS com balões informativos estilizados por severidade.',
          icon: Icons.map_outlined,
          iconColor: Colors.teal.shade700,
        ),
        const SizedBox(height: 20),

        // Action Buttons
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : () => _handleShare(recordsToExport),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(
              _isExporting ? 'Compartilhando...' : 'Compartilhar Arquivo (WhatsApp / Drive / Email)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _handleSaveToDevice(recordsToExport),
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Salvar no Aparelho'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyContentToClipboard(recordsToExport),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar Dados'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormatTile({
    required ExportFormat format,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQgisTutorialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade900),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Como visualizar os pontos e a quantidade de insetos no QGIS:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Passo a Passo com Arquivo GeoJSON',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ...QgisHelper.geoJsonGuide.map((step) => _buildTutorialStepCard(step)),

        const SizedBox(height: 20),
        const Text(
          'Passo a Passo com Arquivo CSV',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ...QgisHelper.csvGuide.map((step) => _buildTutorialStepCard(step)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTutorialStepCard(QgisGuideStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
