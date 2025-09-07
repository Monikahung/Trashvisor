import 'package:flutter/material.dart';
// Ganti 'trashvisor' dengan nama proyek Anda jika berbeda
import 'package:trashvisor/core/colors.dart';

class RewardPageV2 extends StatefulWidget {
  const RewardPageV2({super.key});

  @override
  State<RewardPageV2> createState() => _RewardPageV2State();
}

class _RewardPageV2State extends State<RewardPageV2> {
  int _selectedLevelIndex = 0; // 0: Bronze, 1: Silver, 2: Gold

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan AppColors untuk warna latar belakang utama
      backgroundColor: AppColors.rewardGreenPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Memanggil fungsi-fungsi bantuan yang ada di dalam class ini
            _buildHeaderSection(),
            _buildMissionsSection(),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // BAGIAN 1: FUNGSI-FUNGSI BANTUAN UNTUK HEADER
  // Semua fungsi ini harus berada di dalam class _RewardPageV2State
  // =======================================================================

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/images/reward_background.png', // PASTIKAN PATH ASET INI BENAR
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildDailyCheckInSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Row(
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
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.rewardWhiteTransparent,
        borderRadius: BorderRadius.circular(20),
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
                backgroundColor: AppColors.rewardGreenPrimary,
                child: Icon(Icons.star, color: AppColors.rewardGold),
              ),
              const SizedBox(width: 8),
              const Text('Level Bronze', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Riwayat >', style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Udin Budiono', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Image.asset('assets/images/coin.png', width: 24, height: 24), // PASTIKAN PATH ASET INI BENAR
              const SizedBox(width: 8),
              const Text('1,771', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(value: 0.7, backgroundColor: Colors.grey, color: AppColors.rewardGold),
          const SizedBox(height: 4),
          const Text('-231 points menuju level Silver', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
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
          children: const [
            Text('Tugas Harian', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Sabtu, 23 - 08 - 2025', style: TextStyle(color: AppColors.white, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
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
      ],
    );
  }

  Widget _buildDayItem({required String day, required String points, required bool isCompleted, required bool isCurrent}) {
    return Column(
      children: [
        Text(points, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.rewardGold : AppColors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: isCompleted ? AppColors.rewardGold : AppColors.white.withOpacity(0.5)),
          ),
          child: Image.asset(
            'assets/images/coin.png', // PASTIKAN PATH ASET INI BENAR
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(day.substring(0, 3), style: const TextStyle(color: AppColors.white, fontSize: 12)),
      ],
    );
  }

  // =======================================================================
  // BAGIAN 2: FUNGSI-FUNGSI BANTUAN UNTUK MISI
  // =======================================================================

  Widget _buildMissionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.rewardGreenPrimary,
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
    );
  }

  Widget _buildLevelTabs() {
    final levels = ['Bronze', 'Silver', 'Gold'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.rewardGreenCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(levels.length, (index) {
          final bool isSelected = _selectedLevelIndex == index;
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
              // PERBAIKAN ERROR TEXT KOSONG
              child: Text(
                levels[index],
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBronzeMissions() {
    return Column(
      children: const [
        MissionCard(
          iconData: Icons.calendar_today,
          title: 'Check-in harian selama 3 hari',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.camera_alt,
          title: 'Gunakan Trash Vision sebanyak 1x',
          points: '+25 px',
        ),
        SizedBox(height: 12),
        MissionCard(
          iconData: Icons.chat,
          title: 'Gunakan Chatbot AI sebanyak 1x',
          points: '+25 px',
        ),
      ],
    );
  }

  Widget _buildSilverMissions() => const Center(child: Text('Tugas Silver akan muncul di sini', style: TextStyle(color: AppColors.white)));
  Widget _buildGoldMissions() => const Center(child: Text('Tugas Gold akan muncul di sini', style: TextStyle(color: AppColors.white)));
} // <-- BATAS AKHIR DARI CLASS _RewardPageV2State


// =======================================================================
// WIDGET REUSABLE: KARTU MISI (PASTIKAN ADA DI LUAR CLASS _RewardPageV2State)
// =======================================================================
class MissionCard extends StatelessWidget {
  // PERBAIKAN: MENDEFINISIKAN PROPERTI
  final IconData iconData;
  final String title;
  final String points;

  // PERBAIKAN: MENAMBAHKAN CONSTRUCTOR
  const MissionCard({
    super.key,
    required this.iconData,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
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
            // Variabel 'iconData' sekarang sudah dikenali
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
                      Image.asset('assets/images/coin.png', width: 14, height: 14), // PASTIKAN PATH ASET INI BENAR
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