import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../globals.dart'; // routeObserver

// 🔹 Custom messages tanpa "yang lalu"
class MyCustomMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => ''; // hapus "yang lalu"
  @override
  String suffixFromNow() => 'dari sekarang';
  @override
  String lessThanOneMinute(int seconds) => 'baru saja';
  @override
  String aboutAMinute(int minutes) => '1 menit';
  @override
  String minutes(int minutes) => '$minutes menit';
  @override
  String aboutAnHour(int minutes) => '1 jam';
  @override
  String hours(int hours) => '$hours jam';
  @override
  String aDay(int hours) => '1 hari';
  @override
  String days(int days) => '$days hari';
  @override
  String aboutAMonth(int days) => '1 bulan';
  @override
  String months(int months) => '$months bulan';
  @override
  String aboutAYear(int years) => '1 tahun';
  @override
  String years(int years) => '$years tahun';
  @override
  String wordSeparator() => ' ';
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with RouteAware {
  final _client = Supabase.instance.client;

  bool _loading = true;
  List<_NotificationRow> _rows = [];

  @override
  void initState() {
    super.initState();
    // 🔹 register locale Indonesia custom
    timeago.setLocaleMessages('id_custom', MyCustomMessages());

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
    _reload(); // refresh otomatis saat kembali
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

      final result = <_NotificationRow>[];
      for (final r in (data as List)) {
        final status = (r['status'] ?? '').toString();
        final created = DateTime.tryParse(r['created_at']?.toString() ?? '');
        final missionDate = r['mission_date']?.toString();

        if (status.contains(':')) {
          final idx = status.indexOf(':');
          result.add(_NotificationRow(
            state: status.substring(0, idx),
            key: status.substring(idx + 1),
            createdAt: created,
            missionDate: missionDate,
          ));
        } else {
          result.add(_NotificationRow(
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
      debugPrint('load notifications error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final k = constraints.maxWidth / 360;

        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, true);
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
                  'Notifikasi',
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
                            SizedBox(height: 40 * k),
                            Center(
                              child: Text(
                                'Belum ada notifikasi',
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
                          itemBuilder: (context, i) => _NotificationTile(
                            row: _rows[i],
                            sizeRatio: k,
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationRow {
  final String state;
  final String key;
  final DateTime? createdAt;
  final String? missionDate;

  _NotificationRow({
    required this.state,
    required this.key,
    required this.createdAt,
    required this.missionDate,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotificationRow row;
  final double sizeRatio;

  const _NotificationTile({required this.row, required this.sizeRatio});

  @override
  Widget build(BuildContext context) {
    final s = row.state.toLowerCase();
    final icon = _iconForState(s);
    final title = _titleFor(row);
    final subtitle = _subtitleFor(row);
    final when = _formatWhen(row);

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
              color: AppColors.avocadoGreen,
              borderRadius: BorderRadius.circular(50 * sizeRatio),
            ),
            child: Icon(icon,
                color: AppColors.lightSageGreen, size: 24 * sizeRatio),
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
                SizedBox(height: 5 * sizeRatio),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.fernGreen,
                    fontSize: 13 * sizeRatio,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 4.0 * sizeRatio),
            child: Text(
              when,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: AppColors.fernGreen,
                fontSize: 12 * sizeRatio,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWhen(_NotificationRow r) {
    if (r.createdAt != null) {
      return timeago.format(r.createdAt!.toLocal(), locale: 'id_custom');
    }
    return '-';
  }

  String _titleFor(_NotificationRow r) {
    final label = _labelForKey(r.key);
    switch (r.state.toLowerCase()) {
      case 'processing': return 'Sedang divalidasi — $label';
      case 'completed': return 'Validasi selesai — $label';
      case 'claimed':   return 'Poin berhasil diklaim — $label';
      case 'failed':    return 'Validasi gagal — $label';
      default:          return '${r.state} — $label';
    }
  }

  String _subtitleFor(_NotificationRow r) {
    switch (r.state.toLowerCase()) {
      case 'processing': return 'Tunggu beberapa saat, data kamu sedang diperiksa';
      case 'completed':  return 'Misi selesai dan siap klaim poin';
      case 'claimed':    return 'Poin sudah masuk ke akunmu';
      case 'failed':     return 'Silakan coba ulangi misi ini';
      default:           return '';
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
      default:           return Icons.notifications;
    }
  }
}