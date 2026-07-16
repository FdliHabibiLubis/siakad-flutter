# 🎓 CIAKAD (Cistem Akademik Utama)

[![Flutter](https://img.shields.io/badge/Flutter-v3.22.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-v2.16.x-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![PDF Printing](https://img.shields.io/badge/PDF_Report-Enabled-E01E5A?logo=adobe-acrobat-reader&logoColor=white)](https://pub.dev/packages/printing)
[![Google Fonts](https://img.shields.io/badge/Font-Inter-blue?logo=google-fonts&logoColor=white)](https://fonts.google.com/)

Sistem Informasi Akademik modern berbasis mobile yang dikembangkan menggunakan **Flutter** dan didukung oleh **Supabase** sebagai sistem manajemen basis data & otentikasi waktu nyata (*real-time*). 

Aplikasi ini menerapkan standar sistem desain **"Academic Core"** yang premium, bersih, dan berpusat pada kenyamanan interaksi pengguna. Dilengkapi dengan manajemen multi-peran (Mahasiswa, Dosen, Admin) dan fitur ekspor dokumen akademik resmi langsung dari perangkat.

---

## 🎨 Sistem Desain "Academic Core"

CIAKAD dirancang secara cermat menggunakan elemen-elemen estetik berikut untuk menghadirkan pengalaman pengguna yang premium dan profesional:

*   **Palet Warna Utama**:
    *   `Primary (Indigo-Navy)` : `#1E3A8A` ke arah `#4338CA` (gradien indah pada header & tombol utama).
    *   `Secondary (Teal/Cyan)` : `#14B8A6` (digunakan pada aksen ikon, badge status, & chip informasi).
    *   `Accent (Orange)`        : `#F97316` (warning/notifikasi, highlight penting, & aksi destruktif).
    *   `Background Light`        : `#F9FAFB` (bersih dengan kartu putih berbayangan lembut/soft-shadow).
*   **Tipografi**: Menggunakan font premium **Inter** (melalui Google Fonts) di seluruh teks aplikasi untuk keterbacaan yang maksimal.
*   **Bentuk & Radius Komponen**: Sudut membulat modern (radius `12` untuk elemen form/tombol, `16` untuk kartu & menu navigasi).
*   **Branding & Animasi**:
    *   **Splash Screen Interaktif**: Dilengkapi dengan animasi *Bounce-In* logo dan *Fade-In* judul saat aplikasi pertama kali dimuat.
    *   **Logo Kustom**: Desain topi toga putih terintegrasi di atas huruf C berlatar biru sebagai ikon identitas platform.

---

## 👥 Fitur Berdasarkan Peran Pengguna (Role-Based)

### 👨‍🎓 Portal Mahasiswa
*   **Header Gradient Profil**: Sapaan dinamis lengkap dengan nama, NIM, Program Studi, dan semester aktif saat ini.
*   **Statistik Kumulatif**: Grid visual interaktif untuk memantau nilai IP Kumulatif (IPK), IP Semester (IPS), dan total SKS yang telah ditempuh.
*   **Pengisian & Cetak KRS**: Antarmuka pemilihan jadwal kuliah semester baru menggunakan kartu seleksi interaktif yang ber-highlight saat diklik. Dilengkapi fitur **Cetak KRS Resmi ke format PDF** lengkap dengan area tanda tangan dosen wali & kaprodi.
*   **Kartu Hasil Studi (KHS) & Transkrip**: Laporan nilai semester aktif maupun kumulatif yang dapat diekspor langsung ke dokumen **PDF Cetak KHS**.
*   **Monitoring Tugas**: Panel tugas tertunda yang mendesak lengkap dengan tenggat waktu (*deadline*), status pengumpulan, dan aksi pintas pengerjaan.
*   **Mata Kuliah Semester Ini**: Menampilkan kartu kelas terjadwal lengkap dengan nama dosen pengampu, waktu, dan lokasi ruangan.
*   **Papan Pengumuman**: Daftar pemberitahuan akademik umum maupun informasi khusus kelas.

### 👩‍🏫 Portal Dosen
*   **Monitoring Kelas Diampu**: Daftar seluruh kelas yang ditugaskan kepada dosen lengkap dengan informasi mata kuliah dan kuota jumlah mahasiswa.
*   **Pengelolaan Tugas Kuliah**: Membuat tugas baru lengkap dengan instruksi, lampiran berkas/tautan, dan batas pengumpulan (*deadline*).
*   **Grading & Penilaian**: Memeriksa berkas tugas mahasiswa yang diunggah dan memberikan penilaian numerik (Tugas, UTS, UAS) secara langsung untuk dikalkulasi menjadi Nilai Akhir & Grade otomatis.
*   **Berbagi Materi**: Mengunggah berkas materi kuliah untuk didistribusikan ke mahasiswa di kelas yang bersangkutan.
*   **Jadwal Mengajar**: Dashboard pemantauan jadwal mengajar dosen per hari.

### ⚙️ Portal Administrator
*   **Statistik Kampus Real-time**: Memantau jumlah total Mahasiswa, Dosen, Mata Kuliah, dan antrean KRS yang memerlukan persetujuan.
*   **Kelola Pengguna**: CRUD akun data diri Dosen dan Mahasiswa (sinkron otomatis ke tabel otentikasi publik Supabase melalui trigger database).
*   **Konfigurasi Akademik**: Pengelolaan Program Studi, Semester, Mata Kuliah, Kelas, hingga Jadwal Kuliah secara hierarkis.
*   **Persetujuan KRS**: Memvalidasi, menyetujui, atau menolak usulan KRS mahasiswa dengan cepat.
*   **Laporan Lulus Nilai**: Dashboard monitoring nilai akhir dan transkrip nilai mahasiswa dari seluruh mata kuliah.

---

## 📁 Struktur Folder Proyek

Proyek ini terorganisir dengan rapi mengikuti arsitektur modular di Flutter:

```text
lib/
├── main.dart                      # Titik masuk utama aplikasi (Entry point)
├── pages/                         # Direktori halaman & antarmuka pengguna
│   ├── admin/                     # Portal Administrator
│   │   ├── admin_all_assignments_page.dart
│   │   ├── admin_all_grades_page.dart
│   │   ├── admin_dashboard.dart
│   │   ├── krs_approval_page.dart
│   │   ├── manage_akademik_page.dart
│   │   └── manage_users_page.dart
│   ├── dosen/                     # Portal Dosen
│   │   ├── class_detail_page.dart
│   │   ├── dosen_dashboard.dart
│   │   ├── dosen_jadwal_page.dart
│   │   ├── dosen_nilai_page.dart
│   │   ├── dosen_profile_page.dart
│   │   └── submission_grading_page.dart
│   ├── mahasiswa/                 # Portal Mahasiswa
│   │   ├── khs_page.dart
│   │   ├── krs_page.dart
│   │   ├── mahasiswa_dashboard.dart
│   │   ├── mhs_class_detail_page.dart
│   │   └── profile_page.dart
│   ├── dashboard_shell.dart       # Shell navigasi/bottom bar dinamis sesuai role
│   ├── data_mahasiswa_page.dart   # Detail informasi & transkrip mahasiswa
│   ├── home_page.dart             # Halaman utama pendaratan (Landing/Wrapper)
│   ├── login_page.dart            # Autentikasi Masuk
│   ├── register_page.dart         # Autentikasi Daftar Baru
│   └── splash_page.dart           # Splash Screen dengan Animasi
└── utils/                         # Utilitas & Helper global
    ├── format_utils.dart          # Helper pemformatan teks, tanggal, & nilai
    ├── supabase_config.dart       # Konfigurasi klien dan fungsi pembantu Supabase
    └── theme.dart                 # Konfigurasi sistem desain "Academic Core"
```

---

## 🛠️ Spesifikasi Teknologi & Library

*   **Framework**: [Flutter SDK](https://flutter.dev) (Dart language)
*   **Database & Auth**: [Supabase](https://supabase.com) (PostgreSQL database + realtime triggers + Row Level Security)
*   **Font Package**: `google_fonts: ^6.2.0` (Menggunakan font Inter)
*   **PDF Generation**: `pdf: ^3.12.0`
*   **Dokumen Printing**: `printing: ^5.14.3` (Mendukung cetak & pratinjau PDF langsung dari mobile)
*   **File Selection**: `file_picker: ^11.0.2` (Digunakan untuk mengunggah materi & tugas)
*   **Sistem Penyimpanan**: `shared_preferences: ^2.2.2` (Untuk sesi lokal ringan)

---

## 🚀 Panduan Memulai Proyek

### 1. Persiapan Basis Data (Supabase)
Sebelum menjalankan aplikasi, jalankan skrip SQL di berkas `database.sql` pada menu **SQL Editor** di dashboard Supabase Anda. Skrip ini akan otomatis membuat:
*   Tabel-tabel relasional (users, mahasiswa, dosen, mata kuliah, kelas, krs, dll.)
*   Constraint integritas referensial dan validasi bisnis.
*   Trigger sinkronisasi profil untuk menyalin otomatis user baru dari `auth.users` ke `public.users`.
*   Data benih awal (*seed data*) untuk pengujian cepat.

### 2. Konfigurasi Kredensial API
Buka berkas `lib/utils/supabase_config.dart` dan masukkan kredensial URL serta Anon Key dari proyek Supabase Anda:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'MASUKKAN_URL_SUPABASE_ANDA';
  static const String supabaseAnonKey = 'MASUKKAN_ANON_KEY_SUPABASE_ANDA';
  ...
}
```

### 3. Pemasangan Dependensi
Unduh paket dependensi yang diperlukan oleh proyek dengan perintah:
```bash
flutter pub get
```

### 4. Menjalankan Aplikasi
Jalankan aplikasi ke emulator atau perangkat fisik Anda menggunakan perintah:
```bash
flutter run
```

---

## 📝 Lisensi

Proyek ini dikembangkan untuk kebutuhan akademik dan pembelajaran sistem integrasi Flutter & Supabase. Kontribusi dan saran perbaikan sangat kami harapkan!
