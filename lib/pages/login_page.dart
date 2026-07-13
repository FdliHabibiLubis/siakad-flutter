import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';
import '../utils/theme.dart';
import 'register_page.dart';
import 'dashboard_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Ambil profil dari public.users
        final profile = await SupabaseConfig.getCurrentUserProfile();
        if (profile != null) {
          final String role = profile['role'] ?? 'mahasiswa';
          _snack("Login berhasil sebagai ${role.toUpperCase()}", Colors.green);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardShell(role: role, profile: profile),
            ),
          );
        } else {
          // Jika profil tidak ditemukan, sign out
          await SupabaseConfig.client.auth.signOut();
          _snack("Akun Anda belum tersinkronisasi di database.", Colors.orange);
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains("invalid login credentials") ||
          msg.toLowerCase().contains("invalid credentials") ||
          msg.toLowerCase().contains("password")) {
        msg = "Kata sandi Anda salah";
      }
      _snack(msg, Colors.red);
    } catch (e) {
      _snack("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return AppTheme.buildSetupScreen(context);
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Container(
        color: AppTheme.primary,
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

  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Row(
          children: [
            Expanded(child: _buildBrandingSection()),
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

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Icon(Icons.school_outlined, size: 72, color: Colors.white),
        const SizedBox(height: 12),
        const Text(
          "Sistem Informasi Akademik",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Academic Management Platform",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        _buildFormCard(),
      ],
    );
  }

  Widget _buildBrandingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school, size: 64, color: AppTheme.primary),
          const SizedBox(height: 24),
          const Text(
            "Sistem Informasi\nAkademik",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Kelola jadwal, KRS, materi kuliah, tugas, dan nilai dalam satu platform terintegrasi.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Masuk Akun",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Gunakan email dan password terdaftar Anda",
                style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              // Email Label
              const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              // Email Input
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "name@universitas.ac.id",
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Email wajib diisi";
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                    return "Format email tidak valid";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Label
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              // Password Input
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: "********",
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textLight,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Password wajib diisi";
                  if (val.length < 6) return "Password minimal 6 karakter";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text("MASUK"),
                ),
              ),
              const SizedBox(height: 16),
              
              // Registration Links
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text("Belum punya akun? Daftar di sini"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
