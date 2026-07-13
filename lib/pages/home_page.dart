import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'data_mahasiswa_page.dart';
import '../utils/theme.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String nama;
  final String nim;
  final String jurusan;
  final String alamat;
  final String usernameLogin;
  final String role;

  const HomePage({
    super.key,
    required this.userId,
    required this.nama,
    required this.nim,
    required this.jurusan,
    required this.alamat,
    required this.usernameLogin,
    required this.role,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = "http://localhost/flutter_api/";

  // Form tambah mahasiswa (admin only)
  final cNim = TextEditingController();
  final cNama = TextEditingController();
  final cJurusan = TextEditingController();
  final cAlamat = TextEditingController();
  final cUsername = TextEditingController();
  final cPassword = TextEditingController();

  bool apiConnected = false;
  bool isLoading = false;
  bool showPass = false;
  int totalMhs = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    checkStatusApi();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => checkStatusApi());
    if (widget.role == 'admin') getTotalMahasiswa();
  }

  @override
  void dispose() {
    timer?.cancel();
    cNim.dispose();
    cNama.dispose();
    cJurusan.dispose();
    cAlamat.dispose();
    cUsername.dispose();
    cPassword.dispose();
    super.dispose();
  }

  Future<bool> checkStatusApi() async {
    try {
      final res = await http.get(Uri.parse("${baseUrl}cek_koneksi.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data["status"] == true;
        if (mounted) setState(() => apiConnected = status);
        return status;
      }
      if (mounted) setState(() => apiConnected = false);
      return false;
    } catch (_) {
      if (mounted) setState(() => apiConnected = false);
      return false;
    }
  }

  Future<void> getTotalMahasiswa() async {
    try {
      final res = await http.get(Uri.parse("${baseUrl}get_mahasiswa.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          if (mounted) setState(() => totalMhs = (data["data"] as List).length);
        }
      }
    } catch (_) {}
  }

  void clearForm() {
    cNim.clear();
    cNama.clear();
    cJurusan.clear();
    cAlamat.clear();
    cUsername.clear();
    cPassword.clear();
  }

  Future<void> simpan() async {
    if (cNim.text.trim().isEmpty ||
        cNama.text.trim().isEmpty ||
        cJurusan.text.trim().isEmpty ||
        cAlamat.text.trim().isEmpty ||
        cUsername.text.trim().isEmpty ||
        cPassword.text.isEmpty) {
      _snack("Semua field wajib diisi", Colors.orange);
      return;
    }
    if (!await checkStatusApi()) {
      _snack("Server tidak terhubung", Colors.red);
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}simpan_mahasiswa.php"),
        body: {
          "nim": cNim.text.trim(),
          "nama": cNama.text.trim(),
          "jurusan": cJurusan.text.trim(),
          "alamat": cAlamat.text.trim(),
          "username": cUsername.text.trim(),
          "password": cPassword.text,
        },
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data berhasil disimpan", Colors.green);
        clearForm();
        getTotalMahasiswa();
      } else {
        _snack(data["message"] ?? "Gagal menyimpan", Colors.red);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar?"),
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (r) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        title: Text(isAdmin ? "Dashboard Admin" : "Dashboard Mahasiswa"),
        elevation: 0,
        actions: [
          // Status badge
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
          const SizedBox(width: 4),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: isAdmin ? _buildAdmin() : _buildMahasiswa(),
    );
  }

  // ══════════════════════════════════════════════
  // TAMPILAN MAHASISWA - hanya lihat data sendiri
  // ══════════════════════════════════════════════
  Widget _buildMahasiswa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Header profil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        widget.nama.isNotEmpty
                            ? widget.nama[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Mahasiswa",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Data diri
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Data Diri",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const Divider(height: 20),
                      _infoRow(Icons.badge, "NIM", widget.nim),
                      _infoRow(Icons.person_outline, "Nama", widget.nama),
                      _infoRow(Icons.school, "Jurusan", widget.jurusan),
                      _infoRow(Icons.home_outlined, "Alamat", widget.alamat),
                      _infoRow(
                        Icons.account_circle,
                        "Username",
                        widget.usernameLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3F51B5)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(": ", style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAMPILAN ADMIN - form tambah + navigasi
  // ══════════════════════════════════════════════
  Widget _buildAdmin() {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Banner admin
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, ${widget.nama}!",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "Admin",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stat total mahasiswa
                    Column(
                      children: [
                        Text(
                          "$totalMhs",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Mahasiswa",
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Tombol ke data mahasiswa
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DataMahasiswaPage(role: widget.role),
                          ),
                        );
                        getTotalMahasiswa();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3F51B5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.table_chart, size: 16),
                      label: const Text("Lihat Data"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Form tambah mahasiswa
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_add, color: Color(0xFF3F51B5)),
                          SizedBox(width: 8),
                          Text(
                            "Tambah Data Mahasiswa",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isWide) _buildFormWide() else _buildFormMobile(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: clearForm,
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text("Reset"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : simpan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F51B5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(
                                isLoading ? "Menyimpan..." : "Simpan Data",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormWide() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field(cNim, "NIM", Icons.badge)),
            const SizedBox(width: 14),
            Expanded(child: _field(cNama, "Nama", Icons.person_outline)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _field(cJurusan, "Jurusan", Icons.school)),
            const SizedBox(width: 14),
            Expanded(
              child: _field(
                cUsername,
                "Username",
                Icons.account_circle_outlined,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _fieldMultiline(cAlamat, "Alamat", Icons.home_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(child: _fieldPassword(cPassword, "Password")),
          ],
        ),
      ],
    );
  }

  Widget _buildFormMobile() {
    return Column(
      children: [
        _field(cNim, "NIM", Icons.badge),
        _field(cNama, "Nama", Icons.person_outline),
        _field(cJurusan, "Jurusan", Icons.school),
        _fieldMultiline(cAlamat, "Alamat", Icons.home_outlined),
        _field(cUsername, "Username", Icons.account_circle_outlined),
        _fieldPassword(cPassword, "Password"),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3F51B5)),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _fieldMultiline(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3F51B5)),
          alignLabelWithHint: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _fieldPassword(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        obscureText: !showPass,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3F51B5)),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          suffixIcon: IconButton(
            icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => showPass = !showPass),
          ),
        ),
      ),
    );
  }
}
