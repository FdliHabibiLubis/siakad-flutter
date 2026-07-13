import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/supabase_config.dart';
import 'login_page.dart';
import 'admin/admin_dashboard.dart';
import 'dosen/dosen_dashboard.dart';
import 'mahasiswa/mahasiswa_dashboard.dart';
import 'mahasiswa/krs_page.dart';
import 'mahasiswa/khs_page.dart';
import 'mahasiswa/profile_page.dart';

class DashboardShell extends StatefulWidget {
  final String role;
  final Map<String, dynamic> profile;

  const DashboardShell({super.key, required this.role, required this.profile});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  bool _isMhsLoading = false;
  Map<String, dynamic>? _studentDetails;
  Map<String, dynamic>? _activeSemester;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'mahasiswa') {
      _loadMahasiswaData();
    }
  }

  Future<void> _loadMahasiswaData() async {
    setState(() => _isMhsLoading = true);
    try {
      final std = await SupabaseConfig.getStudentDetails();
      final List<dynamic> sem = await SupabaseConfig.client
          .from('semester')
          .select()
          .eq('status', true)
          .limit(1);

      setState(() {
        _studentDetails = std;
        if (sem.isNotEmpty) {
          _activeSemester = sem.first;
        }
        _isMhsLoading = false;
      });
    } catch (_) {
      setState(() => _isMhsLoading = false);
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.accent),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari sistem akademik ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildMahasiswaShell() {
    if (_isMhsLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> pages = [
      MahasiswaDashboard(profile: widget.profile, onLogout: _logout),
      if (_studentDetails != null && _activeSemester != null)
        KrsPage(
          studentDetails: _studentDetails!,
          activeSemester: _activeSemester!,
          isTab: true,
        )
      else
        const Scaffold(
          body: Center(
            child: Text("Data KRS tidak tersedia (Tidak ada semester akademik aktif)."),
          ),
        ),
      if (_studentDetails != null)
        KhsPage(
          studentDetails: _studentDetails!,
          activeSemester: _activeSemester,
          isTab: true,
        )
      else
        const Scaffold(
          body: Center(
            child: Text("Data KHS tidak tersedia."),
          ),
        ),
      if (_studentDetails != null)
        ProfilePage(
          studentDetails: _studentDetails!,
          isTab: true,
        )
      else
        const Scaffold(
          body: Center(
            child: Text("Data profil tidak tersedia."),
          ),
        ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_outlined), // Keep outline as per guidelines
              label: "Beranda",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_document),
              activeIcon: Icon(Icons.edit_document),
              label: "KRS",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grade_outlined),
              activeIcon: Icon(Icons.grade_outlined),
              label: "KHS",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_outline),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.role) {
      case 'admin':
        return AdminDashboard(profile: widget.profile, onLogout: _logout);
      case 'dosen':
        return DosenDashboard(profile: widget.profile, onLogout: _logout);
      case 'mahasiswa':
        return _buildMahasiswaShell();
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  "Role '${widget.role}' tidak dikenali.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text("Kembali ke Login"),
                )
              ],
            ),
          ),
        );
    }
  }
}
