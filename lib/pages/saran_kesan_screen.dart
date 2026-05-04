import 'package:flutter/material.dart';

class SaranKesanScreen extends StatelessWidget {
  const SaranKesanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saran & Kesan TPM"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kesan Kuliah TPM",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A52BE),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Mata kuliah Teknologi Pemrograman Mobile memberikan wawasan yang sangat praktis dalam pengembangan aplikasi modern. Kami sangat menikmati proses belajar Flutter karena dokumentasinya yang lengkap dan komunitasnya yang suportif.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 32),
            const Text(
              "Saran untuk Mata Kuliah",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Mungkin kedepannya bisa diperbanyak porsi materi mengenai integrasi CI/CD atau testing pada Flutter, agar mahasiswa lebih siap menghadapi standar industri yang lebih kompleks.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
