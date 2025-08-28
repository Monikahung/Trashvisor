import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

// Widget utama untuk halaman profil pengguna.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold memberikan struktur dasar untuk layar.
    return Scaffold(
      // Stack digunakan untuk menumpuk elemen, dalam hal ini
      // gambar latar belakang dan konten di atasnya.
      body: SingleChildScrollView(
        child: Container(
          // Background ada di sini sehingga ikut scroll
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
              // Tombol di pojok kiri atas dan kanan atas.
              _buildTombolAtas(context),
              // Memberi jarak kosong sebelum kartu utama.
              const SizedBox(height: 150),
              // Kartu utama berisi profil dan aktivitas.
              _buildKartuKonten(context)
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Pembantu untuk Keterbacaan yang Lebih Baik ---

  // Membangun tombol 'Kembali' dan 'Keluar'.
  Widget _buildTombolAtas(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali di sisi kiri.
          _buildTombolKembali(
            ikon: Icons.arrow_back_ios_new,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // Tombol Keluar di sisi kanan.
          _buildTombolKeluar(
            teks: 'Keluar',
            ikon: Icons.exit_to_app,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk membuat tombol kembali
  Widget _buildTombolKeluar({String? teks, required IconData ikon, required VoidCallback onPressed}) {
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
                  style: TextStyle(
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

  // Fungsi pembantu untuk membuat tombol kembali
  Widget _buildTombolKembali({required IconData ikon, required VoidCallback onPressed}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        shape: BoxShape.circle,  // lingkaran sempurna
        border: Border.all(color: AppColors.whiteSmoke, width: 2),
      ),
      child: IconButton(
        icon: Icon(ikon, color: AppColors.whiteSmoke),
        onPressed: onPressed,
        padding: EdgeInsets.zero, // penting supaya lingkaran tidak oval
        iconSize: 20,
      ),
    );
  }


  // Membangun kartu putih utama yang berisi profil dan aktivitas.
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bagian profil pengguna.
            _buildBagianProfilPengguna(),
            // Jarak pemisah.
            const SizedBox(height: 20),
            // Bagian aktivitas mingguan.
            _buildBagianAktivitasMingguan(),
          ],
        ),
      ),
    );
  }

  // Membangun area profil pengguna dengan foto, nama, email, level, dan koin.
  Widget _buildBagianProfilPengguna() {
    return Row(
      children: [
        // Foto profil pengguna.
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: AppColors.fernGreen.withAlpha((255 * 0.2).round()), // Warna latar belakang ikon
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fernGreen, width: 2), // Garis luar lingkaran
          ),
          child: Padding(
            padding: const EdgeInsets.all(8), // Jarak antara ikon dan tepi lingkaran
            child: Icon(
              Icons.person,
              size: 60, // ukuran ikon bisa disesuaikan
              color: AppColors.fernGreen,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Kolom untuk detail pengguna (nama, email, level).
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Udin Budiono', // Anda bisa menggantinya dengan variabel dinamis
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkMossGreen
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'udinbudiono55@gmail.com', // Anda bisa menggantinya dengan variabel dinamis
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Baris untuk level dan koin.
              Row(
                children: [
                  // Level pengguna (contoh: Level Silver).
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: Color(0xFFC0C0C0), size: 30),
                        const SizedBox(width: 4),
                        const Text(
                          'Level Silver', 
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkOliveGreen)
                        ),
                      ],
                    ),
                  ),
                  const Spacer(), // Mendorong container koin ke kanan.
                  // Saldo koin pengguna.
                  _buildContainerKoin(1771),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget pembantu untuk membangun container koin.
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
            decoration: BoxDecoration(
              color: Colors.amberAccent, // background ikon
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

  // Membangun bagian aktivitas mingguan dengan hari dan ikon status.
  Widget _buildBagianAktivitasMingguan() {
    // Daftar status aktivitas statis untuk demonstrasi.
    final List<bool?> statusMingguan = [true, true, false, true, true, true, false];
    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.fernGreen.withAlpha((255 * 1.0).round()),
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
              const Text(
                '11/08/2025 - 17/08/2025',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: AppColors.whiteSmoke,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row untuk menampilkan ikon status harian.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  _buildIkonStatus(statusMingguan[index]),
                  const SizedBox(height: 4),
                  Text(
                    hari[index],
                    style: const TextStyle(
                      color: AppColors.whiteSmoke, 
                      fontSize: 12,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIkonStatus(bool? isSelesai) {
    IconData ikon;
    Color warna;
    Color bgWarna;

    if (isSelesai == true) {
      ikon = Icons.check_circle;
      warna = Colors.green;
      bgWarna = AppColors.whiteSmoke; // background hijau lembut
    } else {
      ikon = Icons.cancel;
      warna = Colors.red;
      bgWarna = AppColors.whiteSmoke; // background merah lembut
    }

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: bgWarna,
        shape: BoxShape.circle, // membuatnya bulat
      ),
      child: Icon(
        ikon,
        color: warna,
        size: 32.5,
      ),
    );
  }
}