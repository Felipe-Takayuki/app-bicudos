import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/pest_record.dart';
import '../providers/location_provider.dart';
import '../providers/pest_records_provider.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final PestRecord? recordToEdit;

  const AddEditRecordScreen({super.key, this.recordToEdit});

  @override
  ConsumerState<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends ConsumerState<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final TextEditingController _pestNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();

  double? _latitude;
  double? _longitude;
  double? _altitude;
  double? _accuracy;
  bool _isManualGps = false;

  bool get _isEditing => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final r = widget.recordToEdit!;
      _pestNameController.text = r.pestName;
      _quantityController.text = r.quantity.toString();
      _notesController.text = r.notes;
      _latitude = r.latitude;
      _longitude = r.longitude;
      _altitude = r.altitude;
      _accuracy = r.accuracy;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchGps();
      });
    }
  }

  @override
  void dispose() {
    _pestNameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fetchGps() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.fetchLocation();
    final locState = ref.read(locationProvider);

    if (locState.position != null) {
      setState(() {
        _latitude = locState.position!.latitude;
        _longitude = locState.position!.longitude;
        _altitude = locState.position!.altitude;
        _accuracy = locState.position!.accuracy;
        _isManualGps = false;
      });
    } else if (locState.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locState.errorMessage!),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Tentar Novamente',
            textColor: Colors.white,
            onPressed: _fetchGps,
          ),
        ),
      );
    }
  }

  void _adjustQuantity(int delta) {
    int current = int.tryParse(_quantityController.text) ?? 0;
    int updated = current + delta;
    if (updated < 1) updated = 1;
    setState(() {
      _quantityController.text = updated.toString();
    });
  }

  void _openMapPointPicker() {
    double initialLat = _latitude ?? AppConfig.mapDefaultLat;
    double initialLng = _longitude ?? AppConfig.mapDefaultLng;
    LatLng pickedPoint = LatLng(initialLat, initialLng);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Definir Ponto no Mapa'),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: pickedPoint,
                    initialZoom: AppConfig.mapDefaultZoom,
                    maxZoom: AppConfig.mapMaxZoom,
                    onTap: (_, latLng) {
                      setModalState(() {
                        pickedPoint = latLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConfig.mapTileUrl,
                      userAgentPackageName: AppConfig.mapUserAgent,
                      maxZoom: AppConfig.mapMaxZoom,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickedPoint,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _latitude = pickedPoint.latitude;
                      _longitude = pickedPoint.longitude;
                      _accuracy = 1.0;
                      _isManualGps = true;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirmar Ponto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde a captura do sinal GPS ou defina o ponto manualmente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pestName = _pestNameController.text.trim();
    final quantity = int.parse(_quantityController.text.trim());
    final notes = _notesController.text.trim();

    final record = PestRecord(
      id: _isEditing ? widget.recordToEdit!.id : _uuid.v4(),
      pestName: pestName,
      quantity: quantity,
      notes: notes,
      latitude: _latitude!,
      longitude: _longitude!,
      altitude: _altitude,
      accuracy: _accuracy,
      createdAt: _isEditing ? widget.recordToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(pestRecordsProvider.notifier);
    if (_isEditing) {
      await notifier.updateRecord(record);
    } else {
      await notifier.addRecord(record);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final allRecords = ref.watch(pestRecordsProvider).value ?? [];

    // Dynamically show only the pests previously registered by the user
    final userPests = allRecords
        .map((r) => r.pestName.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Registro' : 'Novo Registro de Pragas'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // GPS Location Card
            _buildGpsCard(locState),
            const SizedBox(height: 16),

            // Pest Identification Card
            _buildSectionCard(
              title: 'Identificação da Praga',
              icon: Icons.bug_report,
              children: [
                TextFormField(
                  controller: _pestNameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Praga',
                    hintText: 'Digite o nome da praga...',
                    prefixIcon: Icon(Icons.bug_report_outlined, color: AppColors.primary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe o nome da praga';
                    }
                    return null;
                  },
                ),
                // Only show previous user pest shortcuts if user has already entered any
                if (userPests.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Pragas utilizadas anteriormente:',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: userPests.map((pest) {
                      return ActionChip(
                        avatar: const Icon(Icons.history, size: 14),
                        label: Text(
                          pest,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _pestNameController.text = pest;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Quantity Counter with Quick Stepper Buttons
                const Text(
                  'Quantidade de Insetos / Pragas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _adjustQuantity(-1),
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Informe a quantidade';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 1) {
                            return 'Valor inválido (> 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _adjustQuantity(1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick add stepper buttons
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: const Text('+5'),
                        onPressed: () => _adjustQuantity(5),
                      ),
                      ActionChip(
                        label: const Text('+10'),
                        onPressed: () => _adjustQuantity(10),
                      ),
                      ActionChip(
                        label: const Text('+20'),
                        onPressed: () => _adjustQuantity(20),
                      ),
                      ActionChip(
                        label: const Text('+50'),
                        onPressed: () => _adjustQuantity(50),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Observations & Notes
            _buildSectionCard(
              title: 'Observações de Campo (Opcional)',
              icon: Icons.notes,
              children: [
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Foco severo na bordadura, folhas raspadas, presença de predadores...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _isEditing ? 'Salvar Alterações' : 'Registrar Ponto',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard(LocationState locState) {
    final hasLocation = _latitude != null && _longitude != null;
    final isFetching = locState.isLoading;

    Color statusColor = Colors.grey;
    String statusText = 'GPS não capturado';

    if (hasLocation) {
      if (_isManualGps) {
        statusColor = Colors.blue;
        statusText = 'Ponto definido manualmente';
      } else if (_accuracy != null && _accuracy! <= 5) {
        statusColor = AppColors.severityLow;
        statusText = 'GPS Excelente (±${_accuracy!.toStringAsFixed(1)}m)';
      } else if (_accuracy != null && _accuracy! <= 12) {
        statusColor = AppColors.severityMedium;
        statusText = 'GPS Bom (±${_accuracy!.toStringAsFixed(1)}m)';
      } else {
        statusColor = AppColors.severityHigh;
        statusText = 'GPS Moderado (±${_accuracy?.toStringAsFixed(1) ?? "?"}m)';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: statusColor, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Coordenadas GPS (WGS84)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (isFetching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasLocation) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latitude: ${_latitude!.toStringAsFixed(6)}°',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Longitude: ${_longitude!.toStringAsFixed(6)}°',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_altitude != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Alt: ${_altitude!.toStringAsFixed(0)}m',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Text(
              'Aguardando fixação das coordenadas do sensor GPS do dispositivo...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isFetching ? null : _fetchGps,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Atualizar GPS'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMapPointPicker,
                  icon: const Icon(Icons.map, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Ajustar no Mapa'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
