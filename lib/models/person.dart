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