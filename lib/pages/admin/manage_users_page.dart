import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _mahasiswaList = [];
  List<Map<String, dynamic>> _prodiList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final futures = await Future.wait([
        client.from('dosen').select('*, users(nama, email)'),
        client.from('mahasiswa').select('*, users(nama, email), program_studi(nama, kode)'),
        client.from('program_studi').select('id, nama, kode'),
      ]);

      if (mounted) {
        setState(() {
          _dosenList = List<Map<String, dynamic>>.from(futures[0] as List);
          _mahasiswaList = List<Map<String, dynamic>>.from(futures[1] as List);
          _prodiList = List<Map<String, dynamic>>.from(futures[2] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack("Gagal memuat data: $e", Colors.red);
      }
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  Future<void> _deleteUser(String userId, String nama) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Pengguna"),
        content: Text("Yakin ingin menghapus akun '$nama'? Semua data terkait (KRS, Nilai, dll) juga akan terhapus."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          )
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.rpc('admin_delete_user', params: {'p_user_id': userId});
        _snack("Pengguna berhasil dihapus", Colors.green);
        _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal menghapus: $e", Colors.red);
      }
    }
  }

  Future<void> _resetPassword(String userId, String nama) async {
    final passwordController = TextEditingController();
    bool obscureText = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Ubah Sandi '$nama'"),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: "Password Baru",
              suffixIcon: IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setDialogState(() {
                    obscureText = !obscureText;
                  });
                },
              ),
            ),
            obscureText: obscureText,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );

    if (ok == true && passwordController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.rpc('admin_reset_password', params: {
          'p_user_id': userId,
          'p_new_password': passwordController.text.trim(),
        });
        _snack("Password berhasil diubah", Colors.green);
      } catch (e) {
        _snack("Gagal mengubah password: $e", Colors.red);
      } finally {
        setState(() => _isLoading = false);
        _loadData();
      }
    }
  }

  Future<void> _addUser() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final namaController = TextEditingController();
    final nimOrNidnController = TextEditingController();
    final alamatController = TextEditingController();
    
    String role = 'mahasiswa';
    String? prodiId = _prodiList.isNotEmpty ? _prodiList.first['id'] : null;
    int angkatan = DateTime.now().year;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isMhs = role == 'mahasiswa';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Tambah Akun Baru"),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: "Role"),
                        items: const [
                          DropdownMenuItem(value: 'mahasiswa', child: Text("Mahasiswa")),
                          DropdownMenuItem(value: 'dosen', child: Text("Dosen")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => role = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama Lengkap")),
                      const SizedBox(height: 12),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                      const SizedBox(height: 12),
                      TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password")),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nimOrNidnController,
                        decoration: InputDecoration(labelText: isMhs ? "NIM" : "NIDN"),
                      ),
                      const SizedBox(height: 12),
                      if (isMhs) ...[
                        DropdownButtonFormField<String>(
                          value: prodiId,
                          decoration: const InputDecoration(labelText: "Program Studi"),
                          items: _prodiList.map((prodi) {
                            return DropdownMenuItem(
                              value: prodi['id'].toString(),
                              child: Text("${prodi['kode']} - ${prodi['nama']}"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() => prodiId = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: angkatan,
                          decoration: const InputDecoration(labelText: "Angkatan"),
                          items: List.generate(8, (i) => DateTime.now().year - i).map((yr) {
                            return DropdownMenuItem(value: yr, child: Text(yr.toString()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => angkatan = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: alamatController, maxLines: 2, decoration: const InputDecoration(labelText: "Alamat")),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Simpan")),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (emailController.text.trim().isEmpty ||
          passwordController.text.isEmpty ||
          namaController.text.trim().isEmpty ||
          nimOrNidnController.text.trim().isEmpty) {
        _snack("Semua field utama wajib diisi", Colors.orange);
        return;
      }

      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.rpc('admin_create_user', params: {
          'p_email': emailController.text.trim(),
          'p_password': passwordController.text,
          'p_role': role,
          'p_nama': namaController.text.trim(),
          'p_nim_or_nidn': nimOrNidnController.text.trim(),
          'p_program_studi_id': role == 'mahasiswa' ? prodiId : null,
          'p_angkatan': role == 'mahasiswa' ? angkatan : null,
          'p_alamat': alamatController.text.trim(),
        });
        _snack("Akun berhasil dibuat", Colors.green);
        _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal membuat akun: $e", Colors.red);
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> item, String role) async {
    final nameController = TextEditingController(text: item['users']['nama'] ?? '');
    final nimOrNidnController = TextEditingController(text: role == 'mahasiswa' ? item['nim'] : item['nidn']);
    final alamatController = TextEditingController(text: item['alamat'] ?? '');
    String? prodiId = role == 'mahasiswa' ? item['program_studi_id']?.toString() : null;
    int? angkatan = role == 'mahasiswa' ? item['angkatan'] : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isMhs = role == 'mahasiswa';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Profil ${role.toUpperCase()}"),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Lengkap")),
                      const SizedBox(height: 12),
                       TextField(
                        controller: nimOrNidnController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: isMhs ? "NIM (Tidak dapat diubah)" : "NIDN (Tidak dapat diubah)",
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isMhs) ...[
                        DropdownButtonFormField<String>(
                          value: prodiId,
                          decoration: const InputDecoration(labelText: "Program Studi"),
                          items: _prodiList.map((prodi) {
                            return DropdownMenuItem(
                              value: prodi['id'].toString(),
                              child: Text("${prodi['kode']} - ${prodi['nama']}"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() => prodiId = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: angkatan,
                          decoration: const InputDecoration(labelText: "Angkatan"),
                          items: List.generate(8, (i) => DateTime.now().year - i).map((yr) {
                            return DropdownMenuItem(value: yr, child: Text(yr.toString()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => angkatan = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: alamatController, maxLines: 2, decoration: const InputDecoration(labelText: "Alamat")),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Simpan")),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        
        // Update public.users
        await client.from('users').update({
          'nama': nameController.text.trim(),
        }).eq('id', item['user_id']);

        // Update role table
        if (role == 'mahasiswa') {
          await client.from('mahasiswa').update({
            'nim': nimOrNidnController.text.trim(),
            'program_studi_id': prodiId,
            'angkatan': angkatan,
            'alamat': alamatController.text.trim(),
          }).eq('id', item['id']);
        } else {
          await client.from('dosen').update({
            'nidn': nimOrNidnController.text.trim(),
            'alamat': alamatController.text.trim(),
          }).eq('id', item['id']);
        }

        _snack("Profil berhasil diubah", Colors.green);
        _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal memperbarui data: $e", Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Pengguna"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.supervisor_account_outlined), text: "Dosen"),
            Tab(icon: Icon(Icons.school_outlined), text: "Mahasiswa"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDosenTab(),
                _buildMahasiswaTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDosenTab() {
    if (_dosenList.isEmpty) {
      return const Center(child: Text("Belum ada data Dosen"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dosenList.length,
      itemBuilder: (context, index) {
        final item = _dosenList[index];
        final nama = item['users'] != null ? item['users']['nama'] : '';
        final email = item['users'] != null ? item['users']['email'] : '';
        final nidn = item['nidn'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NIDN: $nidn"),
                Text("Email: $email"),
                if (item['alamat'] != null) Text("Alamat: ${item['alamat']}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.vpn_key_outlined, color: Colors.amber),
                  tooltip: "Ubah Sandi",
                  onPressed: () => _resetPassword(item['user_id'].toString(), nama),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editUser(item, 'dosen'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.accent),
                  onPressed: () => _deleteUser(item['user_id'].toString(), nama),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMahasiswaTab() {
    if (_mahasiswaList.isEmpty) {
      return const Center(child: Text("Belum ada data Mahasiswa"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mahasiswaList.length,
      itemBuilder: (context, index) {
        final item = _mahasiswaList[index];
        final nama = item['users'] != null ? item['users']['nama'] : '';
        final email = item['users'] != null ? item['users']['email'] : '';
        final nim = item['nim'] ?? '';
        final prodiName = item['program_studi'] != null ? item['program_studi']['nama'] : '-';
        final angkatan = item['angkatan']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.school)),
            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NIM: $nim (Angkatan $angkatan)"),
                Text("Prodi: $prodiName"),
                Text("Email: $email"),
                if (item['alamat'] != null) Text("Alamat: ${item['alamat']}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.vpn_key_outlined, color: Colors.amber),
                  tooltip: "Ubah Sandi",
                  onPressed: () => _resetPassword(item['user_id'].toString(), nama),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editUser(item, 'mahasiswa'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.accent),
                  onPressed: () => _deleteUser(item['user_id'].toString(), nama),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
