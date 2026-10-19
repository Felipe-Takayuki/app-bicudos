import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/pest_records_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/pest_card.dart';
import '../widgets/stats_overview_card.dart';
import 'add_edit_record_screen.dart';
import 'export_screen.dart';
import 'map_view_screen.dart';
import 'record_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }


  void _confirmClearAll(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Todos os Registros'),
        content: const Text(
          'Deseja realmente apagar todos os registros do banco de dados local? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(pestRecordsProvider.notifier).clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos os registros foram removidos.')),
                );
              }
            },
            child: const Text('Apagar Tudo'),
          ),
        ],
      ),
    );
  }

  void _triggerSync() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Autenticação Necessária'),
          content: const Text(
            'Para sincronizar os dados de monitoramento com a nuvem, faça login ou cadastre-se na plataforma.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Fazer Login'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    final result = await ref.read(syncProvider.notifier).sync();
    if (!mounted) return;

    if (result != null && result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '☁️ ${result.message} (${result.syncedToServer} enviados, ${result.receivedFromServer} recebidos)',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      final err = ref.read(syncProvider).errorMessage ?? 'Falha ao sincronizar com o servidor.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $err'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showUserSheet() {
    final authState = ref.read(authProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Icon(
                      authState.isAuthenticated ? Icons.person : Icons.cloud_off,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.isAuthenticated
                              ? authState.user!.name
                              : 'Modo Offline (Sem Conta)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authState.isAuthenticated
                              ? '${authState.user!.roleDisplayName} • ${authState.user!.email}'
                              : 'Os dados estão salvos apenas neste aparelho.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (authState.isAuthenticated) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync, color: AppColors.primary),
                  title: const Text('Sincronizar com a Nuvem'),
                  subtitle: const Text('Enviar registros locais e receber dados atualizados'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _triggerSync();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sessão encerrada com sucesso.')),
                      );
                    }
                  },
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar ou Criar Conta'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(pestRecordsProvider);
    final filteredRecords = ref.watch(filteredPestRecordsProvider);
    final stats = ref.watch(pestStatisticsProvider);
    final filter = ref.watch(pestFilterProvider);
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final allRecords = recordsAsync.value ?? [];
    final pointNumbers = ref.watch(recordPointNumbersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoramento',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Botão de Sincronização em Nuvem com animação de loading
          IconButton(
            tooltip: syncState.isSyncing
                ? 'Sincronizando...'
                : (authState.isAuthenticated ? 'Sincronizar com Nuvem' : 'Sincronização Offline'),
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    authState.isAuthenticated ? Icons.cloud_sync_outlined : Icons.cloud_outlined,
                  ),
            onPressed: syncState.isSyncing ? null : _triggerSync,
          ),
          IconButton(
            tooltip: 'Visualizar no Mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapViewScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Exportar para QGIS',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
          ),
          // Botão de Perfil / Conta
          IconButton(
            tooltip: authState.isAuthenticated ? 'Perfil (${authState.user!.name})' : 'Conta / Login',
            icon: Badge(
              isLabelVisible: authState.isAuthenticated,
              backgroundColor: Colors.greenAccent.shade700,
              child: const Icon(Icons.account_circle_outlined),
            ),
            onPressed: _showUserSheet,
          ),
          if (allRecords.isNotEmpty) ...[
            IconButton(
              tooltip: 'Limpar Todos os Registros',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(ref),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(pestRecordsProvider.notifier).loadRecords(),
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar dados: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(pestRecordsProvider.notifier).loadRecords(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          ),
          data: (allRecords) {
            return CustomScrollView(
              slivers: [
                // Banner de Status da Conexão / Nuvem
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: authState.isAuthenticated
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: authState.isAuthenticated
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.amber.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          authState.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                          size: 18,
                          color: authState.isAuthenticated ? AppColors.primary : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.isAuthenticated
                                ? 'Nuvem Ativa: ${authState.user!.name} (${authState.user!.roleDisplayName})'
                                : 'Modo Offline: Dados salvos localmente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: authState.isAuthenticated
                                  ? AppColors.primary
                                  : Colors.amber.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: authState.isAuthenticated
                              ? (syncState.isSyncing ? null : _triggerSync)
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                },
                          child: Text(
                            authState.isAuthenticated
                                ? (syncState.isSyncing ? 'Sincronizando...' : 'Sincronizar')
                                : 'Conectar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Search Bar & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por praga ou anotação...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(pestFilterProvider.notifier)
                                            .setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (val) {
                              ref.read(pestFilterProvider.notifier).setSearchQuery(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _openFilterSheet,
                              icon: const Icon(Icons.tune),
                              tooltip: 'Filtros',
                            ),
                            if (filter.hasActiveFilters)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Filters Chips Bar
                if (filter.hasActiveFilters)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (filter.selectedPest != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  filter.selectedPest!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () =>
                                    ref.read(pestFilterProvider.notifier).setPest(null),
                              ),
                            ),
                          if (filter.minQuantity != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  '≥ ${filter.minQuantity} un',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => ref
                                    .read(pestFilterProvider.notifier)
                                    .setMinQuantity(null),
                              ),
                            ),
                          TextButton(
                            onPressed: () =>
                                ref.read(pestFilterProvider.notifier).resetFilters(),
                            child: const Text('Limpar', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Statistics Card
                if (allRecords.isNotEmpty)
                  SliverToBoxAdapter(
                    child: StatsOverviewCard(
                      stats: stats,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapViewScreen()),
                        );
                      },
                    ),
                  ),

                // List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pontos Coletados (${filteredRecords.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (filteredRecords.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Ver no Mapa'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MapViewScreen(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Empty State
                if (filteredRecords.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco_outlined,
                                size: 54,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              allRecords.isEmpty
                                  ? 'Nenhum ponto registrado ainda'
                                  : 'Nenhum ponto encontrado com os filtros atuais',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              allRecords.isEmpty
                                  ? 'Comece adicionando seu primeiro registro de pragas com as coordenadas GPS do campo.'
                                  : 'Tente alterar os termos da busca ou limpar os filtros aplicados.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (allRecords.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEditRecordScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    ref.read(pestRecordsProvider.notifier).loadRecords();
                                  }
                                },
                                icon: const Icon(Icons.add_location_alt),
                                label: const Text('Novo Registro de Pragas'),
                              )
                            else
                              OutlinedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(pestFilterProvider.notifier)
                                      .resetFilters();
                                },
                                child: const Text('Limpar Filtros'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Records List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = filteredRecords[index];
                        final pointNumber = pointNumbers[record.id];
                        return PestCard(
                          record: record,
                          pointNumber: pointNumber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordDetailScreen(
                                  record: record,
                                  pointNumber: pointNumber,
                                ),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditRecordScreen(recordToEdit: record),
                              ),
                            );
                          },
                          onDelete: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref
                                .read(pestRecordsProvider.notifier)
                                .deleteRecord(record.id);
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Registro removido com sucesso.'),
                                ),
                              );
                            }
                          },
                        );
                      },
                      childCount: filteredRecords.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_add_btn',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRecordScreen(),
            ),
          );
          if (result == true) {
            ref.read(pestRecordsProvider.notifier).loadRecords();
          }
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Novo Ponto'),
      ),
    );
  }
}
