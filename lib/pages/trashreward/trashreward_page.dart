import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';
import 'widgets/mission_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class EcoRewardPage extends StatefulWidget {
  const EcoRewardPage({super.key});

  @override
  State<EcoRewardPage> createState() => _EcoRewardPageState();
}

class _EcoRewardPageState extends State<EcoRewardPage>
    with SingleTickerProviderStateMixin { // (NEW) untuk top-toast
  String _formattedDate = '';

  final List<Map<String, dynamic>> _levelThresholds = const [
    {'name': 'Bronze', 'min_score': 0, 'max_score': 1000},
    {'name': 'Silver', 'min_score': 1000, 'max_score': 3000},
    {'name': 'Gold', 'min_score': 3000, 'max_score': 6000},
  ];

  // (PERBAIKAN) biar bisa di-refresh setelah selesai misi
  late Future<Map<String, dynamic>> _profileData;
  late Future<List<_DayState>> _dailyRow;

  // (NEW) cache tombol selesai per-misi (UI)
  final Set<String> _completedMissionKeys = {};

  // ------------------------ (NEW) Top-toast (success) ------------------------
  late final AnimationController _toastCtl;
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;
  String _toastMsg = '';

  @override
  void initState() {
    super.initState();
    _profileData = _loadProfileAndLevelInfo();
    _dailyRow = _loadDailyRowData();
    _initializeDate();

    _toastCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    )..addStatusListener((s) {
        if (s == AnimationStatus.dismissed) {
          _toastEntry?.remove();
          _toastEntry = null;
        }
      });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastCtl.dispose();
    _toastEntry?.remove();
    _toastEntry = null;
    super.dispose();
  }

  void _showTopToast(
    String message, {
    Color bg = AppColors.fernGreen,
    Color fg = Colors.white,
  }) {
    _toastTimer?.cancel();
    _toastMsg = message;

    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    const double side = 12;

    if (_toastEntry == null) {
      _toastEntry = OverlayEntry(
        builder: (_) => Positioned(
          top: topPad + 8,
          left: side,
          right: side,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _toastCtl,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
            child: FadeTransition(
              opacity: _toastCtl,
              child: Material(
                color: bg,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _toastMsg,
                          style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
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
      Overlay.of(context).insert(_toastEntry!);
    } else {
      _toastEntry!.markNeedsBuild();
    }

    _toastCtl.forward(from: 0);
    _toastTimer = Timer(const Duration(milliseconds: 1200), () {
      _toastCtl.reverse();
    });
  }
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => _buildRoot(context);

  Future<void> _initializeDate() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      _formattedDate =
          DateFormat('EEEE, dd - MM - yyyy', 'id_ID').format(DateTime.now());
    });
  }

  // ===================== PROFILE + LEVEL =====================

  Future<Map<String, dynamic>> _loadProfileAndLevelInfo() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return {
        'name': 'Pengguna',
        'score': 0,
        'level_name': 'Bronze',
        'progress_text': '1000 poin menuju level Silver',
        'progress_value': 0.0,
      };
    }

    try {
      final row = await client
          .from('profiles')
          .select('full_name, score')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        throw Exception('User profile not found.');
      }

      final fullNameFromRow = (row['full_name'] as String?)?.trim();
      final fullName = (fullNameFromRow != null && fullNameFromRow.isNotEmpty)
          ? fullNameFromRow
          : (user.email?.split('@').first ?? 'Pengguna');

      final score = row['score'] as int? ?? 0;

      final currentLevel = _levelThresholds.firstWhere(
        (l) => score >= (l['min_score'] as int) && score < (l['max_score'] as int),
        orElse: () => _levelThresholds.last,
      );

      String progressText;
      double progressValue;

      if (currentLevel['name'] == 'Gold') {
        final minS = currentLevel['min_score'] as int;
        final maxS = currentLevel['max_score'] as int;
        final range = maxS - minS;
        progressValue = range > 0 ? (score - minS) / range : 0.0;
        progressText = '${maxS - score} poin menuju batas akhir';
      } else {
        final nextIndex = _levelThresholds.indexOf(currentLevel) + 1;
        final next = _levelThresholds[nextIndex];
        final nextMin = next['min_score'] as int;
        final curMin = currentLevel['min_score'] as int;
        final range = nextMin - curMin;
        progressValue = range > 0 ? (score - curMin) / range : 1.0;
        progressText = '${nextMin - score} poin menuju level ${next['name']}';
      }

      return {
        'name': fullName,
        'score': score,
        'level_name': currentLevel['name'] as String,
        'progress_text': progressText,
        'progress_value': progressValue,
      };
    } catch (e) {
      debugPrint('Error loading profile and level info: $e');
      return {
        'name': 'Pengguna',
        'score': 0,
        'level_name': 'Bronze',
        'progress_text': '1000 poin menuju level Silver',
        'progress_value': 0.0,
      };
    }
  }

  // ===================== TUGAS HARIAN (DATA) =====================

  Future<List<_DayState>> _loadDailyRowData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final now = DateTime.now();
    final today = _dateOnly(now);

    if (user == null) {
      // semua abu-abu, hari ini diborder hijau
      return _weekSkeleton(today, today);
    }

    // ambil tanggal dibuatnya akun (profiles.created_at); fallback: today
    DateTime createdAt = today;
    try {
      final prof = await client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (prof != null && prof['created_at'] != null) {
        createdAt = _dateOnly(DateTime.parse(prof['created_at'].toString()));
      }
    } catch (_) {
      // ignore, pakai today
    }

    // window minggu ini: Senin..Minggu
    final monday = _mondayOf(today);
    final sunday = monday.add(const Duration(days: 6));

    // (PERBAIKAN) ambil mission_history minggu ini: tandai sukses & ada aktivitas
    final Set<DateTime> successDays = {};
    final Set<DateTime> activityDays = {};
    try {
      final rows = await client
          .from('mission_history')
          .select('mission_date,status')
          .eq('user_id', user.id)
          .gte('mission_date', _yyyyMmDd(monday))
          .lte('mission_date', _yyyyMmDd(sunday));

      for (final r in rows as List) {
        final dStr = r['mission_date'];
        if (dStr == null) continue;
        final d = _dateOnly(DateTime.parse(dStr.toString()));
        activityDays.add(d); // ada baris apapun -> ada aktivitas
        final status = (r['status'] ?? '').toString().toLowerCase();
        final ok = ['done', 'completed', 'success', 'selesai', 'finish']
            .any((k) => status.contains(k)); // status "completed:<key>" juga masuk
        if (ok) successDays.add(d);
      }
    } catch (e) {
      debugPrint('err load mission_history: $e');
    }

    // (PERBAIKAN) rakit 7 hari — eligible = created_at..today
    final labels = const [
      'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'
    ];
    final List<_DayState> result = [];
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final eligible = !(beforeCreated || inFuture); // (PERBAIKAN)
      final isCompleted = eligible && successDays.contains(d);
      final hasActivity = eligible && activityDays.contains(d); // (NEW)
      final isCurrent = d.year == today.year && d.month == today.month && d.day == today.day;
      result.add(_DayState(
        label: labels[i],
        date: d,
        eligible: eligible,
        completed: isCompleted,
        hasActivity: hasActivity, // (NEW)
        isCurrent: isCurrent,
      ));
    }
    return result;
  }

  // skeleton 1 minggu (dipakai saat belum login/dll)
  List<_DayState> _weekSkeleton(DateTime createdAt, DateTime today) {
    final monday = _mondayOf(today);
    final labels = const ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];

    final List<_DayState> out = [];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final eligible = !(beforeCreated || inFuture); // (PERBAIKAN)
      out.add(_DayState(
        label: labels[i],
        date: d,
        eligible: eligible,
        completed: false,
        hasActivity: false, // (NEW)
        isCurrent: d.year == today.year && d.month == today.month && d.day == today.day,
      ));
    }
    return out;
  }

  // ===================== HELPERS =====================

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) {
    // Mon=1 ... Sun=7
    final wd = d.weekday;
    return _dateOnly(d.subtract(Duration(days: wd - 1)));
  }

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // (NEW) Poin per level (sesuai catatanmu)
  int _pointsForLevel(String levelName) {
    switch (levelName) {
      case 'Silver': return 50;
      case 'Gold':   return 40;
      case 'Bronze':
      default:       return 60;
    }
  }

  // (NEW) daftar 5 misi
  List<_MissionDef> _missions(String levelName) {
    final p = _pointsForLevel(levelName);
    return [
      _MissionDef(
        key: 'checkin',
        title: 'Check-in harian.',
        icon: Icons.calendar_today_outlined,
        points: p,
      ),
      _MissionDef(
        key: 'record_paper',
        title: 'Rekam pembuangan sampah kertas pada tempatnya.',
        icon: Icons.camera_roll_outlined,
        points: p,
      ),
      _MissionDef(
        key: 'record_leaves',
        title: 'Rekam pembuangan sampah daun pada tempatnya.',
        icon: Icons.camera_roll_outlined,
        points: p,
      ),
      _MissionDef(
        key: 'record_plastic_bottle',
        title: 'Rekam pembuangan sampah botol plastik pada tempatnya.',
        icon: Icons.camera_roll_outlined,
        points: p,
      ),
      _MissionDef(
        key: 'record_can',
        title: 'Rekam pembuangan sampah kaleng minuman pada tempatnya.',
        icon: Icons.camera_roll_outlined,
        points: p,
      ),
    ];
  }

  // (NEW) tema warna kartu per level (biar nuansanya tetap)
  _LevelTheme _themeForLevel(String levelName) {
    switch (levelName) {
      case 'Silver':
        return _LevelTheme(
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          buttonBgColor: AppColors.rewardCardBg,
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        );
      case 'Gold':
        return _LevelTheme(
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          buttonBgColor: AppColors.lightSageGreen,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        );
      case 'Bronze':
      default:
        return _LevelTheme(
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        );
    }
  }

  // (NEW) helper: sudah ada baris misi ini (hari ini)?
  Future<bool> _alreadyCompletedToday(String missionKey) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return false;
    final today = _dateOnly(DateTime.now());

    try {
      final row = await client
          .from('mission_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('mission_date', _yyyyMmDd(today))
          .eq('status', 'completed:$missionKey')
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  // (NEW) Selesaikan misi (testing: langsung completed + poin masuk)
  Future<void> _completeMission(_MissionDef m, int points) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _showTopToast('Silakan login terlebih dahulu.', bg: Colors.red);
      return;
    }

    final today = _dateOnly(DateTime.now());
    final dateStr = _yyyyMmDd(today);
    final statusStr = 'completed:${m.key}'; // encode key misi ke kolom status

    try {
      // 1) idempotent: kalau sudah completed hari ini -> jangan double poin
      if (await _alreadyCompletedToday(m.key)) {
        setState(() => _completedMissionKeys.add(m.key));
        _showTopToast('Tugas sudah selesai hari ini.');
        return;
      }

      // 2) insert ke mission_history (sesuai skema yang kamu kirim)
      await client.from('mission_history').insert({
        'user_id': user.id,
        'mission_date': dateStr,
        'status': statusStr,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // 3) update score user (simple add)
      final prof = await client
          .from('profiles')
          .select('score')
          .eq('id', user.id)
          .maybeSingle();
      final cur = (prof?['score'] as int?) ?? 0;
      await client.from('profiles').update({'score': cur + points}).eq('id', user.id);

      // 4) refresh UI
      setState(() {
        _completedMissionKeys.add(m.key);
        _profileData = _loadProfileAndLevelInfo();
        _dailyRow = _loadDailyRowData();
      });

      _showTopToast('Tugas selesai: +$points poin'); // (NEW) toast di atas
    } catch (e) {
      debugPrint('completeMission err: $e');
      // (PERBAIKAN) check-in wajib berhasil: kalau insert gagal, setel UI selesai
      if (m.key == 'checkin') {
        setState(() {
          _completedMissionKeys.add(m.key);
          _profileData = _loadProfileAndLevelInfo();
          _dailyRow = _loadDailyRowData();
        });
        _showTopToast('Check-in dicatat (mode uji).');
      } else {
        // error lain
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyelesaikan tugas. Coba lagi.')),
        );
      }
    }
  }

  // ===================== UI ROOT =====================

  Widget _buildRoot(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            FutureBuilder<Map<String, dynamic>>(
              future: _profileData,
              builder: (context, snapshot) {
                final levelName =
                    snapshot.data?['level_name'] as String? ?? 'Bronze';
                return _buildMissionsSection(levelName: levelName);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===================== UI: Header & Profile Card =====================

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/images/reward_header.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 250,
              child: Center(child: Text('Gagal memuat gambar header.')),
            );
          },
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildProfileCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.rewardWhiteTransparent.withAlpha((255 * 0.5).round()),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.rewardCardBorder, width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.rewardCardBorder),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Text(
          "Eco Reward",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Opacity(
          opacity: 0,
          child: IconButton(onPressed: null, icon: Icon(Icons.arrow_back)),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildProfileCardPlaceholder();

        final data = snapshot.data!;
        final name = data['name'] as String;
        final score = data['score'] as int;
        final levelName = data['level_name'] as String;
        final progressText = data['progress_text'] as String;
        final progressValue = data['progress_value'] as double;

        Color iconBgColor;
        switch (levelName) {
          case 'Silver': iconBgColor = Colors.grey.shade500; break;
          case 'Gold':   iconBgColor = Colors.amber.shade700; break;
          case 'Bronze':
          default:       iconBgColor = Colors.brown.shade400;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.rewardCardBg.withAlpha((255 * 0.85).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.rewardCardBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconBgColor,
                      child: const Icon(Icons.star, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level $levelName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.deepForestGreen,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Riwayat',
                            style: TextStyle(
                              color: AppColors.darkMossGreen,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.darkMossGreen),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepForestGreen,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.rewardGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      score.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepForestGreen,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.white.withAlpha((255 * 0.5).round()),
                  color: AppColors.rewardGreenPrimary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  progressText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkMossGreen,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCardPlaceholder() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.deepForestGreen),
        ),
      ),
    );
  }

  // ===================== UI: Missions Section =====================

  Widget _buildMissionsSection({required String levelName}) {
    Color missionsBgColor;
    int selectedLevelIndex;

    if (levelName == 'Silver') {
      missionsBgColor = AppColors.rewardCardBg;
      selectedLevelIndex = 1;
    } else if (levelName == 'Gold') {
      missionsBgColor = AppColors.lightSageGreen;
      selectedLevelIndex = 2;
    } else {
      missionsBgColor = AppColors.mossGreen;
      selectedLevelIndex = 0;
    }

    final theme = _themeForLevel(levelName);
    final missions = _missions(levelName);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/reward_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDailyCheckInSection(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: missionsBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildLevelTabs(selectedLevelIndex),
                  const SizedBox(height: 20),
                  // (NEW) 5 misi unified
                  ...missions.map((m) {
                    final isDone = _completedMissionKeys.contains(m.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MissionCard(
                        iconData: m.icon,
                        title: m.title,
                        points: '+${m.points} poin',
                        cardColor: theme.cardColor,
                        iconAndTextColor: theme.iconAndTextColor,
                        buttonBgColor: theme.buttonBgColor,
                        iconBgColor: theme.iconBgColor,
                        iconBorderColor: theme.iconBorderColor,
                        pointsBorderColor: theme.pointsBorderColor,
                        pointsTextColor: theme.pointsTextColor,
                        titleColor: theme.titleColor,
                        // (NEW) interaksi tombol: langsung selesai
                        buttonText: isDone ? 'Selesai' : 'Mulai',
                        isCompleted: isDone,
                        onPressed: isDone ? null : () => _completeMission(m, m.points),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TUGAS HARIAN (UI) ----------------

  Widget _buildDailyCheckInSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.rewardGreenPrimary),
              ),
              child: const Text(
                'Tugas Harian',
                style: TextStyle(
                  color: AppColors.rewardGreenPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.rewardGreenPrimary),
              ),
              child: Text(
                _formattedDate,
                style: const TextStyle(
                  color: AppColors.rewardGreenPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<_DayState>>(
          future: _dailyRow,
          builder: (context, snap) {
            final days = snap.data;
            if (days == null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.rewardGreenPrimary),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.rewardGreenPrimary,
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.rewardGreenPrimary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days
                    .map((d) => _buildDayItem(
                          day: d.label,
                          eligible: d.eligible,
                          isCompleted: d.completed,
                          hasActivity: d.hasActivity, // (NEW)
                          isCurrent: d.isCurrent,
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayItem({
    required String day,
    required bool eligible,
    required bool isCompleted,
    required bool hasActivity, // (NEW)
    required bool isCurrent,
  }) {
    // (PERBAIKAN) sesuai mock:
    // - !eligible: bulat abu-abu kosong
    // - isCurrent && !isCompleted: border hijau + ikon uang pudar
    // - eligible & (isCompleted || hasActivity): koin kuning
    // - eligible & !isCurrent & !hasActivity: X merah (kosong)
    final bool isProgress = eligible && isCurrent && !isCompleted;

    Widget? inner;
    if (!eligible) {
      inner = null;
    } else if (isProgress) {
      inner = Icon(Icons.attach_money,
          color: AppColors.rewardGreenPrimary.withOpacity(0.35), size: 22);
    } else if (isCompleted || hasActivity) {
      inner = Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 24);
    } else {
      inner = const Icon(Icons.cancel, color: Colors.red, size: 24);
    }

    final borderColor =
        (isProgress || isCurrent) ? AppColors.rewardGreenPrimary : Colors.grey.shade400;
    final borderWidth = (isProgress || isCurrent) ? 2.0 : 1.0;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: eligible ? borderColor : Colors.grey.shade300,
              width: borderWidth,
            ),
          ),
          child: inner,
        ),
        const SizedBox(height: 4),
        Text(day, style: const TextStyle(fontSize: 12, fontFamily: 'Roboto')),
      ],
    );
  }

  // ------------------ Level tabs & missions ------------------

  Widget _buildLevelTabs(int selectedLevelIndex) {
    final levelsData = [
      {'name': 'Bronze', 'color': AppColors.lightSageGreen, 'iconColor': Colors.brown.shade400},
      {'name': 'Silver', 'color': AppColors.oliveGreen, 'iconColor': Colors.grey.shade500},
      {'name': 'Gold', 'color': AppColors.mossGreen, 'iconColor': Colors.amber.shade700},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.1).round()), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(levelsData.length, (index) {
          final isSelected = selectedLevelIndex == index;
          final level = levelsData[index];
          return Expanded(
            child: GestureDetector(
              onTap: null, // tidak bisa pindah manual
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? (level['color'] as Color) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars,
                      color: isSelected && level['name'] == 'Bronze'
                          ? AppColors.black
                          : isSelected
                              ? AppColors.white
                              : (level['iconColor'] as Color),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level['name'] as String,
                      style: TextStyle(
                        color: isSelected && level['name'] == 'Bronze'
                            ? AppColors.black
                            : isSelected
                                ? AppColors.white
                                : AppColors.darkMossGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ===================== Model kecil untuk state hari =====================

class _DayState {
  final String label;
  final DateTime date;
  final bool eligible;    // false = sebelum akun dibuat ATAU setelah hari ini -> abu-abu kosong
  final bool completed;   // true = ada mission_history dengan status sukses
  final bool hasActivity; // (NEW) true = ada baris mission_history apapun
  final bool isCurrent;   // true = hari ini -> border hijau

  _DayState({
    required this.label,
    required this.date,
    required this.eligible,
    required this.completed,
    required this.hasActivity, // (NEW)
    required this.isCurrent,
  });
}

// ===================== Model & Theme bantuan (NEW) =====================

class _MissionDef {
  final String key;
  final String title;
  final IconData icon;
  final int points;
  _MissionDef({
    required this.key,
    required this.title,
    required this.icon,
    required this.points,
  });
}

class _LevelTheme {
  final Color cardColor;
  final Color iconAndTextColor;
  final Color buttonBgColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color pointsBorderColor;
  final Color pointsTextColor;
  final Color titleColor;
  _LevelTheme({
    required this.cardColor,
    required this.iconAndTextColor,
    required this.buttonBgColor,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.pointsBorderColor,
    required this.pointsTextColor,
    required this.titleColor,
  });
}
