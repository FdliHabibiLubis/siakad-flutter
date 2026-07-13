# CIAKAD (Cistem Akademik Utama)

Sistem Informasi Akademik modern berbasis mobile yang dikembangkan menggunakan **Flutter** dan didukung oleh **Supabase** sebagai sistem manajemen basis data & otentikasi waktu nyata. 

Aplikasi ini menerapkan standar sistem desain **"Academic Core"** yang premium, bersih, dan berpusat pada kenyamanan interaksi pengguna.

---

## 🎨 Sistem Desain "Academic Core"

CIAKAD dirancang secara cermat menggunakan elemen-elemen estetik berikut:
- **Palet Warna Utama**:
  - `Primary (Indigo-Navy)` : `#1E3A8A` ke arah `#4338CA` (gradien header & tombol utama).
  - `Secondary (Teal/Cyan)` : `#14B8A6` (aksen ikon, badge status, & chip jurusan).
  - `Accent (Orange)`        : `#F97316` (warning/notifikasi, highlight, & tombol hapus).
  - `Background`             : `#F9FAFB` (bersih dengan kartu putih berbayangan lembut).
- **Tipografi**: Menggunakan font premium **Inter** (Google Fonts) di seluruh teks aplikasi.
- **Bentuk Komponen**: Sudut membulat modern (radius `12` untuk form & tombol, `16` untuk kartu & menu).
- **Branding & Animasi**:
  - **Splash Screen Interaktif**: Dilengkapi dengan animasi *Bounce-In* logo dan *Fade-In* judul saat aplikasi pertama kali dimuat.
  - **Logo Kustom**: Desain topi toga putih terintegrasi di atas huruf C berlatar biru sebagai ikon identitas platform.

---

## 👥 Fitur Berdasarkan Peran Pengguna (Role-Based)

### 👨‍🎓 Portal Mahasiswa
- **Header Gradient Profil**: Sapaan dinamis lengkap dengan nama, NIM, Program Studi, dan semester aktif saat ini.
- **Statistik Kumulatif**: Grid visual interaktif untuk memantau nilai IP Kumulatif (IPK) dan total SKS yang telah terdaftar.
- **Monitoring Tugas**: Panel tugas tertunda yang mendesak lengkap dengan tenggat waktu (*deadline*) dan aksi pintas pengerjaan.
- **Mata Kuliah Semester Ini**: Menampilkan kartu kelas terjadwal lengkap dengan nama dosen pengampu dan lokasi ruangan.
- **Pengisian KRS**: Antarmuka pemilihan jadwal kuliah semester baru menggunakan kartu seleksi interaktif yang ber-highlight saat diklik.
- **Papan Pengumuman**: Daftar pemberitahuan akademik umum maupun informasi khusus kelas.

### 👩‍🏫 Portal Dosen
- **Monitoring Kelas Diampu**: Daftar seluruh kelas yang ditugaskan kepada dosen lengkap dengan kuota jumlah mahasiswa.
- **Pengelolaan Tugas Kuliah**: Membuat tugas baru lengkap dengan instruksi dan batas pengumpulan.
- **Grading & Penilaian**: Memeriksa berkas tugas mahasiswa yang diunggah dan memberikan penilaian numerik secara langsung.
- **Berbagi Materi**: Mengunggah berkas materi kuliah untuk didistribusikan ke mahasiswa.

### ⚙️ Portal Administrator
- **Statistik Kampus Real-time**: Memantau jumlah total Mahasiswa, Dosen, Mata Kuliah, dan antrean KRS yang memerlukan persetujuan.
- **Kelola Pengguna**: CRUD akun data diri Dosen dan Mahasiswa (sinkron otomatis ke tabel otentikasi publik).
- **Konfigurasi Akademik**: Pengelolaan Program Studi, Semester, Mata Kuliah, Kelas, hingga Jadwal Kuliah secara hierarkis.
- **Persetujuan KRS**: Memvalidasi, menyetujui, atau menolak usulan KRS mahasiswa dengan cepat.
- **Laporan Lulus Nilai**: Dashboard monitoring nilai akhir dan transkrip nilai mahasiswa dari seluruh mata kuliah.

---

## 🛠️ Spesifikasi Teknologi

- **Framework**: [Flutter SDK](https://flutter.dev) (Dart language)
- **Database & Auth**: [Supabase](https://supabase.com) (PostgreSQL database + realtime triggers)
- **Font Package**: `google_fonts: ^6.2.0`
- **PDF Report**: `pdf: ^3.12.0` & `printing: ^5.14.3`

---

## 🚀 Panduan Memulai Proyek

### 1. Persiapan Basis Data (Supabase)
Sebelum menjalankan aplikasi, jalankan skrip SQL di berkas `database.sql` pada menu SQL Editor di dashboard Supabase Anda. Skrip ini akan membuat tabel, relasi, constraint, trigger sinkronisasi profil, serta data awal (seed data).

### 2. Konfigurasi Kredensial API
Buka berkas `lib/utils/supabase_config.dart` dan masukkan kredensial URL serta Anon Key Supabase proyek Anda:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  ...
}
```

### 3. Pemasangan Dependensi
Unduh paket dependensi yang dideklarasikan di dalam proyek dengan perintah:
```bash
flutter pub get
```

### 4. Menjalankan Aplikasi
Jalankan aplikasi ke emulator atau perangkat fisik Anda menggunakan perintah:
```bash
flutter run
```
