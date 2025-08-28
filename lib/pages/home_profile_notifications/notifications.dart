import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final kSizeRatio = screenWidth / 360;

        return Scaffold(
          backgroundColor: AppColors.avocadoGreen,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60 * kSizeRatio), // tinggi AppBar bisa disesuaikan
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
                  fontSize: 22 * kSizeRatio,
                ),
              ),
              leading: Container(
                margin: EdgeInsets.only(left: 8.0 * kSizeRatio),
                padding: EdgeInsets.all(8.0 * kSizeRatio), // padding di sekitar ikon
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.fernGreen, // warna lingkaran
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.whiteSmoke,
                      size: 24 * kSizeRatio,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0 * kSizeRatio),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10 * kSizeRatio),
                  // Notifikasi belum dibaca
                  _buildNotificationItem(
                    icon: Icons.videocam_outlined,
                    title: 'Rekam video buang sampah berhasil!',
                    subtitle: 'Klaim point anda pada level Gold',
                    time: '1 menit',
                    isRead: false,
                    sizeRatio: kSizeRatio,
                  ),
                  _buildNotificationItem(
                    icon: Icons.location_on_outlined,
                    title: 'TPS terdekat berhasil ditetapkan!',
                    subtitle: 'Cek lebih rinci terkait TPS terdekat',
                    time: '3 jam',
                    isRead: false,
                    sizeRatio: kSizeRatio,
                  ),
                  _buildNotificationItem(
                    icon: Icons.monetization_on_outlined,
                    title: 'Kerjakan task untuk meningkatkan level',
                    subtitle: 'Selesaikan 231 point lagi menuju level silver',
                    time: '14 jam',
                    isRead: false,
                    sizeRatio: kSizeRatio,
                  ),
                  // Notifikasi sudah dibaca
                  _buildNotificationItem(
                    icon: Icons.check_circle_outline,
                    title: 'Berhasil menyelesaikan task 1 Bronze',
                    subtitle: 'Klaim point anda pada level Bronze',
                    time: '5 hari',
                    isRead: true,
                    sizeRatio: kSizeRatio,
                  ),
                  _buildNotificationItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Coba gunakan fitur Trash Chatbot',
                    subtitle: 'Tanyakan segala hal seputar sampah',
                    time: '1 minggu',
                    isRead: true,
                    sizeRatio: kSizeRatio,
                  ),
                  _buildNotificationItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Check-in hari pertama berhasil!',
                    subtitle: 'Lihat point yang sudah terkumpul',
                    time: '2 minggu',
                    isRead: true,
                    sizeRatio: kSizeRatio,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
    required double sizeRatio,
  }) {
    final bgColor = isRead ? const Color(0xFFDCEFD6) : AppColors.whiteSmoke;
    final titleColor = isRead ? AppColors.deepForestGreen : AppColors.deepForestGreen;
    final subtitleColor = isRead ? AppColors.fernGreen : AppColors.fernGreen;

    return Container(
      margin: EdgeInsets.only(bottom: 10 * sizeRatio),
      padding: EdgeInsets.all(16 * sizeRatio),
      decoration: BoxDecoration(
        color: bgColor,
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
            child: Icon(icon, color: AppColors.lightSageGreen, size: 24 * sizeRatio),
          ),
          SizedBox(width: 15 * sizeRatio),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
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
                    color: subtitleColor,
                    fontSize: 13 * sizeRatio,
                  ),
                ),
              ],
            ),
          ),
          // Teks waktu
          Padding(
            padding: EdgeInsets.only(left: 4.0 * sizeRatio),
            child: SizedBox(
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: titleColor,
                  fontSize: 12 * sizeRatio,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}