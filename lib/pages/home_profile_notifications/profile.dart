import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/pages/loginandregister/login.dart' show LoginPage;

// >>> UBAH: daftar key misi scan (dipakai untuk hitung 5 tugas/hari)
const Set<String> _scanKeys = {
  'record_paper',
  'record_leaves',
  'record_plastic_bottle',
  'record_can',
};

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // ------------------------ Top-banner (success) ------------------------
  late final AnimationController _bannerCtl;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;
  String _bannerMessage = '';

  // Ambang batas level
  final List<Map<String, dynamic>> _levelThresholds = [
    {
      'name': 'Bronze',
      'min_score': 0,
      'max_score': 1000,
      'color': Colors.brown,
    },
    {
      'name': 'Silver',
      'min_score': 1000,
      'max_score': 3000,
      'color': Colors.grey,
    },
    {
      'name': 'Gold',
      'min_score': 3000,
      'max_score': 6000,
      'color': Colors.amber,
    },
  ];

  // cache kecil untuk aktivitas minggu ini
  late final Future<List<_ProfileDayState>> _weeklyActivity;

  @override
  void initState() {
    super.initState();
    _bannerCtl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 180),
        )..addStatusListener((status) {
          if (status == AnimationStatus.dismissed) {
            _bannerEntry?.remove();
            _bannerEntry = null;
          }
        });

    _weeklyActivity = _loadWeeklyActivity();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtl.dispose();
    _bannerEntry?.remove();
    _bannerEntry = null;
    super.dispose();
  }

  // Top banner hijau (gaya sama dg login)
  void _showTopBanner(
    String message, {
    Color bg = AppColors.fernGreen,
  }) {
    _bannerTimer?.cancel();
    _bannerMessage = message;

    final media = MediaQuery.of(context);
    final topPad = media.padding.top; // SafeArea atas
    const double side = 12;

    if (_bannerEntry == null) {
      _bannerEntry = OverlayEntry(
        builder: (_) => Positioned(
          top: topPad + 8,
          left: side,
          right: side,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _bannerCtl,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: FadeTransition(
              opacity: _bannerCtl,
              child: Material(
                color: bg,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  // >>> UBAH: Padding harus pakai named parameter `padding`
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    // HAPUS "const" di sini
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _bannerMessage, // <-- pakai variabelnya
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_bannerEntry!);
    } else {
      _bannerEntry!.markNeedsBuild();
    }

    _bannerCtl.forward(from: 0);
    _bannerTimer = Timer(const Duration(milliseconds: 1200), () {
      _bannerCtl.reverse();
    });
  }

  // Ambil info profil
  Future<Map<String, dynamic>> _loadProfileInfo() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return {
        'name': 'Pengguna',
        'first': 'Pengguna',
        'email': '',
        'score': 0,
        'level_name': 'Bronze',
        'level_color': Colors.brown,
      };
    }

    String? fullName;
    int? score;

    try {
      final row = await client
          .from('profiles')
          .select('full_name, score')
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        fullName = (row['full_name'] as String?)?.trim();
        score = row['score'] as int?;
      }
    } catch (_) {}

    final meta = user.userMetadata;
    if ((fullName == null || fullName.isEmpty) && meta != null) {
      for (final key in ['full_name', 'name', 'nama']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) {
          fullName = v.trim();
          break;
        }
      }
    }

    final email = user.email ?? '';
    fullName ??= email.split('@').first;

    String titleTwoWords(String s) {
      final parts = s
          .split(RegExp(r'[\s._-]+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'Pengguna';
      final chosen = parts
          .take(2)
          .map((w) {
            final lower = w.toLowerCase();
            return lower[0].toUpperCase() + lower.substring(1);
          })
          .join(' ');
      return chosen;
    }

    String titleFirstWord(String s) {
      final parts = s
          .split(RegExp(r'[\s._-]+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'Pengguna';
      final lower = parts.first.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }

    final int userScore = score ?? 0;
    final currentLevel = _levelThresholds.firstWhere(
      (level) =>
          userScore >= (level['min_score'] as int) &&
          userScore < (level['max_score'] as int),
      orElse: () => _levelThresholds.last,
    );

    return {
      'name': titleTwoWords(fullName),
      'first': titleFirstWord(fullName),
      'email': email,
      'score': userScore,
      'level_name': currentLevel['name'] as String,
      'level_color': currentLevel['color'] as Color,
    };
  }

  // Logout
  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    final info = await _loadProfileInfo();
    final friendlyFirst = info['first'] ?? 'Pengguna';

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    _showTopBanner('Selamat tinggal, $friendlyFirst');
    await Future.delayed(const Duration(milliseconds: 900));
    final cams = await availableCameras();

    if (!nav.mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(cameras: cams)),
      (_) => false,
    );
  }

  // ===================== AKTIVITAS MINGGUAN (DATA) =====================

  // >>> UBAH: definisi “sukses per key per hari”
  // - checkin: cukup status `completed:` atau `claimed:`
  // - misi scan: dianggap sukses hanya jika `claimed:` (bukan `completed:`)
  static bool _isSuccessForKey(String state, String key) {
    final s = state.toLowerCase();
    if (key == 'checkin') {
      return s.startsWith('completed') || s.startsWith('claimed');
    }
    if (_scanKeys.contains(key)) {
      return s.startsWith('claimed'); // harus klaim dulu
    }
    return false;
  }

  Future<List<_ProfileDayState>> _loadWeeklyActivity() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final today = _onlyDate(DateTime.now());
    final monday = _mondayOf(today);
    final sunday = monday.add(const Duration(days: 6));

    if (user == null) {
      return _buildWeekSkeleton(createdAt: today, today: today, monday: monday);
    }

    DateTime createdAt = today;
    try {
      final prof = await client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (prof != null && prof['created_at'] != null) {
        createdAt = _onlyDate(DateTime.parse(prof['created_at'].toString()));
      }
    } catch (_) {}

    // >>> UBAH: hitung per tanggal -> set “keys sukses” & ada aktivitas
    final Map<DateTime, Set<String>> successKeysPerDay = {};
    final Map<DateTime, bool> activityPerDay = {};

    try {
      final rows = await client
          .from('mission_history')
          .select('mission_date,status')
          .eq('user_id', user.id)
          .gte('mission_date', _yyyyMmDd(monday))
          .lte('mission_date', _yyyyMmDd(sunday));

      for (final r in rows as List) {
        final dStr = r['mission_date'];
        final st = (r['status'] ?? '').toString();
        if (dStr == null || st.isEmpty) continue;
        final d = _onlyDate(DateTime.parse(dStr.toString()));
        activityPerDay[d] = true;

        // parse "state:key"
        if (st.contains(':')) {
          final i = st.indexOf(':');
          final state = st.substring(0, i);
          final key = st.substring(i + 1);
          if (_isSuccessForKey(state, key)) {
            (successKeysPerDay[d] ??= <String>{}).add(key);
          }
        }
      }
    } catch (_) {}

    // Rakit 7 hari → completed = 5 key sukses (checkin + 4 scan)
    const labels = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<_ProfileDayState> out = [];
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final isCurrent =
          d.year == today.year && d.month == today.month && d.day == today.day;

      final eligible = !(beforeCreated || inFuture);
      final succCount = (successKeysPerDay[d] ?? const <String>{}).length;
      final isCompleted = eligible && succCount >= 5;

      out.add(
        _ProfileDayState(
          label: labels[i],
          date: d,
          eligible: eligible,
          completed: isCompleted,
          hasActivity: eligible && (activityPerDay[d] ?? false),
          isCurrent: isCurrent,
        ),
      );
    }
    return out;
  }

  List<_ProfileDayState> _buildWeekSkeleton({
    required DateTime createdAt,
    required DateTime today,
    required DateTime monday,
  }) {
    const labels = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<_ProfileDayState> out = [];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final eligible = !(beforeCreated || inFuture);
      final isCurrent =
          d.year == today.year && d.month == today.month && d.day == today.day;
      out.add(
        _ProfileDayState(
          label: labels[i],
          date: d,
          eligible: eligible,
          completed: false,
          hasActivity: false,
          isCurrent: isCurrent,
        ),
      );
    }
    return out;
  }

  // ===================== HELPERS TANGGAL =====================

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) {
    final wd = d.weekday; // Mon=1 ... Sun=7
    return _onlyDate(d.subtract(Duration(days: wd - 1)));
  }

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _ddMMyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_profile.jpg'),
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTombolAtas(context),
              const SizedBox(height: 150),
              _buildKartuKonten(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Pembantu ---

  Widget _buildTombolAtas(BuildContext context) {
    return Padding(
      // >>> UBAH: Padding pakai named parameter
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTombolKembali(
            ikon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
          _buildTombolKeluar(
            teks: 'Keluar',
            ikon: Icons.exit_to_app,
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTombolKeluar({
    String? teks,
    required IconData ikon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.whiteSmoke, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: [
            Icon(ikon, color: AppColors.whiteSmoke, size: 20),
            if (teks != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  teks,
                  style: const TextStyle(
                    color: AppColors.whiteSmoke,
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTombolKembali({
    required IconData ikon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.whiteSmoke, width: 2),
      ),
      child: IconButton(
        icon: Icon(ikon, color: AppColors.whiteSmoke),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 20,
      ),
    );
  }

  Widget _buildKartuKonten(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        // >>> UBAH: Padding pakai named parameter
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBagianProfilPengguna(context),
            const SizedBox(height: 20),
            _buildBagianAktivitasMingguan(),
          ],
        ),
      ),
    );
  }

  // ---------------- PROFIL ----------------

  Widget _buildBagianProfilPengguna(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadProfileInfo(),
      builder: (context, snap) {
        final loading = !snap.hasData;
        final name = snap.data?['name'] ?? 'Pengguna';
        final email = snap.data?['email'] ?? '';
        final score = snap.data?['score'] as int? ?? 0;
        final levelName = snap.data?['level_name'] ?? 'Bronze';
        final levelColor = snap.data?['level_color'] ?? Colors.brown;

        return Row(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.fernGreen.withAlpha((255 * 0.2).round()),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fernGreen, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.person, size: 60, color: AppColors.fernGreen),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading ? 'Memuat…' : email,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLevelContainer(levelName, levelColor),
                      const Spacer(),
                      _buildContainerKoin(score),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelContainer(String levelName, Color levelColor) {
    return Row(
      children: [
        Icon(Icons.stars, color: levelColor, size: 30),
        const SizedBox(width: 4),
        Text(
          'Level $levelName',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: levelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContainerKoin(int jumlah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.amberAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            jumlah.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: AppColors.whiteSmoke,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- AKTIVITAS MINGGUAN ----------------

  Widget _buildBagianAktivitasMingguan() {
    final today = _onlyDate(DateTime.now());
    final monday = _mondayOf(today);
    final sunday = monday.add(const Duration(days: 6));
    final rangeText = '${_ddMMyyyy(monday)} - ${_ddMMyyyy(sunday)}';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Mingguan',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteSmoke,
                ),
              ),
              Text(
                rangeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: AppColors.whiteSmoke,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<_ProfileDayState>>(
            future: _weeklyActivity,
            builder: (context, snap) {
              final data = snap.data;
              if (data == null) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.whiteSmoke,
                      strokeWidth: 2.2,
                    ),
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((d) {
                  return Column(
                    children: [
                      _buildIkonStatusProfile(
                        eligible: d.eligible,
                        completed: d.completed,
                        hasActivity: d.hasActivity,
                        isCurrent: d.isCurrent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.label,
                        style: const TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIkonStatusProfile({
    required bool eligible,
    required bool completed,
    required bool hasActivity,
    required bool isCurrent,
  }) {
    if (!eligible) {
      return Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: AppColors.whiteSmoke,
          shape: BoxShape.circle,
        ),
      );
    }

    if (completed) {
      return Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: AppColors.whiteSmoke,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 32.5),
      );
    }

    // tidak completed -> silang merah (sesuai permintaan)
    return Container(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.cancel, color: Colors.red, size: 32.5),
    );
  }
}

// ===== Model kecil aktivitas harian untuk profil =====
class _ProfileDayState {
  final String label;
  final DateTime date;
  final bool eligible;
  final bool completed;
  final bool hasActivity;
  final bool isCurrent;

  _ProfileDayState({
    required this.label,
    required this.date,
    required this.eligible,
    required this.completed,
    required this.hasActivity,
    required this.isCurrent,
  });
}
