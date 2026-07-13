import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'mhs_class_detail_page.dart';

class MahasiswaDashboard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;

  const MahasiswaDashboard({super.key, required this.profile, required this.onLogout});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentDetails;
  Map<String, dynamic>? _activeSemester;
  List<Map<String, dynamic>> _mySchedules = [];
  List<Map<String, dynamic>> _announcements = [];
  double _ipk = 0.0;
  List<Map<String, dynamic>> _pendingAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      // 1. Get Mahasiswa Details
      final stdData = await SupabaseConfig.getStudentDetails();
      if (stdData == null) {
        throw Exception("Profil Mahasiswa tidak ditemukan di database.");
      }
      _studentDetails = stdData;

      // 2. Get Active Semester
      final List<dynamic> semData = await client
          .from('semester')
          .select()
          .eq('status', true)
          .limit(1);
      
      if (semData.isNotEmpty) {
        _activeSemester = semData.first;
      }

      // 3. Get Student Schedule if semester active exists
      if (_activeSemester != null) {
        final List<dynamic> krsData = await client
            .from('krs')
            .select('*, jadwal(*, kelas(*, mata_kuliah(*), dosen(users(nama))), semester(*))')
            .eq('mahasiswa_id', _studentDetails!['id'])
            .eq('semester_id', _activeSemester!['id'])
            .eq('status', 'disetujui');
        
        _mySchedules = List<Map<String, dynamic>>.from(krsData);
      }

      // 4. Get announcements (general and class specific for approved courses)
      final List<String> enrolledClassIds = _mySchedules.map((k) => k['jadwal']['kelas_id'].toString()).toList();
      
      final clientQuery = client.from('pengumuman').select('*, users(nama), kelas(*)');
      
      List<dynamic> annData = [];
      if (enrolledClassIds.isNotEmpty) {
        annData = await clientQuery.or('kelas_id.is.null,kelas_id.in.(${enrolledClassIds.join(",")})').order('created_at', ascending: false);
      } else {
        annData = await clientQuery.isFilter('kelas_id', null).order('created_at', ascending: false);
      }
      _announcements = List<Map<String, dynamic>>.from(annData);

      // 5. Calculate Cumulative GPA (IPK)
      final List<dynamic> gradesData = await client
          .from('nilai')
          .select('*, kelas(*, mata_kuliah(*))')
          .eq('mahasiswa_id', _studentDetails!['id']);
      
      double totalPoints = 0;
      int totalSks = 0;
      for (var row in gradesData) {
        final sks = row['kelas']?['mata_kuliah']?['sks'];
        final grade = row['grade'];
        if (sks != null && grade != null) {
          final sksInt = (sks as num).toInt();
          double gp = 0.0;
          switch (grade.toString().toUpperCase()) {
            case 'A': gp = 4.0; break;
            case 'B': gp = 3.0; break;
            case 'C': gp = 2.0; break;
            case 'D': gp = 1.0; break;
            case 'E': gp = 0.0; break;
          }
          totalPoints += sksInt * gp;
          totalSks += sksInt;
        }
      }
      _ipk = totalSks > 0 ? totalPoints / totalSks : 0.0;

      // 6. Get Pending Assignments (tugas yang harus dikerjakan)
      _pendingAssignments = [];
      if (enrolledClassIds.isNotEmpty) {
        // Fetch all assignments for enrolled classes
        final List<dynamic> allAssignments = await client
            .from('tugas')
            .select('*, kelas(*, mata_kuliah(*))')
            .inFilter('kelas_id', enrolledClassIds)
            .order('deadline', ascending: true);
            
        // Fetch student's submissions
        final List<dynamic> mySubmissions = await client
            .from('pengumpulan_tugas')
            .select('tugas_id')
            .eq('mahasiswa_id', _studentDetails!['id']);
            
        final submittedTugasIds = mySubmissions.map((s) => s['tugas_id'].toString()).toSet();
        
        // Filter pending assignments
        _pendingAssignments = List<Map<String, dynamic>>.from(
          allAssignments.where((t) => !submittedTugasIds.contains(t['id'].toString()))
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(context, "Gagal memuat dashboard: $e", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portal Mahasiswa"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
               onRefresh: _loadDashboardData,
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(20),
                 physics: const AlwaysScrollableScrollPhysics(),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildWelcomeCard(),
                     const SizedBox(height: 24),
                     
                     _buildIpkCard(),
                     const SizedBox(height: 24),
                     
                     _buildPendingAssignments(),
                     const SizedBox(height: 28),

                     const Text(
                       "Mata Kuliah Semester Ini",
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                     ),
                     const SizedBox(height: 12),
                     _buildEnrolledClasses(),
                     const SizedBox(height: 28),
                     
                     const Text(
                       "Papan Pengumuman",
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
    final nim = _studentDetails?['nim'] ?? '-';
    final prodi = _studentDetails?['program_studi']?['nama'] ?? '-';
    final semesterName = _activeSemester?['nama'] ?? 'Belum ada semester aktif';
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
                    "Hai, ${widget.profile['nama']}!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "NIM: $nim | $prodi",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Semester Aktif: $semesterName",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.school, color: Colors.white, size: 36),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIpkCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stars_outlined, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Indeks Prestasi Kumulatif (IPK) Saat Ini",
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ipk.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAssignments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tugas Yang Harus Dikerjakan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        if (_pendingAssignments.isEmpty)
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    "Semua tugas sudah selesai dikerjakan!",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingAssignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tugas = _pendingAssignments[index];
              final title = tugas['judul'] ?? 'Tugas Tanpa Judul';
              final desc = tugas['deskripsi'] ?? '';
              final deadlineStr = tugas['deadline'] != null
                  ? DateTime.parse(tugas['deadline']).toLocal().toString().substring(0, 16)
                  : '-';
              final mkName = tugas['kelas']?['mata_kuliah']?['nama'] ?? 'Mata Kuliah';
              
              return Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mkName,
                                style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.alarm_on_outlined, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  "Batas Waktu: $deadlineStr",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          final sId = tugas['kelas_id'].toString();
                          final sched = _mySchedules.firstWhere(
                            (k) => k['jadwal']['kelas_id'].toString() == sId,
                            orElse: () => {},
                          );
                          
                          if (sched.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MhsClassDetailPage(
                                  kelasItem: sched['jadwal']['kelas'],
                                  mahasiswaId: _studentDetails!['id'],
                                  jadwalItem: sched['jadwal'],
                                ),
                              ),
                            ).then((_) => _loadDashboardData());
                          } else {
                            AppTheme.showSnackBar(
                              context,
                              "Detail kelas untuk tugas ini tidak ditemukan.",
                              backgroundColor: Colors.orange,
                            );
                          }
                        },
                        child: const Text(
                          "KERJAKAN",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEnrolledClasses() {
    if (_mySchedules.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, color: Colors.grey.shade400, size: 40),
                const SizedBox(height: 8),
                const Text(
                  "Anda belum mengambil KRS atau KRS Anda belum disetujui Admin.",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
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
      itemCount: _mySchedules.length,
      itemBuilder: (context, index) {
        final item = _mySchedules[index];
        final j = item['jadwal'] ?? {};
        final k = j['kelas'] ?? {};
        final mk = k['mata_kuliah'] ?? {};
        final dName = k['dosen'] != null ? k['dosen']['users']['nama'] : '-';
        final timeStr = "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(child: Icon(Icons.class_outlined)),
            title: Text("[${mk['kode']}] ${mk['nama']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Dosen: $dName | Kelas: ${k['nama']} (${mk['sks']} SKS)"),
                const SizedBox(height: 2),
                Text("Jadwal: ${j['hari']}, $timeStr (${(j['ruangan'] ?? '').toString().toLowerCase().contains('ruang') ? (j['ruangan'] ?? '') : "Ruang ${j['ruangan'] ?? ''}"})", style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MhsClassDetailPage(
                    kelasItem: k,
                    mahasiswaId: _studentDetails!['id'],
                    jadwalItem: j,
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
            child: Text("Tidak ada pengumuman baru", style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
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
        final dateStr = "${date.day}/${date.month}/${date.year}";
        final isGeneral = ann['kelas_id'] == null;
        final scopeText = isGeneral ? "PENGUMUMAN UMUM" : "KELAS ${ann['kelas']['nama']}";

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGeneral ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scopeText,
                        style: TextStyle(
                          color: isGeneral ? Colors.blue : Colors.purple,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
                const SizedBox(height: 8),
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
                Text(
                  "Oleh: ${ann['users']['nama']}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
