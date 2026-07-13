import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class KrsPage extends StatefulWidget {
  final Map<String, dynamic> studentDetails;
  final Map<String, dynamic> activeSemester;
  final bool isTab;

  const KrsPage({super.key, required this.studentDetails, required this.activeSemester, this.isTab = false});

  @override
  State<KrsPage> createState() => _KrsPageState();
}

class _KrsPageState extends State<KrsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableJadwal = [];
  List<Map<String, dynamic>> _existingKrs = [];
  
  final Set<String> _selectedJadwalIds = {};
  String _krsStatus = "draft"; // draft, menunggu, disetujui, ditolak
  int _totalSks = 0;

  @override
  void initState() {
    super.initState();
    _loadKrsData();
  }

  Future<void> _loadKrsData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final mId = widget.studentDetails['id'];
      final semId = widget.activeSemester['id'];

      // 1. Fetch available schedules for the active semester
      final List<dynamic> schedules = await client
          .from('jadwal')
          .select('*, kelas(*, mata_kuliah(*), dosen(users(nama))), semester(*)')
          .eq('semester_id', semId);

      _availableJadwal = List<Map<String, dynamic>>.from(schedules);

      // 2. Fetch existing KRS for student in this active semester
      final List<dynamic> existing = await client
          .from('krs')
          .select('*, jadwal(*, kelas(*, mata_kuliah(*)))')
          .eq('mahasiswa_id', mId)
          .eq('semester_id', semId);

      _existingKrs = List<Map<String, dynamic>>.from(existing);

      // Determine KRS status
      if (_existingKrs.isNotEmpty) {
        // If there's an approved, then all is approved; if pending, then pending.
        final hasApproved = _existingKrs.any((k) => k['status'] == 'disetujui');
        final hasPending = _existingKrs.any((k) => k['status'] == 'menunggu');
        final hasRejected = _existingKrs.any((k) => k['status'] == 'ditolak');

        if (hasApproved) {
          _krsStatus = 'disetujui';
        } else if (hasPending) {
          _krsStatus = 'menunggu';
        } else if (hasRejected) {
          _krsStatus = 'ditolak';
        } else {
          _krsStatus = 'draft';
        }

        // Pre-select schedules
        _selectedJadwalIds.clear();
        for (var k in _existingKrs) {
          if (k['jadwal_id'] != null) {
            _selectedJadwalIds.add(k['jadwal_id'].toString());
          }
        }
      } else {
        _krsStatus = 'draft';
      }

      // Calculate SKS
      _calculateSks();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat KRS: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateSks() {
    int sum = 0;
    for (var id in _selectedJadwalIds) {
      final schedule = _availableJadwal.firstWhere((j) => j['id'].toString() == id, orElse: () => {});
      if (schedule.isNotEmpty) {
        sum += (schedule['kelas']['mata_kuliah']['sks'] as num).toInt();
      }
    }
    _totalSks = sum;
  }

  void _toggleSchedule(String id, bool checked) {
    if (_krsStatus == 'menunggu' || _krsStatus == 'disetujui') return;

    setState(() {
      if (checked) {
        _selectedJadwalIds.add(id);
      } else {
        _selectedJadwalIds.remove(id);
      }
      _calculateSks();
    });
  }

  Future<void> _submitKrs() async {
    if (_selectedJadwalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal satu mata kuliah"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_totalSks > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total SKS melebihi batas maksimum 24 SKS"), backgroundColor: Colors.orange),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajukan KRS"),
        content: Text("Yakin ingin mengajukan $_totalSks SKS ke Admin? KRS akan dikunci sampai diperiksa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ajukan"),
          )
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        final mId = widget.studentDetails['id'];
        final semId = widget.activeSemester['id'];

        // 1. Delete existing draft/rejected KRS rows for this semester
        await client.from('krs').delete().eq('mahasiswa_id', mId).eq('semester_id', semId).inFilter('status', ['draft', 'ditolak']);

        // 2. Insert new KRS rows
        final List<Map<String, dynamic>> rows = _selectedJadwalIds.map((jId) {
          return {
            'mahasiswa_id': mId,
            'jadwal_id': jId,
            'semester_id': semId,
            'status': 'menunggu',
          };
        }).toList();

        await client.from('krs').insert(rows);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("KRS berhasil diajukan!"), backgroundColor: Colors.green),
        );
        _loadKrsData();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengajukan KRS: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _krsStatus == 'menunggu' || _krsStatus == 'disetujui';

    Color badgeColor = Colors.grey;
    if (_krsStatus == 'disetujui') badgeColor = Colors.green;
    if (_krsStatus == 'menunggu') badgeColor = Colors.orange;
    if (_krsStatus == 'ditolak') badgeColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Isi Kartu Rencana Studi (KRS)"),
        automaticallyImplyLeading: !widget.isTab,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: badgeColor.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status KRS: ${_krsStatus.toUpperCase()}",
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text("Semester: ${widget.activeSemester['nama']}", style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                      if (locked)
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: AppTheme.textLight),
                            SizedBox(width: 4),
                            Text("Terkunci", style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                          ],
                        )
                    ],
                  ),
                ),
                
                // Available class list
                Expanded(
                  child: _availableJadwal.isEmpty
                      ? const Center(child: Text("Belum ada jadwal kuliah di semester aktif ini."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _availableJadwal.length,
                          itemBuilder: (context, index) {
                            final item = _availableJadwal[index];
                            final jId = item['id'].toString();
                            final k = item['kelas'] ?? {};
                            final mk = k['mata_kuliah'] ?? {};
                            final dName = k['dosen'] != null ? k['dosen']['users']['nama'] : '-';
                            final timeStr = "${item['jam_mulai'].substring(0, 5)} - ${item['jam_selesai'].substring(0, 5)}";
                            
                            final isChecked = _selectedJadwalIds.contains(jId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: CheckboxListTile(
                                value: isChecked,
                                enabled: !locked,
                                activeColor: AppTheme.primary,
                                title: Text("[${mk['kode']}] ${mk['nama']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Kelas: ${k['nama']} | SKS: ${mk['sks']} SKS"),
                                    Text("Dosen: $dName"),
                                    Text("Jadwal: ${item['hari']}, $timeStr (${(item['ruangan'] ?? '').toString().toLowerCase().contains('ruang') ? (item['ruangan'] ?? '') : "Ruang ${item['ruangan'] ?? ''}"})", style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                  ],
                                ),
                                onChanged: (val) {
                                  if (val != null) _toggleSchedule(jId, val);
                                },
                              ),
                            );
                          },
                        ),
                ),
                
                // Bottom Submit Bar
                if (!locked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: AppTheme.borderLight, width: 1.5)),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Total SKS Dipilih", style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                              Text("$_totalSks / 24 SKS", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _submitKrs,
                            child: const Text("AJUKAN KRS"),
                          )
                        ],
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
