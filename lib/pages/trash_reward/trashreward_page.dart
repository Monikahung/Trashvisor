import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';
import 'widgets/mission_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart';
import 'scan_video.dart';
import 'history_page.dart';
import '../../main.dart';
import 'quiz_page.dart';

class EcoRewardPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const EcoRewardPage({super.key, required this.cameras});

  @override
  State<EcoRewardPage> createState() => _EcoRewardPageState();
}

class _EcoRewardPageState extends State<EcoRewardPage>
    with RouteAware, SingleTickerProviderStateMixin {
  String _formattedDate = '';
  final Map<String, bool> _processingMissions = {};
  final Set<String> _claimableMissions = {};
  final Set<String> _completedMissionKeys = {};
  final Set<String> _failedMissionKeys = {};
  final Map<String, String> _failedRowIdByKey = {};
  final Map<String, bool> _busy = {'checkin': false};
  final List<Map<String, dynamic>> _levelThresholds = const [
    {'name': 'Bronze', 'min_score': 0, 'max_score': 1000},
    {'name': 'Silver', 'min_score': 1000, 'max_score': 3000},
    {'name': 'Gold', 'min_score': 3000, 'max_score': 6000},
  ];

  late Future<Map<String, dynamic>> _profileData;
  late Future<List<_DayState>> _dailyRow;
  late final AnimationController _toastCtl;
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;
  String _toastMsg = '';
  late final RealtimeChannel _channel;

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

    unawaited(_fetchData());
    final client = Supabase.instance.client;
    _channel = client
        .channel('public:mission_history')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'mission_history',
      callback: (payload) {
        _fetchData();
      },
    )
        .subscribe();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _fetchData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _toastTimer?.cancel();
    _toastCtl.dispose();
    _toastEntry?.remove();
    _toastEntry = null;
    _channel.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _profileData = _loadProfileAndLevelInfo();
      _dailyRow = _loadDailyRowData();
    });
    await _fetchMissionHistory();
    await _prefetchCompletedToday();
  }

  Future<void> _fetchMissionHistory() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final today = _yyyyMmDd(_dateOnly(DateTime.now()));
      final rows = await client
          .from('mission_history')
          .select('id,status')
          .eq('user_id', user.id)
          .eq('mission_date', today)
          .order('created_at', ascending: false);

      _processingMissions.clear();
      _claimableMissions.clear();
      _completedMissionKeys.clear();
      _failedMissionKeys.clear();
      _failedRowIdByKey.clear();

      for (final r in rows) {
        final rawStatus = (r['status'] ?? '').toString();
        if (!rawStatus.contains(':')) continue;

        final idx = rawStatus.indexOf(':');
        final state = rawStatus.substring(0, idx).toLowerCase();
        final missionKey = rawStatus.substring(idx + 1);
        final rowId = (r['id'] ?? '').toString();

        if (missionKey.isEmpty) continue;

        switch (state) {
          case 'processing':
            _processingMissions[missionKey] = true;
            break;
          case 'completed':
          case 'valid':
          case 'claim':
            _claimableMissions.add(missionKey);
            break;
          case 'claimed':
          case 'complete':
            _completedMissionKeys.add(missionKey);
            break;
          case 'failed':
            _failedMissionKeys.add(missionKey);
            _failedRowIdByKey.putIfAbsent(missionKey, () => rowId);
            break;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching mission history: $e');
    }
  }

  Future<bool> _claimReward(_MissionDef m) async {
    if (_busy[m.key] == true) return false;
    _busy[m.key] = true;
    setState(() {});

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _busy[m.key] = false;
      setState(() {});
      return false;
    }

    final ok = await client.rpc(
      'claim_mission',
      params: {
        'p_user_id': user.id,
        'p_date': _yyyyMmDd(_dateOnly(DateTime.now())),
        'p_key': m.key,
        'p_points': m.points,
      },
    ) as bool? ??
        false;

    _busy[m.key] = false;

    if (!mounted) return ok;
    if (ok) {
      setState(() {
        _claimableMissions.remove(m.key);
        _completedMissionKeys.add(m.key);
        _profileData = _loadProfileAndLevelInfo();
      });
      _showTopToast('Berhasil mengklaim ${m.points} poin!',
          bg: AppColors.rewardGreenPrimary);
    } else {
      _showTopToast('Belum siap diklaim.', bg: Colors.orange);
    }
    return ok;
  }

  Future<void> _autoClaimCheckin(_MissionDef m) async {
    if (_busy['checkin'] == true) return;
    _busy['checkin'] = true;
    setState(() {});

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _showTopToast('Silakan login terlebih dahulu.', bg: Colors.red);
      _busy['checkin'] = false;
      setState(() {});
      return;
    }

    final ok = await client.rpc(
      'checkin_claim',
      params: {
        'p_user_id': user.id,
        'p_date': _yyyyMmDd(_dateOnly(DateTime.now())),
        'p_points': m.points,
      },
    ) as bool? ??
        false;

    _busy['checkin'] = false;

    if (!mounted) return;
    if (ok) {
      setState(() {
        _completedMissionKeys.add(m.key);
        _profileData = _loadProfileAndLevelInfo();
        _dailyRow = _loadDailyRowData();
      });
      _showTopToast('Check-in berhasil: +${m.points} poin');
    } else {
      _showTopToast('Check-in belum dapat diproses.', bg: Colors.orange);
    }
  }

  Future<void> _prefetchCompletedToday() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final today = _yyyyMmDd(_dateOnly(DateTime.now()));
    try {
      final rows = await client
          .from('mission_history')
          .select('status')
          .eq('user_id', user.id)
          .eq('mission_date', today);

      final keys = <String>{};
      for (final r in rows) {
        final s = (r['status'] ?? '').toString();
        if (s.startsWith('claimed:')) keys.add(s.split(':').last);
      }

      if (keys.isNotEmpty) {
        setState(() {
          _completedMissionKeys
            ..clear()
            ..addAll(keys);
        });
      }
    } catch (e) {
      debugPrint('prefetchCompletedToday err: $e');
    }
  }

  void _showTopToast(String message,
      {Color bg = AppColors.fernGreen, Color fg = Colors.white}) {
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _toastMsg,
                          style: TextStyle(
                            color: fg,
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
      Overlay.of(context).insert(_toastEntry!);
    } else {
      _toastEntry!.markNeedsBuild();
    }

    _toastCtl.forward(from: 0);
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      _toastCtl.reverse();
    });
  }

  Future<void> _initializeDate() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      _formattedDate =
          DateFormat('EEEE, dd - MM - yyyy', 'id_ID').format(DateTime.now());
    });
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _mondayOf(DateTime d) {
    final wd = d.weekday;
    return _dateOnly(d.subtract(Duration(days: wd - 1)));
  }

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _pointsForLevel(String levelName) {
    switch (levelName) {
      case 'Silver':
        return 50;
      case 'Gold':
        return 40;
      case 'Bronze':
      default:
        return 60;
    }
  }

  List<_MissionDef> _missions(String levelName) {
    final p = _pointsForLevel(levelName);
    return [
      _MissionDef(
          key: 'checkin',
          title: 'Check-in harian',
          icon: Icons.calendar_today_outlined,
          points: p),
      _MissionDef(
          key: 'record_paper',
          title: 'Rekam pembuangan sampah kertas pada tempatnya',
          icon: Icons.camera_roll_outlined,
          points: p),
      _MissionDef(
          key: 'record_leaves',
          title: 'Rekam pembuangan sampah daun pada tempatnya',
          icon: Icons.camera_roll_outlined,
          points: p),
      _MissionDef(
          key: 'record_plastic_bottle',
          title: 'Rekam pembuangan sampah botol plastik pada tempatnya',
          icon: Icons.camera_roll_outlined,
          points: p),
      _MissionDef(
          key: 'record_can',
          title: 'Rekam pembuangan sampah kaleng minuman pada tempatnya',
          icon: Icons.camera_roll_outlined,
          points: p),
      _MissionDef(
          key: 'quiz',
          title: 'Uji Pengetahuan Sampahmu!',
          icon: Icons.quiz_outlined,
          points: 100),
    ];
  }

  String _getMissionType(String missionKey) {
    switch (missionKey) {
      case 'record_paper':
        return 'paper';
      case 'record_leaves':
        return 'leaf';
      case 'record_plastic_bottle':
        return 'plastic_bottle';
      case 'record_can':
        return 'drink_cans';
      default:
        return '';
    }
  }

  _LevelTheme _themeForLevel(String levelName) {
    switch (levelName) {
      case 'Silver':
        return _LevelTheme(
          cardColor: AppColors.oliveGreen,
          iconAndTextColor:
          AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          buttonBgColor: AppColors.rewardCardBg,
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor:
          AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
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

  @override
  Widget build(BuildContext context) => _buildRoot(context);

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

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/images/features/top_reward.png',
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
            color:
            AppColors.rewardWhiteTransparent.withAlpha((255 * 0.5).round()),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.rewardCardBorder, width: 1),
          ),
          child: IconButton(
            icon:
            const Icon(Icons.arrow_back, color: AppColors.rewardCardBorder),
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
          case 'Silver':
            iconBgColor = Colors.grey.shade500;
            break;
          case 'Gold':
            iconBgColor = Colors.amber.shade700;
            break;
          case 'Bronze':
          default:
            iconBgColor = Colors.brown.shade400;
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
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MissionHistoryPage()),
                        );
                        if (!mounted) return;
                        await _fetchData();
                      },
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
                    ),
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
                  color: AppColors.fernGreen,
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
          child: CircularProgressIndicator(color: AppColors.whiteSmoke),
        ),
      ),
    );
  }

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
          image: AssetImage('assets/images/bg/bg_reward.png'),
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
                  ...missions.map((m) {
                    final isDone = _completedMissionKeys.contains(m.key);
                    final isProcessing = _processingMissions[m.key] ?? false;
                    final isClaimable = _claimableMissions.contains(m.key);
                    final isFailed = _failedMissionKeys.contains(m.key);
                    final isBusy = _busy[m.key] == true;

                    VoidCallback? onPressedAction;
                    String buttonText;

                    if (isDone) {
                      buttonText = 'Selesai';
                      onPressedAction = null;
                    } else if (isClaimable) {
                      buttonText = isBusy ? '...' : 'Klaim';
                      onPressedAction = isBusy
                          ? null
                          : () async {
                        final ok = await _claimReward(m);
                        if (!ok) return;
                        await _fetchData();
                      };
                    } else if (isProcessing) {
                      buttonText = 'Proses';
                      onPressedAction = null;
                    } else if (isFailed) {
                      buttonText = 'Ulangi';
                      onPressedAction = () async {
                        final reuseId = _failedRowIdByKey[m.key];
                        final navContext = context;
                        final popResult = await Navigator.push(
                          navContext,
                          MaterialPageRoute(
                            builder: (_) => ScanVideo(
                              cameras: widget.cameras,
                              missionKey: m.key,
                              missionType: _getMissionType(m.key),
                              reuseRowId: reuseId,
                              onValidationComplete: (bool _) async {
                                if (!mounted) return;
                                await _fetchData();
                              },
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (popResult == true) {
                          setState(() {
                            _failedMissionKeys.remove(m.key);
                            _processingMissions[m.key] = true;
                          });
                        }
                        unawaited(_fetchMissionHistory());
                      };
                    } else {
                      if (m.key == 'quiz') {
                        buttonText = 'Mulai';
                        onPressedAction = () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const QuizPage()),
                          );
                          if (result == true && mounted) {
                            _fetchData();
                          }
                        };
                      } else if (m.key == 'checkin') {
                        buttonText =
                        _busy['checkin'] == true ? '...' : 'Klaim';
                        onPressedAction = _busy['checkin'] == true
                            ? null
                            : () => _autoClaimCheckin(m);
                      } else {
                        buttonText = 'Mulai';
                        onPressedAction = () async {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            _showTopToast('Silakan login terlebih dahulu.',
                                bg: Colors.red);
                            return;
                          }
                          final navContext = context;
                          final popResult = await Navigator.push(
                            navContext,
                            MaterialPageRoute(
                              builder: (_) => ScanVideo(
                                cameras: widget.cameras,
                                missionKey: m.key,
                                missionType: _getMissionType(m.key),
                                reuseRowId: null,
                                onValidationComplete: (bool _) async {
                                  if (!mounted) return;
                                  await _fetchData();
                                },
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (popResult == true) {
                            setState(() {
                              _failedMissionKeys.remove(m.key);
                              _processingMissions[m.key] = true;
                            });
                          }
                          unawaited(_fetchMissionHistory());
                        };
                      }
                    }

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
                        buttonText: buttonText,
                        isCompleted: isDone,
                        onPressed: onPressedAction,
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
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
                        strokeWidth: 2.4, color: AppColors.fernGreen),
                  ),
                ),
              );
            }

            return Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
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
                  hasActivity: d.hasActivity,
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
    required bool hasActivity,
    required bool isCurrent,
  }) {
    final bool isProgress = eligible && isCurrent && !isCompleted;

    Widget? inner;
    if (!eligible) {
      inner = null;
    } else if (isProgress) {
      inner = Icon(
        Icons.attach_money,
        color: AppColors.rewardGreenPrimary.withAlpha((255 * 0.35).round()),
        size: 22,
      );
    } else if (isCompleted || hasActivity) {
      inner =
          Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 24);
    } else {
      inner = const Icon(Icons.cancel, color: Colors.red, size: 24);
    }

    final borderColor = (isProgress || isCurrent)
        ? AppColors.rewardGreenPrimary
        : Colors.grey.shade400;
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

  Widget _buildLevelTabs(int selectedLevelIndex) {
    final levelsData = [
      {
        'name': 'Bronze',
        'color': AppColors.lightSageGreen,
        'iconColor': Colors.brown.shade400,
      },
      {
        'name': 'Silver',
        'color': AppColors.oliveGreen,
        'iconColor': Colors.grey.shade500,
      },
      {
        'name': 'Gold',
        'color': AppColors.mossGreen,
        'iconColor': Colors.amber.shade700,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 5)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(levelsData.length, (index) {
          final isSelected = selectedLevelIndex == index;
          final level = levelsData[index];
          return Expanded(
            child: GestureDetector(
              onTap: null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (level['color'] as Color)
                      : Colors.transparent,
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

      if (row == null) throw Exception('User profile not found.');

      final fullNameFromRow = (row['full_name'] as String?)?.trim();
      final fullName =
      (fullNameFromRow != null && fullNameFromRow.isNotEmpty)
          ? fullNameFromRow
          : (user.email?.split('@').first ?? 'Pengguna');

      final score = (row['score'] as num?)?.toInt() ?? 0;

      final currentLevel = _levelThresholds.firstWhere(
            (l) =>
        score >= (l['min_score'] as int) &&
            score < (l['max_score'] as int),
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
        progressText =
        '${nextMin - score} poin menuju level ${next['name']}';
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

  Future<List<_DayState>> _loadDailyRowData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final today = _dateOnly(DateTime.now());

    if (user == null) {
      return _weekSkeleton(today, today);
    }

    DateTime createdAt = today;
    try {
      final prof = await client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (prof != null && prof['created_at'] != null) {
        createdAt =
            _dateOnly(DateTime.parse(prof['created_at'].toString()));
      }
    } catch (_) {}

    final monday = _mondayOf(today);
    final sunday = monday.add(const Duration(days: 6));

    final Set<DateTime> successDays = {};
    final Set<DateTime> activityDays = {};
    try {
      final rows = await client
          .from('mission_history')
          .select('mission_date,status')
          .eq('user_id', user.id)
          .gte('mission_date', _yyyyMmDd(monday))
          .lte('mission_date', _yyyyMmDd(sunday));

      for (final r in rows) {
        final dStr = r['mission_date'];
        if (dStr == null) continue;
        final d = _dateOnly(DateTime.parse(dStr.toString()));
        activityDays.add(d);

        final status = (r['status'] ?? '').toString().toLowerCase();
        final ok = [
          'claimed', // sukses mingguan = sudah diklaim
          'done',
          'finish',
        ].any((k) => status.startsWith(k));
        if (ok) successDays.add(d);
      }
    } catch (e) {
      debugPrint('err load mission_history: $e');
    }

    final labels = const [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<_DayState> result = [];
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final eligible = !(beforeCreated || inFuture);
      final isCompleted = eligible && successDays.contains(d);
      final hasActivity = eligible && activityDays.contains(d);
      final isCurrent = d == today;
      result.add(
        _DayState(
          label: labels[i],
          date: d,
          eligible: eligible,
          completed: isCompleted,
          hasActivity: hasActivity,
          isCurrent: isCurrent,
        ),
      );
    }
    return result;
  }

  List<_DayState> _weekSkeleton(DateTime createdAt, DateTime today) {
    final monday = _mondayOf(today);
    final labels = const [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final List<_DayState> out = [];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      final beforeCreated = d.isBefore(createdAt);
      final inFuture = d.isAfter(today);
      final eligible = !(beforeCreated || inFuture);
      out.add(
        _DayState(
          label: labels[i],
          date: d,
          eligible: eligible,
          completed: false,
          hasActivity: false,
          isCurrent: d.year == today.year &&
              d.month == today.month &&
              d.day == today.day,
        ),
      );
    }
    return out;
  }
}

class _DayState {
  final String label;
  final DateTime date;
  final bool eligible;
  final bool completed;
  final bool hasActivity;
  final bool isCurrent;

  _DayState({
    required this.label,
    required this.date,
    required this.eligible,
    required this.completed,
    required this.hasActivity,
    required this.isCurrent,
  });
}

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