import 'package:flutter/material.dart';
// Ganti 'trashvisor' dengan nama proyek Anda jika berbeda
import 'package:trashvisor/core/colors.dart';
import 'widgets/mission_card.dart'; // <-- IMPORT WIDGET YANG SUDAH DIPISAH

class EcoRewardPage extends StatefulWidget {
  const EcoRewardPage({super.key});

  @override
  State<EcoRewardPage> createState() => _EcoRewardPageState();
}

class _EcoRewardPageState extends State<EcoRewardPage> {
  int _selectedLevelIndex = 0; // 0: Bronze, 1: Silver, 2: Gold

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildMissionsSection(),
          ],
        ),
      ),
    );
  }

  // Bagian Header dengan Ilustrasi dan Kartu Profil
  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/images/reward_header.png', // Pastikan nama file ini benar
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 250, // Sesuaikan tinggi dengan desain
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

  // App Bar dengan judul statis
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

  // Kartu Profil yang dinamis
  Widget _buildProfileCard() {
    final levels = ["Bronze", "Silver", "Gold"];
    final progressTexts = [
      "-231 points menuju level Silver",
      "-829 points menuju level Gold",
      "Anda sudah mencapai level tertinggi"
    ];

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
                const CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Level ${levels[_selectedLevelIndex]}',
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
                  child: const Text(
                    'Riwayat >',
                    style: TextStyle(
                      color: AppColors.darkMossGreen,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Udin Budiono',
                style: TextStyle(
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
                const Text(
                    '1,771',
                    style: TextStyle(
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
              value: 0.7,
              backgroundColor: Colors.white.withAlpha((255 * 0.5).round()),
              color: AppColors.rewardGreenPrimary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
                progressTexts[_selectedLevelIndex],
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
  }

  // Bagian Daftar Misi dengan Latar Belakang Baru
  Widget _buildMissionsSection() {
    Color missionsBgColor;
    if (_selectedLevelIndex == 0) {
      missionsBgColor = AppColors.mossGreen; // Warna untuk Bronze
    } else if (_selectedLevelIndex == 1) {
      missionsBgColor = AppColors.rewardCardBg; // Warna untuk Silver
    } else {
      missionsBgColor = AppColors.lightSageGreen; // Warna untuk Gold
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
                  _buildLevelTabs(),
                  const SizedBox(height: 20),
                  if (_selectedLevelIndex == 0) _buildBronzeMissions(),
                  if (_selectedLevelIndex == 1) _buildSilverMissions(),
                  if (_selectedLevelIndex == 2) _buildGoldMissions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi Tugas Harian
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

  // Fungsi Item Hari
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

  // Tab Level dengan Warna Dinamis
  Widget _buildLevelTabs() {
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
          final isSelected = _selectedLevelIndex == index;
          final level = levelsData[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLevelIndex = index;
                });
              },
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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

  // Daftar Misi untuk Level Silver
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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

  // Daftar Misi untuk Level Gold
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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
        SizedBox(height: 12),
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