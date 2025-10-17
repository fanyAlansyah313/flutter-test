import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const String baseUrl = 'http://10.0.2.2:8000';

class TambahScreen extends StatefulWidget {
  const TambahScreen({super.key});

  @override
  State<TambahScreen> createState() => _TambahScreenState();
}

class _TambahScreenState extends State<TambahScreen> {
  final _formKey = GlobalKey<FormState>();
  final txtName = TextEditingController();
  final txtTanggal = TextEditingController();
  final txtAgama = TextEditingController();
  final txtImage = TextEditingController();
  final txtFiles = TextEditingController();

  final Map<String, bool> hobiOptions = {
    'Membaca': false,
    'Musik': false,
    'Olahraga': false,
    'Traveling': false,
  };

  String statusSelected = 'Single';

  List<dynamic> provinsiList = [];
  List<dynamic> kabupatenList = [];
  List<dynamic> desaList = [];

  String? selectedProvinsi;
  String? selectedKabupaten;
  String? selectedDesa;

  XFile? pickedImageFile;
  PlatformFile? pickedAnyFile;

  @override
  void initState() {
    super.initState();
    fetchProvinsi();
  }

  //api lokasi
  Future<void> fetchProvinsi() async {
    try {
      final url = Uri.parse('$baseUrl/api/wilayah/provinces');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          provinsiList = jsonDecode(res.body);
        });
      } else {
        debugPrint('fetchProvinsi status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetch provinsi: $e');
    }
  }

  Future<void> fetchKabupaten(String provinsiId) async {
    setState(() {
      kabupatenList = [];
      desaList = [];
      selectedKabupaten = null;
      selectedDesa = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/wilayah/regencies/$provinsiId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          kabupatenList = jsonDecode(res.body);
        });
      } else {
        debugPrint('fetchKabupaten status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetch kabupaten: $e');
    }
  }

  Future<void> fetchDesa(String kabupatenId) async {
    setState(() {
      desaList = [];
      selectedDesa = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/wilayah/districts/$kabupatenId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          desaList = jsonDecode(res.body);
        });
      } else {
        debugPrint('fetchDesa status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetch desa: $e');
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          pickedImageFile = image;
          txtImage.text = image.path; // lokal path (kamu bisa upload nanti)
        });
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withReadStream: false);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedAnyFile = result.files.first;
          txtFiles.text = pickedAnyFile!.path ?? pickedAnyFile!.name;
        });
      }
    } catch (e) {
      debugPrint('pickFile error: $e');
    }
  }

  Future<void> submit() async {
  if (!_formKey.currentState!.validate()) return;

  final chosenHobi = hobiOptions.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .join(', ');

  try {
    var uri = Uri.parse('$baseUrl/people'); 

    var request = http.MultipartRequest('POST', uri);

    request.fields['name'] = txtName.text.trim();
    request.fields['tanggal_lahir'] = txtTanggal.text.trim();
    request.fields['agama'] = txtAgama.text.trim();
    request.fields['provinsi'] = selectedProvinsi ?? '';
    request.fields['kabupaten'] = selectedKabupaten ?? '';
    request.fields['desa'] = selectedDesa ?? '';
    request.fields['hobi'] = chosenHobi;
    request.fields['status_pernikahan'] = statusSelected;

    if (pickedImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        pickedImageFile!.path,
        filename: pickedImageFile!.name,
      ));
    }

    if (pickedAnyFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        pickedAnyFile!.path!,
        filename: pickedAnyFile!.name,
      ));
    }

    var response = await request.send();
    var resBody = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      var data = jsonDecode(resBody.body);
      Navigator.pop(context, data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal tambah data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    txtName.dispose();
    txtTanggal.dispose();
    txtAgama.dispose();
    txtImage.dispose();
    txtFiles.dispose();
    super.dispose();
  }

  Widget _inputField(TextEditingController c, String label, bool wajib, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        validator: wajib ? (v) => v == null || v.isEmpty ? '$label wajib' : null : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<dynamic> items,
    required String label,
    required Function(String) onChanged,
    String nameKey = 'name',
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map<DropdownMenuItem<String>>((item) {
        final display = (item[nameKey] ?? item['nama'] ?? item['name'] ?? '').toString();
        final val = (item['id'] ?? item['province_id'] ?? item['regency_id'] ?? item['district_id'] ?? '').toString();
        return DropdownMenuItem<String>(value: val, child: Text(display));
      }).toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _inputField(txtName, 'Nama', true),
              _inputField(txtTanggal, 'Tanggal (YYYY-MM-DD)', true),
              _inputField(txtAgama, 'Agama', false),

              const SizedBox(height: 8),
            _sectionTitle('Hobi'),
            Wrap(
              spacing: 12,
              runSpacing: 0,
              children: hobiOptions.keys.map((key) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: hobiOptions[key],
                      activeColor: Colors.indigo,
                      onChanged: (val) {
                        setState(() {
                          hobiOptions[key] = val ?? false;
                        });
                      },
                    ),
                    Text(key),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            _sectionTitle('Status Pernikahan'),
              Row(
                children: ['Single', 'Menikah', 'Cerai'].map((status) {
                  return Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: status,
                          groupValue: statusSelected,
                          activeColor: Colors.indigo,
                          onChanged: (val) {
                            if (val != null) setState(() => statusSelected = val);
                          },
                        ),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _sectionTitle('Lokasi'),
              const SizedBox(height: 6),
              _dropdown(
                value: selectedProvinsi,
                items: provinsiList,
                label: 'Pilih Provinsi',
                onChanged: (val) {
                  setState(() => selectedProvinsi = val);
                  fetchKabupaten(val);
                },
                nameKey: 'name',
              ),
              const SizedBox(height: 12),
              _dropdown(
                value: selectedKabupaten,
                items: kabupatenList,
                label: 'Pilih Kabupaten',
                onChanged: (val) {
                  setState(() => selectedKabupaten = val);
                  fetchDesa(val);
                },
                nameKey: 'name',
              ),
              const SizedBox(height: 12),
              _dropdown(
                value: selectedDesa,
                items: desaList,
                label: 'Pilih Desa',
                onChanged: (val) => setState(() => selectedDesa = val),
                nameKey: 'name',
              ),

              const SizedBox(height: 16),
              _sectionTitle('Upload Media'),
              Row(children: [
                Expanded(child: _inputField(txtImage, 'Gambar (dipilih)', false, readOnly: true)),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: pickImage,
                  child: const Icon(Icons.image, color: Colors.white),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _inputField(txtFiles, 'File (dipilih)', false, readOnly: true)),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: pickFile,
                  child: const Icon(Icons.attach_file, color: Colors.white),
                ),
              ]),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('SIMPAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
