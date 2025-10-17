// main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tes_rst/screens/tambah_data.dart';
import 'package:url_launcher/url_launcher.dart';


const String baseUrl = 'http://10.0.2.2:8000';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Person> persons = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPersons();
  }

  Future<void> fetchPersons() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/people'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final listJson = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        if (listJson is List) {
          persons = listJson.map((e) => Person.fromJson(e)).toList();
        } else {
          persons = [];
        }
      } else {
        showSnack('Gagal load: ${response.statusCode}');
      }
    } catch (e) {
      showSnack('Fetch error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> addPerson(Map<String, dynamic> newPerson) async {
    try {
      newPerson = _normalizePathsForSend(newPerson);
      final response = await http.post(
        Uri.parse('$baseUrl/api/people'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newPerson),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        showSnack('Berhasil menambah person');
        await fetchPersons();
      } else {
        showSnack('Gagal tambah: ${response.statusCode}');
      }
    } catch (e) {
      showSnack('Add error: $e');
    }
  }

  Future<void> updatePerson(int id, Map<String, dynamic> updatedData) async {
    try {
      updatedData = _normalizePathsForSend(updatedData);
      final response = await http.put(
        Uri.parse('$baseUrl/api/people/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        showSnack('Berhasil update');
        await fetchPersons();
      } else {
        showSnack('Gagal update: ${response.statusCode}');
      }
    } catch (e) {
      showSnack('Update error: $e');
    }
  }

  Future<void> deletePerson(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/people/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          persons.removeWhere((p) => p.id == id);
        });
        showSnack('Data dihapus');
      } else {
        showSnack('Gagal hapus: ${response.statusCode}');
      }
    } catch (e) {
      showSnack('Delete error: $e');
    }
  }

  void showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Map<String, dynamic> _normalizePathsForSend(Map<String, dynamic> map) {
    final res = Map<String, dynamic>.from(map);
    if (res['image'] is String) {
      res['image'] = (res['image'] as String).replaceFirst('$baseUrl/', '');
    }
    if (res['files'] is String) {
      res['files'] = (res['files'] as String).replaceFirst('$baseUrl/', '');
    }
    return res;
  }

    String _fullUrl(String maybeRelative) {
      if (maybeRelative.startsWith('http')) return maybeRelative;
      return '$baseUrl/storage/${maybeRelative.replaceFirst(RegExp(r'^/+'), '')}';
    } 

    Future<void> openFile(String url) async {
    final full = _fullUrl(url);
    final uri = Uri.parse(full);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showSnack('Tidak bisa membuka file: $full');
    }
  }

  Future<void> showPersonDialog({Person? person}) async {
  final isEdit = person != null;
  final txtImage = TextEditingController(text: person == null ? '' : _fullUrl(person.image));
  final txtFiles = TextEditingController(text: person == null ? '' : _fullUrl(person.files));

  final txtName = TextEditingController(text: person?.name ?? '');
  final txtTanggal = TextEditingController(text: person == null ? '' : person.tanggalLahir.toIso8601String().split('T')[0]);
  final _formKey = GlobalKey<FormState>();

  Map<String, bool> hobiOptions = {
    "Membaca": person?.hobi.contains("Membaca") ?? false,
    "Menulis": person?.hobi.contains("Menulis") ?? false,
    "Berenang": person?.hobi.contains("Berenang") ?? false,
  };

  String statusSelected = person?.statusPernikahan ?? "Single";
  final agamaOptions = ["Islam", "Kristen", "Katolik", "Hindu", "Budha"];
  String? agamaSelected = person?.agama ?? agamaOptions.first;

  await showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isEdit ? 'Edit Data Person' : 'Tambah Data Person',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _customField(txtName, 'Nama', true),
                  _customField(txtTanggal, 'Tanggal Lahir', true),
                  const SizedBox(height: 10),
                  const Text('Agama', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: agamaSelected,
                    items: agamaOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => agamaSelected = val),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Hobi', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 12,
                    children: hobiOptions.keys.map((key) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                              value: hobiOptions[key],
                              onChanged: (val) =>
                                  setState(() => hobiOptions[key] = val ?? false)),
                          Text(key),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  const Text('Status Pernikahan',style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ['Single', 'Menikah', 'Cerai'].map((status) {
                      final isSelected = statusSelected == status;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: Colors.indigo,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  const Text('Gambar', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (txtImage.text.isNotEmpty)
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: txtImage.text.startsWith('http')
                            ? Image.network(txtImage.text, fit: BoxFit.cover)
                            : Image.file(File(txtImage.text), fit: BoxFit.cover),
                      ),
                    )
                  else
                    const Text('Tidak ada gambar', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),

                  // File
                  const Text('File', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (txtFiles.text.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            txtFiles.text.split('/').last, // tampilkan nama file saja
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                  const Text('Tidak ada file', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Batal')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final payload = {
                            "name": txtName.text.trim(),
                            "tanggal_lahir": txtTanggal.text.trim(),
                            "agama": agamaSelected ?? '',
                            "hobi": hobiOptions.entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .join(', '),
                            "status_pernikahan": statusSelected,
                          };

                          Navigator.of(ctx).pop();
                          if (isEdit) {
                            await updatePerson(person.id, payload);
                          } else {
                            await addPerson(payload);
                          }
                        },
                        child: Text(isEdit ? 'Simpan' : 'Tambah'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _customField(TextEditingController controller, String label,
    [bool required = false]) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Manager'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Data', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahScreen()),
            );
            if (result != null && result is Map<String, dynamic>) {
              await addPerson(result);
            }
          },
        ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPersons,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : persons.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      const Icon(Icons.people_alt_outlined, size: 72, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Center(child: Text('Belum ada data. Tekan + untuk tambah.', style: TextStyle(color: Colors.grey))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: persons.length,
                    itemBuilder: (context, i) {
                      final p = persons[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.indigo, // garis tegas
                            width: 1.3,
                          ),
                        ),
                        elevation: 4,
                        shadowColor: Colors.indigo.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // IMAGE (left)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                        _fullUrl(p.image),
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Image error: $error');
                                          return Container(
                                            width: 84,
                                            height: 84,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // MIDDLE: INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text('${p.provinsi} · ${p.kabupaten}', style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    Text('Lahir: ${p.tanggalLahir.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    Text('Agama: ${p.agama}'),
                                    Text('Provinsi: ${p.provinsi}'),
                                    const SizedBox(height: 6),
                                    Text('Kabupaten: ${p.kabupaten}'),
                                    const SizedBox(height: 6),
                                    Text('Desa: ${p.desa}'),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Chip(
                                          label: Text(p.hobi.isEmpty ? '—' : p.hobi),
                                          backgroundColor: Colors.indigo.shade100,
                                          labelStyle: const TextStyle(color: Colors.indigo),
                                        ),
                                        Chip(
                                          label: Text(p.statusPernikahan),
                                          backgroundColor: Colors.orange.shade100,
                                          labelStyle: const TextStyle(color: Colors.deepOrange),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // RIGHT: ACTIONS
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.indigo),
                                    onPressed: () {
                                      final full = _fullUrl(p.files);
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              full,
                                              errorBuilder: (_, __, ___) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Text('Gambar tidak dapat dimuat'),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => showPersonDialog(person: p),
                                    icon: const Icon(Icons.edit_rounded, color: Colors.green),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Konfirmasi Hapus'),
                                          content: Text('Hapus data ${p.name}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await deletePerson(p.id);
                                      }
                                    },
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ------------------ Person Model ------------------
class Person {
  final int id;
  final String name;
  final DateTime tanggalLahir;
  final String agama;
  final String provinsi;
  final String kabupaten;
  final String desa;
  final String hobi;
  final String statusPernikahan;
  final String image; // stored as relative path in backend
  final String files; // stored as relative path in backend

  Person({
    required this.id,
    required this.name,
    required this.tanggalLahir,
    required this.agama,
    required this.provinsi,
    required this.kabupaten,
    required this.desa,
    required this.hobi,
    required this.statusPernikahan,
    required this.image,
    required this.files,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? '',
      tanggalLahir: DateTime.parse(json['tanggal_lahir'] ?? DateTime.now().toIso8601String()),
      agama: json['agama'] ?? '',
      provinsi: json['provinsi'] ?? '',
      kabupaten: json['kabupaten'] ?? '',
      desa: json['desa'] ?? '',
      hobi: json['hobi'] ?? '',
      statusPernikahan: json['status_pernikahan'] ?? '',
      image: json['image'] ?? '',
      files: json['files'] ?? '',
    );
  }
}
