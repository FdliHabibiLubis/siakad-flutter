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

      final studentProdiId = widget.studentDetails['program_studi_id'] ?? 
                             widget.studentDetails['program_studi']?['id'];
      final allSchedules = List<Map<String, dynamic>>.from(schedules);

      _availableJadwal = allSchedules.where((j) {
        final mk = j['kelas']?['mata_kuliah'];
        if (mk == null) return false;
        final mkProdiId = mk['program_studi_id'] ?? mk['program_studi']?['id'];
        
        // If the course has no program studi, it is a general course (visible to all).
        // Otherwise, it must match the student's program studi exactly.
        if (mkProdiId == null) return true;
        return mkProdiId == studentProdiId;
      }).toList();

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
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              widget.studentDetails['program_studi'] != null
                                  ? "Belum ada jadwal kuliah untuk program studi ${widget.studentDetails['program_studi']['nama']} di semester aktif ini."
                                  : "Belum ada jadwal kuliah di semester aktif ini.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textLight),
                            ),
                          ),
                        )
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isChecked ? AppTheme.primary : AppTheme.borderLight,
                          width: isChecked ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: locked
                              ? null
                              : () => _toggleSchedule(jId, !isChecked),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Selection Strip Indicator
                                Container(
                                  width: 5,
                                  color: isChecked ? AppTheme.primary : Colors.transparent,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                mk['kode'] ?? '',
                                                style: const TextStyle(
                                                  color: AppTheme.secondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "${mk['sks']} SKS",
                                                style: const TextStyle(
                                                  color: AppTheme.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          mk['nama'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 14, color: AppTheme.textLight),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Dosen: $dName",
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.textLight),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Jadwal: ${item['hari']}, $timeStr",
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                                              ),
                                            ),
                                            if (item['ruangan'] != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "Ruang ${item['ruangan']}",
                                                  style: TextStyle(fontSize: 9, color: AppTheme.textLight.withOpacity(0.9), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Selection circle indicator on the right side
                                Container(
                                  padding: const EdgeInsets.only(right: 16),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isChecked ? AppTheme.primary : AppTheme.textLight.withOpacity(0.4),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
