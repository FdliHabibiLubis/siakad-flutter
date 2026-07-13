import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/theme.dart';

class DataMahasiswaPage extends StatefulWidget {
  final String role;
  const DataMahasiswaPage({super.key, required this.role});

  @override
  State<DataMahasiswaPage> createState() => _DataMahasiswaPageState();
}

class _DataMahasiswaPageState extends State<DataMahasiswaPage> {
  static const String baseUrl = "http://localhost/flutter_api/";

  List<dynamic> listMahasiswa = [];
  bool isLoading = true;
  String keyword = "";

  @override
  void initState() {
    super.initState();
    getMahasiswa();
  }

  Future<void> getMahasiswa() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("${baseUrl}get_mahasiswa.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          setState(() => listMahasiswa = data["data"]);
        }
      }
    } catch (e) {
      _snack("Gagal mengambil data: $e", Colors.red);
    }
    setState(() => isLoading = false);
  }

  List<dynamic> get filtered {
    if (keyword.isEmpty) return listMahasiswa;
    return listMahasiswa.where((item) {
      return (item['nim'] ?? '').toLowerCase().contains(keyword) ||
          (item['nama'] ?? '').toLowerCase().contains(keyword) ||
          (item['jurusan'] ?? '').toLowerCase().contains(keyword) ||
          (item['alamat'] ?? '').toLowerCase().contains(keyword) ||
          (item['username'] ?? '').toLowerCase().contains(keyword);
    }).toList();
  }

  Future<void> hapus(String id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.accent),
                SizedBox(width: 8),
                Text("Konfirmasi Hapus"),
              ],
            ),
            content: const Text("Yakin ingin menghapus data mahasiswa ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Tidak"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}hapus_mahasiswa.php"),
        body: {"id": id},
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data berhasil dihapus", Colors.green);
        getMahasiswa();
      } else {
        _snack(data["message"] ?? "Gagal menghapus", Colors.red);
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
  }

  void showEditDialog(Map<String, dynamic> item) {
    final eNama = TextEditingController(text: item['nama'] ?? '');
    final eJurusan = TextEditingController(text: item['jurusan'] ?? '');
    final eAlamat = TextEditingController(text: item['alamat'] ?? '');
    final eUsername = TextEditingController(text: item['username'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        "Edit Data Mahasiswa",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // NIM read only
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: item['nim'] ?? ''),
                    decoration: InputDecoration(
                      labelText: "NIM (tidak bisa diubah)",
                      prefixIcon: const Icon(Icons.badge, color: AppTheme.textLight),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(eNama, "Nama", Icons.person_outline),
                  _dialogField(eJurusan, "Jurusan", Icons.school_outlined),
                  _dialogFieldMulti(eAlamat, "Alamat", Icons.home_outlined),
                  _dialogField(
                    eUsername,
                    "Username",
                    Icons.account_circle_outlined,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await update(
                            id: item['id'].toString(),
                            nama: eNama.text.trim(),
                            jurusan: eJurusan.text.trim(),
                            alamat: eAlamat.text.trim(),
                            username: eUsername.text.trim(),
                          );
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text("Simpan"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> update({
    required String id,
    required String nama,
    required String jurusan,
    required String alamat,
    required String username,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}update_mahasiswa.php"),
        body: {
          "id": id,
          "nama": nama,
          "jurusan": jurusan,
          "alamat": alamat,
          "username": username,
        },
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data berhasil diupdate", Colors.green);
        getMahasiswa();
      } else {
        _snack(data["message"] ?? "Gagal update", Colors.red);
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final isAdmin = widget.role == 'admin';
    final data = filtered;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text("Data Mahasiswa (API PHP)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: getMahasiswa,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + stat bar ───────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                // Stat row
                Row(
                  children: [
                    _statChip(Icons.people, "${listMahasiswa.length}", "Total"),
                    const SizedBox(width: 8),
                    _statChip(Icons.search, "${data.length}", "Ditampilkan"),
                  ],
                ),
                const SizedBox(height: 12),
                // Search input
                TextField(
                  onChanged: (v) => setState(() => keyword = v.toLowerCase()),
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Cari nama, NIM, jurusan, username...",
                    hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Konten ─────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : data.isEmpty
                ? _buildEmpty()
                : isWide
                ? _buildTable(data, isAdmin)
                : _buildCardList(data, isAdmin),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // TABEL - web, full width pakai Expanded agar pas
  // ════════════════════════════════════════════════════
  Widget _buildTable(List<dynamic> data, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppTheme.primary,
              child: Row(
                children: [
                  const Icon(Icons.table_chart_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Daftar Mahasiswa (Tabel Dinamis)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${data.length} mahasiswa",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // ── Header kolom ─────────────────────────────
            Container(
              color: AppTheme.primary.withOpacity(0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 40, child: _H("No")),
                  const SizedBox(width: 16),
                  const Expanded(flex: 2, child: _H("NIM")),
                  const Expanded(flex: 3, child: _H("Nama")),
                  const Expanded(flex: 2, child: _H("Jurusan")),
                  const Expanded(flex: 3, child: _H("Alamat")),
                  const Expanded(flex: 2, child: _H("Username")),
                  if (isAdmin) const SizedBox(width: 80, child: _H("Aksi")),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // ── Baris data ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: data.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    final rowColor = i % 2 == 0
                        ? Colors.white
                        : AppTheme.primary.withOpacity(0.015);
                    return Container(
                      color: rowColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // No
                          SizedBox(
                            width: 40,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${i + 1}",
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // NIM
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['nim'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Nama + avatar
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                                  child: Text(
                                    (item['nama'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['nama'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Jurusan
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _jurusanBadge(item['jurusan'] ?? ''),
                            ),
                          ),
                          // Alamat
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['alamat'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                            ),
                          ),
                          // Username
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['username'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                          // Aksi
                          if (isAdmin)
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _aksiBtn(
                                    Icons.edit_outlined,
                                    Colors.orange,
                                    "Edit",
                                    () => showEditDialog(item),
                                  ),
                                  const SizedBox(width: 8),
                                  _aksiBtn(
                                    Icons.delete_outline,
                                    AppTheme.accent,
                                    "Hapus",
                                    () => hapus(item['id'].toString()),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // CARD LIST - mobile
  // ════════════════════════════════════════════════════
  Widget _buildCardList(List<dynamic> data, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text(
                        (item['nama'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['nama'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (isAdmin) ...[
                      _aksiBtn(
                        Icons.edit_outlined,
                        Colors.orange,
                        "Edit",
                        () => showEditDialog(item),
                      ),
                      const SizedBox(width: 4),
                      _aksiBtn(
                        Icons.delete_outline,
                        AppTheme.accent,
                        "Hapus",
                        () => hapus(item['id'].toString()),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _cardRow(Icons.badge_outlined, "NIM", item['nim'] ?? ''),
                _cardRow(Icons.school_outlined, "Jurusan", item['jurusan'] ?? ''),
                _cardRow(Icons.home_outlined, "Alamat", item['alamat'] ?? ''),
                _cardRow(
                  Icons.account_circle_outlined,
                  "Username",
                  item['username'] ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────
  Widget _statChip(IconData icon, String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            "$val $label",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _jurusanBadge(String jurusan) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
        ),
        child: Text(
          jurusan,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _aksiBtn(IconData icon, Color color, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _cardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ),
          const Text(": ", style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            keyword.isEmpty
                ? "Belum ada data mahasiswa"
                : "Data tidak ditemukan",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _dialogFieldMulti(
    TextEditingController c,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
        fontSize: 13,
      ),
    );
  }
}
