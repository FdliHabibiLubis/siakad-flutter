import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future getMahasiswa() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("${baseUrl}get_mahasiswa.php"));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data["success"] == true) {
          setState(() => listMahasiswa = data["data"]);
        }
      }
    } catch (e) {
      _snack("Gagal mengambil data: $e", Colors.red);
    }
    setState(() => isLoading = false);
  }

  // Filter berdasarkan keyword pencarian
  List<dynamic> get filteredList {
    if (keyword.isEmpty) return listMahasiswa;
    return listMahasiswa.where((item) {
      return item['nim'].toString().toLowerCase().contains(keyword) ||
          item['nama'].toString().toLowerCase().contains(keyword) ||
          item['jurusan'].toString().toLowerCase().contains(keyword) ||
          item['alamat'].toString().toLowerCase().contains(keyword);
    }).toList();
  }

  Future hapus(String id) async {
    bool konfirmasi =
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!konfirmasi) return;

    try {
      final res = await http.post(
        Uri.parse("${baseUrl}hapus_mahasiswa.php"),
        body: {"id": id},
      );
      var data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data Berhasil Dihapus", const Color(0xFF43A047));
        getMahasiswa();
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
  }

  void showEditDialog(Map<String, dynamic> item) {
    final eNim = TextEditingController(text: item['nim']);
    final eNama = TextEditingController(text: item['nama']);
    final eJurusan = TextEditingController(text: item['jurusan']);
    final eAlamat = TextEditingController(text: item['alamat']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF3F51B5)),
            SizedBox(width: 8),
            Text("Edit Data Mahasiswa"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eNim,
                decoration: const InputDecoration(
                  labelText: "NIM",
                  prefixIcon: Icon(Icons.badge, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eNama,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFF3F51B5),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eJurusan,
                decoration: const InputDecoration(
                  labelText: "Jurusan",
                  prefixIcon: Icon(Icons.school, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eAlamat,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Alamat",
                  prefixIcon: Icon(
                    Icons.home_outlined,
                    color: Color(0xFF3F51B5),
                  ),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await updateMahasiswa(
                item['id'].toString(),
                eNim.text,
                eNama.text,
                eJurusan.text,
                eAlamat.text,
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future updateMahasiswa(
    String id,
    String nimVal,
    String namaVal,
    String jurusanVal,
    String alamatVal,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}update_mahasiswa.php"),
        body: {
          "id": id,
          "nim": nimVal,
          "nama": namaVal,
          "jurusan": jurusanVal,
          "alamat": alamatVal,
        },
      );
      var data = jsonDecode(res.body);
      if (data["success"] == true) {
        _snack("Data Berhasil Diupdate", const Color(0xFF43A047));
        getMahasiswa();
      } else {
        _snack("Data Gagal Diupdate", Colors.red);
      }
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
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
  Widget build(BuildContext context) {
    bool isAdmin = widget.role == "admin";
    List<dynamic> displayed = filteredList;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text("Data Mahasiswa"),
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
          // Header info + search
          Container(
            decoration: const BoxDecoration(color: Color(0xFF3F51B5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Statistik
                Row(
                  children: [
                    _statCard(Icons.people, "${listMahasiswa.length}", "Total"),
                    const SizedBox(width: 10),
                    _statCard(
                      Icons.search,
                      "${displayed.length}",
                      "Ditampilkan",
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      isAdmin ? "Admin" : "User",
                      "Role",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  onChanged: (val) =>
                      setState(() => keyword = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Cari NIM, nama, jurusan, alamat...",
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

          // Konten tabel
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
                  )
                : displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 70,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          keyword.isEmpty
                              ? "Belum ada data mahasiswa"
                              : "Data tidak ditemukan",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      var item = displayed[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF3F51B5,
                            ).withOpacity(0.1),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item['nama'] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge,
                                    size: 13,
                                    color: Color(0xFF3F51B5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['nim'] ?? "",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.school,
                                    size: 13,
                                    color: Color(0xFF3F51B5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['jurusan'] ?? "",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.home_outlined,
                                    size: 13,
                                    color: Color(0xFF3F51B5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['alamat'] ?? "",
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Tombol aksi hanya admin
                          trailing: isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                        size: 22,
                                      ),
                                      tooltip: "Edit",
                                      onPressed: () => showEditDialog(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                      tooltip: "Hapus",
                                      onPressed: () =>
                                          hapus(item['id'].toString()),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
