import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/pest_records_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  String? _selectedPest;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minQuantity;

  @override
  void initState() {
    super.initState();
    final current = ref.read(pestFilterProvider);
    _selectedPest = current.selectedPest;
    _startDate = current.startDate;
    _endDate = current.endDate;
    _minQuantity = current.minQuantity;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(pestRecordsProvider);
    final allRecords = recordsAsync.value ?? [];
    final availablePests = allRecords.map((r) => r.pestName).toSet().toList();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtrar Registros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPest = null;
                      _startDate = null;
                      _endDate = null;
                      _minQuantity = null;
                    });
                  },
                  child: const Text('Limpar Tudo'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date Range Filter
            const Text(
              'Período de Coleta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('dd/MM/yy').format(_startDate!)} até ${DateFormat('dd/MM/yy').format(_endDate!)}'
                          : 'Todas as datas',
                      style: TextStyle(
                        color: _startDate != null ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pest Filter
            const Text(
              'Filtrar por Praga',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedPest,
              decoration: const InputDecoration(
                hintText: 'Todas as pragas',
                prefixIcon: Icon(Icons.bug_report, color: AppColors.primary),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as pragas')),
                ...availablePests.map((p) => DropdownMenuItem(value: p, child: Text(p))),
              ],
              onChanged: (val) => setState(() => _selectedPest = val),
            ),
            const SizedBox(height: 16),

            // Min Quantity Filter
            const Text(
              'Quantidade Mínima de Insetos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Qualquer'),
                  selected: _minQuantity == null,
                  onSelected: (_) => setState(() => _minQuantity = null),
                ),
                ChoiceChip(
                  label: const Text('≥ 5 un'),
                  selected: _minQuantity == 5,
                  onSelected: (sel) => setState(() => _minQuantity = sel ? 5 : null),
                ),
                ChoiceChip(
                  label: const Text('≥ 15 un'),
                  selected: _minQuantity == 15,
                  onSelected: (sel) => setState(() => _minQuantity = sel ? 15 : null),
                ),
                ChoiceChip(
                  label: const Text('≥ 30 un'),
                  selected: _minQuantity == 30,
                  onSelected: (sel) => setState(() => _minQuantity = sel ? 30 : null),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(pestFilterProvider.notifier);
                  notifier.setPest(_selectedPest);
                  notifier.setDateRange(_startDate, _endDate);
                  notifier.setMinQuantity(_minQuantity);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
