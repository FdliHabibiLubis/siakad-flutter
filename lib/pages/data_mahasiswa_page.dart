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
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF3F51B5)),
                      SizedBox(width: 8),
                      Text(
                        "Edit Data Mahasiswa",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
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
                      prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(eNama, "Nama", Icons.person_outline),
                  _dialogField(eJurusan, "Jurusan", Icons.school),
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
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        title: const Text("Data Mahasiswa"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: getMahasiswa,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + stat bar ───────────────────────────
          Container(
            color: const Color(0xFF3F51B5),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                const SizedBox(height: 10),
                // Search
                TextField(
                  onChanged: (v) => setState(() => keyword = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Cari nama, NIM, jurusan, username...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // ── Konten ─────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
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
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              color: const Color(0xFF1A237E),
              child: Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    "Daftar Mahasiswa",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${data.length} mahasiswa",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ── Header kolom ─────────────────────────────
            Container(
              color: const Color(0xFFE8EAF6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Baris data ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: data.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    final rowColor = i % 2 == 0
                        ? Colors.white
                        : const Color(0xFFF5F6FF);
                    return Container(
                      color: rowColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // No
                          SizedBox(
                            width: 40,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8EAF6),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${i + 1}",
                                style: const TextStyle(
                                  color: Color(0xFF3F51B5),
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
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.w600,
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
                                  backgroundColor: const Color(
                                    0xFF3F51B5,
                                  ).withOpacity(0.12),
                                  child: Text(
                                    (item['nama'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF3F51B5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    item['nama'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
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
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          // Username
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['username'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
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
                                  const SizedBox(width: 4),
                                  _aksiBtn(
                                    Icons.delete_outline,
                                    Colors.red,
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
      padding: const EdgeInsets.all(14),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF3F51B5),
                      child: Text(
                        (item['nama'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
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
                      _aksiBtn(
                        Icons.delete_outline,
                        Colors.red,
                        "Hapus",
                        () => hapus(item['id'].toString()),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _cardRow(Icons.badge, "NIM", item['nim'] ?? ''),
                _cardRow(Icons.school, "Jurusan", item['jurusan'] ?? ''),
                _cardRow(Icons.home_outlined, "Alamat", item['alamat'] ?? ''),
                _cardRow(
                  Icons.account_circle,
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            "$val $label",
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
          color: const Color(0xFF3F51B5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.3)),
        ),
        child: Text(
          jurusan,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF3F51B5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
          margin: const EdgeInsets.only(left: 4),
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
          Icon(icon, size: 15, color: const Color(0xFF3F51B5)),
          const SizedBox(width: 6),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Text(": ", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
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
          prefixIcon: Icon(icon, color: const Color(0xFF3F51B5)),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
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
          prefixIcon: Icon(icon, color: const Color(0xFF3F51B5)),
          alignLabelWithHint: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}

// Widget kecil untuk header kolom tabel
class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
        fontSize: 13,
      ),
    );
  }
}
