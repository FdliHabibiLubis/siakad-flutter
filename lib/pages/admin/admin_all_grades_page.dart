import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class AdminAllGradesPage extends StatefulWidget {
  const AdminAllGradesPage({super.key});

  @override
  State<AdminAllGradesPage> createState() => _AdminAllGradesPageState();
}

class _AdminAllGradesPageState extends State<AdminAllGradesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gradesList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await SupabaseConfig.client
          .from('nilai')
          .select('*, mahasiswa(*, users(nama)), kelas(*, mata_kuliah(*))')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _gradesList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat nilai: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredGrades {
    if (_searchQuery.isEmpty) return _gradesList;
    return _gradesList.where((item) {
      final nama = (item['mahasiswa']['users']['nama'] ?? '').toString().toLowerCase();
      final nim = (item['mahasiswa']['nim'] ?? '').toString().toLowerCase();
      final mk = (item['kelas']['mata_kuliah']['nama'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return nama.contains(q) || nim.contains(q) || mk.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGrades;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seluruh Nilai Mahasiswa"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Cari Mahasiswa, NIM, atau Mata Kuliah",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("Tidak ada data nilai ditemukan"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final m = item['mahasiswa'];
                          final nama = m['users']['nama'] ?? '-';
                          final nim = m['nim'] ?? '';
                          final mk = item['kelas']['mata_kuliah'];
                          final mkName = mk['nama'] ?? '';
                          
                          final tugas = item['nilai_tugas']?.toString() ?? '-';
                          final uts = item['nilai_uts']?.toString() ?? '-';
                          final uas = item['nilai_uas']?.toString() ?? '-';
                          final akhir = item['nilai_akhir']?.toString() ?? '-';
                          final grade = item['grade'] ?? '-';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nama,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: grade == 'A' || grade == 'B' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Grade: $grade",
                                          style: TextStyle(
                                            color: grade == 'A' || grade == 'B' ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text("NIM: $nim", style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text("Mata Kuliah: ${mkName} (Kelas ${item['kelas']['nama']})", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildScoreColumn("Tugas", tugas),
                                      _buildScoreColumn("UTS", uts),
                                      _buildScoreColumn("UAS", uas),
                                      _buildScoreColumn("Nilai Akhir", akhir),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String score) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        const SizedBox(height: 4),
        Text(score, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }
}
