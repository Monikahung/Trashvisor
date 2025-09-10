import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';
import 'widgets/mission_card.dart';

class EcoRewardPage extends StatefulWidget {
  const EcoRewardPage({super.key});

  @override
  State<EcoRewardPage> createState() => _EcoRewardPageState();
}

class _EcoRewardPageState extends State<EcoRewardPage> {
  final List<Map<String, dynamic>> _levelThresholds = [
    {'name': 'Bronze', 'min_score': 0, 'max_score': 1000},
    {'name': 'Silver', 'min_score': 1000, 'max_score': 3000},
    {'name': 'Gold', 'min_score': 3000, 'max_score': 6000},
  ];

  // (REVISI) Hapus _selectedLevelIndex
  // int _selectedLevelIndex = 0; // Tidak lagi dibutuhkan

  // (REVISI) Buat variabel untuk menyimpan data profil dan level
  late final Future<Map<String, dynamic>> _profileData;

  @override
  void initState() {
    super.initState();
    // (REVISI) Panggil fungsi _loadProfileAndLevelInfo() di initState
    // untuk mengambil data saat halaman dimuat
    _profileData = _loadProfileAndLevelInfo();
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
          .select('full_name, score') // Cukup ambil full_name dan score
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        throw Exception('User profile not found.');
      }

      final fullName = (row['full_name'] as String?)?.trim() ?? user.email?.split('@').first ?? 'Pengguna';
      final score = row['score'] as int? ?? 0;

      final currentLevel = _levelThresholds.firstWhere(
        (level) => score >= (level['min_score'] as int) && score < (level['max_score'] as int),
        orElse: () => _levelThresholds.last,
      );

      String progressText;
      double progressValue;

