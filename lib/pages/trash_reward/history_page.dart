import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // >>>> UBAH: pakai lokal ID
import 'package:trashvisor/core/colors.dart';
import '../../globals.dart'; // routeObserver

class MissionHistoryPage extends StatefulWidget {
  const MissionHistoryPage({super.key});

  @override
  State<MissionHistoryPage> createState() => _MissionHistoryPageState();
}

class _MissionHistoryPageState extends State<MissionHistoryPage>
    with RouteAware {
  final _client = Supabase.instance.client;

  bool _loading = true;
  List<_HistoryRow> _rows = [];

  @override
  void initState() {
    super.initState();
    // >>>> UBAH: inisialisasi format Indonesia dulu baru load
    initializeDateFormatting('id_ID', null).then((_) => _reload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reload(); // refresh otomatis saat kembali ke layar ini
  }

  Future<void> _reload() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await _client
          .from('mission_history')
          .select('mission_date,status,created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      final result = <_HistoryRow>[];
      for (final r in (data as List)) {
        final status = (r['status'] ?? '').toString();
        final created = DateTime.tryParse(r['created_at']?.toString() ?? '');
        final missionDate = r['mission_date']?.toString();

        if (status.contains(':')) {
          final idx = status.indexOf(':');
          result.add(_HistoryRow(
            state: status.substring(0, idx),
            key: status.substring(idx + 1),
            createdAt: created,
            missionDate: missionDate,
          ));
        } else {
          result.add(_HistoryRow(
            state: status,
            key: '',
            createdAt: created,
            missionDate: missionDate,
          ));
        }
      }

      setState(() {
        _rows = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('load history error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final k = constraints.maxWidth / 360;

        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, true); // beri sinyal ke parent
            return false;
          },
          child: Scaffold(
            backgroundColor: AppColors.avocadoGreen,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60 * k),
              child: AppBar(
                backgroundColor: AppColors.whiteSmoke,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'Riwayat',
                  style: TextStyle(
                    color: AppColors.fernGreen,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 22 * k,
                  ),
                ),
                leading: Container(
                  margin: EdgeInsets.only(left: 8.0 * k),
                  padding: EdgeInsets.all(8.0 * k),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.fernGreen,
                      ),
                      child: Icon(Icons.close,
                          color: AppColors.whiteSmoke, size: 24 * k),
                    ),
                  ),
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _reload,
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.fernGreen),
                    )
                  : _rows.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20 * k),
                            Center(
                              child: Text(
                                'Belum ada riwayat',
                                style: TextStyle(
                                  color: AppColors.whiteSmoke,
                                  fontSize: 16 * k,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16 * k),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) =>
                              _HistoryTile(row: _rows[i], sizeRatio: k),
                        ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryRow {
  final String state;      // processing/completed/claimed/failed/...
  final String key;        // checkin/record_paper/...
  final DateTime? createdAt;
  final String? missionDate;

  _HistoryRow({
    required this.state,
    required this.key,
    required this.createdAt,
    required this.missionDate,
  });
}

class _HistoryTile extends StatelessWidget {
  final _HistoryRow row;
  final double sizeRatio;

  const _HistoryTile({required this.row, required this.sizeRatio});

  @override
  Widget build(BuildContext context) {
    final s = row.state.toLowerCase();
    final icon = _iconForState(s);
    final badgeColor = _badgeColorForState(s);
    final title = _titleFor(row);
    final when = _formatWhen(row); // >>>> UBAH: hari + tanggal (ID) + jam

    return Container(
      margin: EdgeInsets.only(bottom: 10 * sizeRatio),
      padding: EdgeInsets.all(16 * sizeRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFD6),
        borderRadius: BorderRadius.circular(15 * sizeRatio),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * sizeRatio),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(50 * sizeRatio),
            ),
            child: Icon(icon, color: AppColors.whiteSmoke, size: 24 * sizeRatio),
          ),
          SizedBox(width: 15 * sizeRatio),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.deepForestGreen,
                    fontFamily: 'Nunito',
                    fontSize: 15 * sizeRatio,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6 * sizeRatio),
                Text(
                  when,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.fernGreen,
                    fontSize: 13 * sizeRatio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // >>>> UBAH: prioritas pakai mission_date untuk hari/tanggal; createdAt untuk jam
  String _formatWhen(_HistoryRow r) {
    // mission_date → hari + tanggal
    if (r.missionDate != null && r.missionDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(r.missionDate!) ??
          DateTime.tryParse('${r.missionDate!}T00:00:00Z');
      if (parsed != null) {
        final d = parsed.toLocal();
        final hari = DateFormat('EEEE', 'id_ID').format(d);
        final tgl = DateFormat('dd MMM yyyy', 'id_ID').format(d);
        // jika ada createdAt, tampilkan jamnya
        if (r.createdAt != null) {
          final jam = DateFormat('HH:mm', 'id_ID').format(r.createdAt!.toLocal());
          return '$hari, $tgl • $jam';
        }
        return '$hari, $tgl';
      }
    }
    // fallback: createdAt saja
    if (r.createdAt != null) {
      final d = r.createdAt!.toLocal();
      final hari = DateFormat('EEEE', 'id_ID').format(d);
      final tgl = DateFormat('dd MMM yyyy', 'id_ID').format(d);
      final jam = DateFormat('HH:mm', 'id_ID').format(d);
      return '$hari, $tgl • $jam';
    }
    return '-';
  }

  String _titleFor(_HistoryRow r) {
    final label = _labelForKey(r.key);
    switch (r.state.toLowerCase()) {
      case 'processing': return 'Validasi sedang diproses — $label';
      case 'completed': return 'Validasi selesai (siap klaim) — $label';
      case 'claimed':   return 'Poin berhasil diklaim — $label';
      case 'failed':    return 'Validasi gagal (silakan ulangi) — $label';
      default:          return '${r.state} — $label';
    }
  }

  String _labelForKey(String k) {
    switch (k) {
      case 'checkin':               return 'Check-in harian';
      case 'record_paper':          return 'Rekam sampah kertas';
      case 'record_leaves':         return 'Rekam sampah daun';
      case 'record_plastic_bottle': return 'Rekam botol plastik';
      case 'record_can':            return 'Rekam kaleng minuman';
      default:                      return k.isEmpty ? '—' : k;
    }
  }

  IconData _iconForState(String s) {
    switch (s) {
      case 'processing': return Icons.cloud_upload_outlined;
      case 'completed':  return Icons.verified_outlined;
      case 'claimed':    return Icons.monetization_on_outlined;
      case 'failed':     return Icons.error_outline;
      default:           return Icons.history;
    }
  }

  Color _badgeColorForState(String s) {
    switch (s) {
      case 'processing': return AppColors.avocadoGreen;
      case 'completed':  return AppColors.fernGreen;
      case 'claimed':    return AppColors.rewardGold;
      case 'failed':     return Colors.red;
      default:           return AppColors.darkMossGreen;
    }
  }
}