import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String baseUrl = "http://localhost/flutter_api/";

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool apiConnected = false;
  bool isLoading = false;
  bool showPassword = false;
  Timer? timer;

  void clearLogin() {
    username.clear();
    password.clear();
  }

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

  Future login() async {
    if (username.text.trim().isEmpty || password.text.trim().isEmpty) {
      _snack("Username dan Password wajib diisi", Colors.orange);
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
        Uri.parse("${baseUrl}login.php"),
        body: {"username": username.text, "password": password.text},
      );
      var data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Login Berhasil", const Color(0xFF43A047));
        clearLogin();
        Future.delayed(const Duration(milliseconds: 600), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                role: data["role"] ?? "user",
                nama: data["nama"] ?? "",
              ),
            ),
          );
        });
      } else {
        _snack("Username atau Password Salah", Colors.red);
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
    if (mounted) setState(() => isLoading = false);
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
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 0 : 24,
                vertical: 32,
              ),
              child: isWide ? _buildWideLayout() : _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDE (web) ──────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sisi kiri: branding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Aplikasi\nData Mahasiswa",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Kelola data mahasiswa dengan mudah dan cepat.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _apiStatusBadge(),
                    const SizedBox(height: 16),
                    _featureItem(Icons.people, "Manajemen data mahasiswa"),
                    _featureItem(
                      Icons.admin_panel_settings,
                      "Kontrol akses role admin & user",
                    ),
                    _featureItem(Icons.search, "Pencarian data real-time"),
                  ],
                ),
              ),
            ),
            // Sisi kanan: form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildFormCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MOBILE ──────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Icon(Icons.school, size: 72, color: Colors.white),
        const SizedBox(height: 12),
        const Text(
          "Data Mahasiswa",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _apiStatusBadge(),
        const SizedBox(height: 28),
        _buildFormCard(),
      ],
    );
  }

  Widget _apiStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
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
          const SizedBox(width: 6),
          Text(
            apiConnected ? "Server Online" : "Server Offline",
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Masuk",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Silakan login untuk melanjutkan",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: username,
              decoration: const InputDecoration(
                labelText: "Username",
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
              controller: password,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF3F51B5),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "MASUK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  clearLogin();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text(
                  "Belum punya akun? Daftar di sini",
                  style: TextStyle(color: Color(0xFF3F51B5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
