import 'package:cloud_firestore/cloud_firestore.dart';

class Urun {
  String? id;
  String ad;
  String kategori;
  int stokMiktari;
  double fiyat;
  String aciklama;
  String? fotoUrl;
  String barkod;
  DateTime olusturmaTarihi;
  DateTime guncellemeTarihi;

  Urun({
    this.id,
    required this.ad,
    required this.kategori,
    required this.stokMiktari,
    required this.fiyat,
    required this.aciklama,
    this.fotoUrl,
    required this.barkod,
    DateTime? olusturmaTarihi,
    DateTime? guncellemeTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now(),
        guncellemeTarihi = guncellemeTarihi ?? DateTime.now();

  // Firestore'a kaydetmek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'kategori': kategori,
      'stok_miktari': stokMiktari,
      'fiyat': fiyat,
      'aciklama': aciklama,
      'foto_url': fotoUrl,
      'barkod': barkod,
      'olusturma_tarihi': Timestamp.fromDate(olusturmaTarihi),
      'guncelleme_tarihi': Timestamp.fromDate(guncellemeTarihi),
    };
  }

  // Firestore'dan okumak için Map'ten dönüştürme
  factory Urun.fromMap(Map<String, dynamic> map, String documentId) {
    return Urun(
      id: documentId,
      ad: map['ad'] ?? '',
      kategori: map['kategori'] ?? '',
      stokMiktari: map['stok_miktari'] ?? 0,
      fiyat: (map['fiyat'] ?? 0.0).toDouble(),
      aciklama: map['aciklama'] ?? '',
      fotoUrl: map['foto_url'],
      barkod: map['barkod'] ?? '',
      olusturmaTarihi: (map['olusturma_tarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guncellemeTarihi: (map['guncelleme_tarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // DocumentSnapshot'tan oluşturma
  factory Urun.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Urun.fromMap(data, doc.id);
  }

  // Ürün kopyalama metodu
  Urun copyWith({
    String? id,
    String? ad,
    String? kategori,
    int? stokMiktari,
    double? fiyat,
    String? aciklama,
    String? fotoUrl,
    String? barkod,
    DateTime? olusturmaTarihi,
    DateTime? guncellemeTarihi,
  }) {
    return Urun(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      kategori: kategori ?? this.kategori,
      stokMiktari: stokMiktari ?? this.stokMiktari,
      fiyat: fiyat ?? this.fiyat,
      aciklama: aciklama ?? this.aciklama,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      barkod: barkod ?? this.barkod,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
    );
  }

  @override
  String toString() {
    return 'Urun{id: $id, ad: $ad, kategori: $kategori, stokMiktari: $stokMiktari, fiyat: $fiyat}';
  }
}