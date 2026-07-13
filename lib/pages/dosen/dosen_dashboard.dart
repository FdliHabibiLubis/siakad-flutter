import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'class_detail_page.dart';

class DosenDashboard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;

  const DosenDashboard({super.key, required this.profile, required this.onLogout});

  @override
  State<DosenDashboard> createState() => _DosenDashboardState();
}

class _DosenDashboardState extends State<DosenDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dosenDetails;
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadDosenData();
  }

  Future<void> _loadDosenData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      
      // Get Dosen Profile Row
      final details = await SupabaseConfig.getDosenDetails();
      if (details == null) {
        throw Exception("Profil Dosen tidak ditemukan di database.");
      }
      _dosenDetails = details;

      // Get Classes taught by this Dosen
      final List<dynamic> classesData = await client
          .from('kelas')
          .select('*, mata_kuliah(*), jadwal(*)')
          .eq('dosen_id', _dosenDetails!['id']);
      
      _kelasList = List<Map<String, dynamic>>.from(classesData);

      // Get General Announcements
      final List<dynamic> annData = await client
          .from('pengumuman')
          .select('*, users(nama)')
          .isFilter('kelas_id', null)
          .order('created_at', ascending: false);

      _announcements = List<Map<String, dynamic>>.from(annData);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat dashboard dosen: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Dosen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDosenData,
            tooltip: "Muat Ulang",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.accent),
            onPressed: widget.onLogout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDosenData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    
                    const Text(
                      "Mata Kuliah Yang Diampu",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    _buildClassesList(),
                    const SizedBox(height: 28),
                    
                    const Text(
                      "Pengumuman Akademik Umum",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    _buildAnnouncementsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final nidn = _dosenDetails?['nidn'] ?? '-';
    return AppTheme.buildGradientCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Datang, ${widget.profile['nama']}!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "NIDN: $nidn",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pilih kelas Anda di bawah untuk mengelola materi, tugas, pengumuman kelas, dan input nilai.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.co_present_outlined, color: Colors.white, size: 36),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    if (_kelasList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.class_outlined, color: Colors.grey.shade400, size: 40),
                const SizedBox(height: 8),
                const Text(
                  "Anda belum ditugaskan mengajar di kelas manapun.",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kelasList.length,
      itemBuilder: (context, index) {
        final k = _kelasList[index];
        final mk = k['mata_kuliah'] ?? {};
        final j = k['jadwal'];
        
        String scheduleText = "Belum dijadwalkan";
        if (j != null) {
          final timeStr = "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";
          scheduleText = "${j['hari']}, $timeStr (${(j['ruangan'] ?? '').toString().toLowerCase().contains('ruang') ? (j['ruangan'] ?? '') : "Ruang ${j['ruangan'] ?? ''}"})";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: AppTheme.primary),
            ),
            title: Text(
              "[${mk['kode'] ?? ''}] ${mk['nama'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Kelas: ${k['nama']} | Kuota: ${k['kuota']} Mahasiswa"),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        scheduleText,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassDetailPage(
                    kelasItem: k,
                    dosenId: _dosenDetails!['id'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text("Tidak ada pengumuman akademik umum", style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final date = DateTime.parse(ann['created_at']).toLocal();
        final dateString = "${date.day}/${date.month}/${date.year}";
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ann['judul'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  ann['isi'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Oleh: ${ann['users']['nama']}", style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                    Text(dateString, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
