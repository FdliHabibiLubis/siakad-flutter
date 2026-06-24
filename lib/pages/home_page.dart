import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'data_mahasiswa_page.dart';

class HomePage extends StatefulWidget {
  final String role;
  final String nama;
  const HomePage({super.key, required this.role, required this.nama});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = "http://localhost/flutter_api/";

  final TextEditingController nim = TextEditingController();
  final TextEditingController nama = TextEditingController();
  final TextEditingController jurusan = TextEditingController();
  final TextEditingController alamat = TextEditingController();

  bool apiConnected = false;
  bool isLoading = false;
  Timer? timer;

  Future<bool> checkStatusApi() async {
    try {
      final res = await http.get(Uri.parse("${baseUrl}cek_koneksi.php"));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        bool status = data["status"] == true;
        if (mounted) setState(() => apiConnected = status);
        return status;
      }
      if (mounted) setState(() => apiConnected = false);
      return false;
    } catch (e) {
      if (mounted) setState(() => apiConnected = false);
      return false;
    }
  }

  void clearForm() {
    nim.clear();
    nama.clear();
    jurusan.clear();
    alamat.clear();
  }

  Future simpan() async {
    if (nim.text.trim().isEmpty ||
        nama.text.trim().isEmpty ||
        jurusan.text.trim().isEmpty ||
        alamat.text.trim().isEmpty) {
      _snack("Semua data wajib diisi", Colors.orange);
      return;
    }
    bool apiAktif = await checkStatusApi();
    if (!apiAktif) {
      _snack("Server API Tidak Terhubung", Colors.red);
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}simpan_mahasiswa.php"),
        body: {
          "nim": nim.text,
          "nama": nama.text,
          "jurusan": jurusan.text,
          "alamat": alamat.text,
        },
      );
      var data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data Berhasil Disimpan", const Color(0xFF43A047));
        clearForm();
      } else {
        _snack("Data Gagal Disimpan", Colors.red);
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
            ),
            onPressed: () {
              Navigator.pop(context);
              clearForm();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    checkStatusApi();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => checkStatusApi());
  }

  @override
  void dispose() {
    timer?.cancel();
    nim.dispose();
    nama.dispose();
    jurusan.dispose();
    alamat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final isAdmin = widget.role == "admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        title: const Text("Tambah Data Mahasiswa"),
        elevation: 0,
        actions: [
          // Status API
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: apiConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    apiConnected ? "Online" : "Offline",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // Batas lebar konten di web
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 16),
            child: isWide ? _buildWideBody(isAdmin) : _buildMobileBody(isAdmin),
          ),
        ),
      ),
    );
  }

  // ── WIDE (web): info card kiri, form kanan ──────────────────
  Widget _buildWideBody(bool isAdmin) {
    return Column(
      children: [
        // Info user banner
        _buildUserBanner(isAdmin, isWide: true),
        const SizedBox(height: 24),
        // Dua kolom: form kiri, info kanan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildFormCard()),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _buildSideInfo(isAdmin)),
          ],
        ),
      ],
    );
  }

  // ── MOBILE: stack vertikal ──────────────────────────────────
  Widget _buildMobileBody(bool isAdmin) {
    return Column(
      children: [
        _buildUserBanner(isAdmin, isWide: false),
        const SizedBox(height: 16),
        _buildFormCard(),
      ],
    );
  }

  Widget _buildUserBanner(bool isAdmin, {required bool isWide}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isWide ? 30 : 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
              size: isWide ? 30 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, ${widget.nama}!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAdmin ? "Administrator" : "User",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Tombol lihat data
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DataMahasiswaPage(role: widget.role),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3F51B5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.table_chart, size: 18),
            label: Text(
              isWide ? "Lihat Data Mahasiswa" : "Lihat Data",
              style: TextStyle(fontSize: isWide ? 14 : 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Color(0xFF3F51B5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Form Input Mahasiswa",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nim,
              decoration: const InputDecoration(
                labelText: "NIM",
                prefixIcon: Icon(Icons.badge, color: Color(0xFF3F51B5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: "Nama Mahasiswa",
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Color(0xFF3F51B5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: jurusan,
              decoration: const InputDecoration(
                labelText: "Jurusan",
                prefixIcon: Icon(Icons.school, color: Color(0xFF3F51B5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: alamat,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Alamat",
                prefixIcon: Icon(Icons.home_outlined, color: Color(0xFF3F51B5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: clearForm,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text("Reset"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(isLoading ? "Menyimpan..." : "Simpan Data"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Panel info samping (hanya di web)
  Widget _buildSideInfo(bool isAdmin) {
    return Column(
      children: [
        _infoPanel(
          icon: Icons.info_outline,
          title: "Panduan Input",
          color: const Color(0xFF3F51B5),
          items: const [
            "NIM harus unik untuk setiap mahasiswa",
            "Nama ditulis lengkap sesuai KTP",
            "Jurusan sesuai program studi",
            "Alamat tempat tinggal saat ini",
          ],
        ),
        const SizedBox(height: 16),
        _infoPanel(
          icon: isAdmin ? Icons.admin_panel_settings : Icons.person,
          title: isAdmin ? "Hak Akses Admin" : "Hak Akses User",
          color: isAdmin ? const Color(0xFF1A237E) : const Color(0xFF1565C0),
          items: isAdmin
              ? [
                  "Tambah data mahasiswa",
                  "Lihat semua data mahasiswa",
                  "Edit data mahasiswa",
                  "Hapus data mahasiswa",
                ]
              : ["Tambah data mahasiswa", "Lihat semua data mahasiswa"],
        ),
      ],
    );
  }

  Widget _infoPanel({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: color.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