      if (currentLevel['name'] == 'Gold') {
        // Logika khusus untuk level Gold
        final goldMinScore = currentLevel['min_score'] as int;
        final goldMaxScore = currentLevel['max_score'] as int;
        final range = goldMaxScore - goldMinScore;
        progressValue = range > 0 ? (score - goldMinScore) / range : 0.0;
        progressText = '${goldMaxScore - score} poin menuju batas akhir';
      } else {
        // Logika untuk level Bronze dan Silver
        final nextLevelIndex = _levelThresholds.indexOf(currentLevel) + 1;
        final nextLevel = _levelThresholds[nextLevelIndex];
        final nextLevelMinScore = nextLevel['min_score'] as int;
        final currentLevelMinScore = currentLevel['min_score'] as int;
        
        final range = nextLevelMinScore - currentLevelMinScore;
        progressValue = range > 0 ? (score - currentLevelMinScore) / range : 1.0;
        progressText = '${nextLevelMinScore - score} poin menuju level ${nextLevel['name']}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            // (REVISI) Tampilkan bagian misi sesuai data dari FutureBuilder
            FutureBuilder<Map<String, dynamic>>(
              future: _profileData,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildMissionsSection(levelName: 'Bronze'); // Default saat loading
                }
                
                final levelName = snapshot.data!['level_name'] as String;
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
          'assets/images/reward_header.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 250,
              child: Center(
                child: Text('Gagal memuat gambar header.'),
              ),
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
            border: Border.all(
              color: AppColors.rewardCardBorder,
              width: 1
            )
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
              fontWeight: FontWeight.bold),
        ),
        Opacity(
          opacity: 0,
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildProfileCardPlaceholder();
        }
        
        final data = snapshot.data!;
        final name = data['name'] as String;
        final score = data['score'] as int;
        final levelName = data['level_name'] as String;
        final progressText = data['progress_text'] as String;
        final progressValue = data['progress_value'] as double;

        // Tentukan warna ikon berdasarkan level
        Color iconBgColor;
        switch (levelName) {
          case 'Bronze':
            iconBgColor = Colors.brown.shade400;
            break;
          case 'Silver':
            iconBgColor = Colors.grey.shade500;
            break;
          case 'Gold':
            iconBgColor = Colors.amber.shade700;
            break;
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
              border: Border.all(
                color: AppColors.rewardCardBorder,
                width: 2,
              ),
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
                      child: Icon(Icons.star, color: Colors.white),
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
                      onPressed: () { /* Navigasi ke halaman riwayat */ },
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
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.darkMossGreen,
                          ),
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
                    )
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.rewardGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                        score.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepForestGreen,
                          fontFamily: 'Roboto',
                        )
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
                    )
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

  // (REVISI) Tambahkan parameter levelName
  Widget _buildMissionsSection({required String levelName}) {
    Color missionsBgColor;
    int selectedLevelIndex;

    if (levelName == 'Bronze') {
      missionsBgColor = AppColors.mossGreen;
      selectedLevelIndex = 0;
    } else if (levelName == 'Silver') {
      missionsBgColor = AppColors.rewardCardBg;
      selectedLevelIndex = 1;
    } else {
      missionsBgColor = AppColors.lightSageGreen;
      selectedLevelIndex = 2;
    }

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
                  _buildLevelTabs(selectedLevelIndex), // (REVISI) Kirim index level ke tab
                  const SizedBox(height: 20),
                  if (selectedLevelIndex == 0) _buildBronzeMissions(),
                  if (selectedLevelIndex == 1) _buildSilverMissions(),
                  if (selectedLevelIndex == 2) _buildGoldMissions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCheckInSection() {
    final days = [
      {'day': 'Senin', 'points': '+10', 'completed': true, 'isCurrent': false},
      {'day': 'Selasa', 'points': '+20', 'completed': true, 'isCurrent': false},
      {'day': 'Rabu', 'points': '+30', 'completed': true, 'isCurrent': false},
      {'day': 'Kamis', 'points': '+40', 'completed': true, 'isCurrent': false},
      {'day': 'Jumat', 'points': '+50', 'completed': false, 'isCurrent': true},
      {'day': 'Sabtu', 'points': '+60', 'completed': false, 'isCurrent': false},
      {'day': 'Minggu', 'points': '+70', 'completed': false, 'isCurrent': false},
    ];

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
              child: const Text(
                'Sabtu, 23 - 08 - 2025',
                style: TextStyle(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.rewardGreenPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((dayData) {
              return _buildDayItem(
                day: dayData['day'] as String,
                isCompleted: dayData['completed'] as bool,
                isCurrent: dayData['isCurrent'] as bool,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem({required String day, required bool isCompleted, required bool isCurrent}) {
    bool hasCoin = isCompleted || isCurrent;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.rewardGreenPrimary : Colors.grey.shade400,
              width: isCurrent ? 2.0 : 1.0,
            ),
          ),
          child: hasCoin
              ? Icon(
            Icons.monetization_on,
            color: isCurrent ? AppColors.white : Colors.amber.shade700,
            size: 24,
          )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  // (REVISI) Menerima parameter selectedLevelIndex
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
              // onTap: () {
              //   setState(() {
              //     _selectedLevelIndex = index;
              //   });
              // },
              // (REVISI) Menonaktifkan onTap agar tidak bisa diubah manual
              onTap: null, 
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

  // Daftar Misi untuk Level Bronze
  Widget _buildBronzeMissions() {
    return Column(
      children: [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian selama 3 hari',
          points: '+50 poin',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 1 kali',
          points: '+70 poin px',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Ajukan pertanyaan ke Trash Chatbot sebanyak 3 kali',
          points: '+60 poin',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Cek Trash Location sebanyak 3 kali',
          points: '+60 poin',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan Trash Capsule sebanyak 1 kali',
          points: '+60 poin',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.eco_outlined,
          title: 'Foto sampah organik',
          points: '+25 px',
          cardColor: AppColors.lightSageGreen,
          iconAndTextColor: AppColors.darkMossGreen,
          buttonBgColor: AppColors.black,
          iconBgColor: AppColors.mossGreen,
          iconBorderColor: AppColors.fernGreen,
          pointsBorderColor: AppColors.fernGreen,
          pointsTextColor: AppColors.black,
          titleColor: AppColors.black,
        ),
      ],
    );
  }

  Widget _buildSilverMissions() {
    return Column(
      children: [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian',
          points: '+50 poin',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 3 kali',
          points: '+80 poin',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Ajukan pertanyaan ke Trash Chatbot sebanyak 5 kali',
          points: '+70 poin',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Cek Trash Location sebanyak 5 kali',
          points: '+70 poin',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan Trash Capsule sebanyak 2 kali',
          points: '+70 point',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.eco_outlined,
          title: 'Deteksi sampah organik dengan Trash Vision',
          points: '+60 poin',
          cardColor: AppColors.oliveGreen,
          iconAndTextColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          iconBgColor: AppColors.rewardCardBg,
          iconBorderColor: AppColors.darkOliveGreen.withAlpha((255 * 0.75).round()),
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
      ],
    );
  }

  Widget _buildGoldMissions() {
    return Column(
      children: [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian',
          points: '+50 poin',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 5 kali',
          points: '+80 poin',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Ajukan pertanyaan ke Trash Chatbot sebanyak 7 kali',
          points: '+70 poin',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Cek Trash Location sebanyak 7 kali',
          points: '+70 point',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan Trash Capsule sebanyak kali',
          points: '+70 poin',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
        const SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_roll_outlined,
          title: 'Rekam membuang sampah daun pada tempatnya',
          points: '+60 poin',
          cardColor: AppColors.mossGreen,
          iconAndTextColor: AppColors.rewardCardIkonBorder,
          iconBgColor: AppColors.lightSageGreen,
          iconBorderColor: AppColors.rewardCardIkonBorder,
          pointsBorderColor: AppColors.lightSageGreen,
          pointsTextColor: AppColors.whiteSmoke,
          titleColor: AppColors.whiteSmoke,
        ),
      ],
    );
  }
}