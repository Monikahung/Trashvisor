import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

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
          'assets/images/reward_header.png',
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
            color: AppColors.rewardWhiteTransparent.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
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
      padding: const EdgeInsets.symmetric(horizontal:35.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.rewardCardBg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.rewardCardBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepForestGreen),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () { /* Navigasi ke halaman riwayat */ },
                  child: const Text('Riwayat >', style: TextStyle(color: AppColors.darkMossGreen)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Udin Budiono',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepForestGreen)
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.rewardGold, size: 24),
                const SizedBox(width: 8),
                const Text(
                    '1,771',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepForestGreen)
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Colors.white.withOpacity(0.5),
              color: AppColors.rewardGreenPrimary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
                progressTexts[_selectedLevelIndex],
                style: const TextStyle(fontSize: 12, color: AppColors.darkMossGreen)
            ),
          ],
        ),
      ),
    );
  }

  // Bagian Daftar Misi dengan Latar Belakang Baru
  Widget _buildMissionsSection() {
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
            _buildLevelTabs(),
            const SizedBox(height: 20),
            if (_selectedLevelIndex == 0) _buildBronzeMissions(),
            if (_selectedLevelIndex == 1) _buildSilverMissions(),
            if (_selectedLevelIndex == 2) _buildGoldMissions(),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI TUGAS HARIAN YANG DIPERBARUI ---
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
                points: dayData['points'] as String,
                isCompleted: dayData['completed'] as bool,
                isCurrent: dayData['isCurrent'] as bool,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- FUNGSI ITEM HARI YANG DIPERBARUI ---
  Widget _buildDayItem({required String day, required String points, required bool isCompleted, required bool isCurrent}) {
    bool hasCoin = isCompleted || isCurrent;

    return Column(
      children: [
        Text(points, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
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
              ? Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              'assets/images/reward_coins_icon.png',
            ),
          )
              : null,
        ),
        const SizedBox(height: 4),
        Text(day, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Tab Level
  Widget _buildLevelTabs() {
    final levels = ['Bronze', 'Silver', 'Gold'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(levels.length, (index) {
          final isSelected = _selectedLevelIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLevelIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.rewardGreenLight : AppColors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                levels[index],
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.darkMossGreen,
                  fontWeight: FontWeight.bold,
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
      children: const [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian selama 3 hari',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 1x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Gunakan Chatbot AI sebanyak 1x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Cek Trash Location sebanyak 1x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan Menu TrashTime Capsule sebanyak 1x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.eco_outlined,
          title: 'Foto sampah organik',
          points: '+25 px',
        ),
      ],
    );
  }

  // Daftar Misi untuk Level Silver
  Widget _buildSilverMissions() {
    return Column(
      children: const [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian selama 3 hari',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 3x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Gunakan Chatbot AI sebanyak 3x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Cek Trash Location sebanyak 3x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan Menu TrashTime Capsule sebanyak 3x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.eco_outlined,
          title: 'Foto 1 jenis sampah anorganik',
          points: '+25 px',
        ),
      ],
    );
  }

  // Daftar Misi untuk Level Gold
  Widget _buildGoldMissions() {
    return Column(
      children: const [
        MissionCard(
          iconData: Icons.calendar_today_outlined,
          title: 'Check-in harian selama 7 hari',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt_outlined,
          title: 'Gunakan Trash Vision sebanyak 5x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat_bubble_outline,
          title: 'Gunakan Chatbot AI sebanyak 7x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.location_on_outlined,
          title: 'Gunakan menu Geolokasi untuk mengetahui TPS terdekat',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.timelapse_outlined,
          title: 'Gunakan TrashTime Capsule sebanyak 5x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_roll_outlined,
          title: 'Rekam membuang sampah pada tempatnya',
          points: '+25 px',
        ),
      ],
    );
  }
}

// Widget Terpisah untuk Kartu Misi
class MissionCard extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String points;

  const MissionCard({
    super.key,
    required this.iconData,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // ... (kode ini tidak berubah)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rewardGreenCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.rewardGreenPrimary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rewardGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.rewardGold, size: 14),
                      const SizedBox(width: 4),
                      Text(points, style: const TextStyle(color: AppColors.rewardGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rewardGreenLight,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
  }
}