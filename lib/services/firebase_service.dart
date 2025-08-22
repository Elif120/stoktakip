import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/urun.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'urunler';

  // Ürün ekleme
  Future<String> urunEkle(Urun urun) async {
    try {
      urun.guncellemeTarihi = DateTime.now();
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(urun.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Tüm ürünleri getirme - Stream
  Stream<List<Urun>> tumUrunleriGetirStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('ad')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Urun.fromFirestore(doc))
        .toList());
  }

  // Tüm ürünleri getirme - Future
  Future<List<Urun>> tumUrunleriGetir() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('ad')
          .get();

      return snapshot.docs
          .map((doc) => Urun.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ürünler getirilirken hata oluştu: $e');
    }
  }

  // Ürün güncelleme
  Future<void> urunGuncelle(Urun urun) async {
    try {
      if (urun.id == null) {
        throw Exception('Ürün ID\'si bulunamadı');
      }

      urun.guncellemeTarihi = DateTime.now();
      await _firestore
          .collection(_collectionName)
          .doc(urun.id)
          .update(urun.toMap());
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Ürün silme
  Future<void> urunSil(String urunId) async {
    try {
      // Önce ürünü getir
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(urunId)
          .get();

      if (doc.exists) {
        Urun urun = Urun.fromFirestore(doc);

        // Eğer fotoğraf varsa onu da sil
        if (urun.fotoUrl != null && urun.fotoUrl!.isNotEmpty) {
          await fotoSil(urun.fotoUrl!);
        }

        // Ürünü sil
        await _firestore.collection(_collectionName).doc(urunId).delete();
      }
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Ürün arama
  Future<List<Urun>> urunAra(String anahtar) async {
    try {
      // Firestore'da text search için birden fazla sorgu yapıyoruz
      List<Urun> tumUrunler = await tumUrunleriGetir();

      String arananKelime = anahtar.toLowerCase();
      return tumUrunler.where((urun) =>
      urun.ad.toLowerCase().contains(arananKelime) ||
          urun.kategori.toLowerCase().contains(arananKelime) ||
          urun.barkod.contains(anahtar)).toList();
    } catch (e) {
      throw Exception('Ürün aranırken hata oluştu: $e');
    }
  }

  // ID'ye göre ürün getirme
  Future<Urun?> urunGetir(String urunId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(urunId)
          .get();

      if (doc.exists) {
        return Urun.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ürün getirilirken hata oluştu: $e');
    }
  }

  // Kategoriye göre ürünleri getirme
  Future<List<Urun>> kategoriUrunleriGetir(String kategori) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('kategori', isEqualTo: kategori)
          .orderBy('ad')
          .get();

      return snapshot.docs
          .map((doc) => Urun.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Kategori ürünleri getirilirken hata oluştu: $e');
    }
  }

  // Düşük stoklu ürünleri getirme
  Future<List<Urun>> dusukStokUrunleriGetir(int minStok) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('stok_miktari', isLessThan: minStok)
          .orderBy('stok_miktari')
          .get();

      return snapshot.docs
          .map((doc) => Urun.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Düşük stok ürünleri getirilirken hata oluştu: $e');
    }
  }

  // Barkoda göre ürün getirme
  Future<Urun?> barkodIleUrunGetir(String barkod) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('barkod', isEqualTo: barkod)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Urun.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Barkod ile ürün aranırken hata oluştu: $e');
    }
  }

  // Fotoğraf yükleme
  Future<String> fotoYukle(File fotoFile, String urunId) async {
    try {
      String fileName = '${urunId}_${Uuid().v4()}.jpg';
      Reference ref = _storage.ref().child('urun_fotograflari/$fileName');

      UploadTask uploadTask = ref.putFile(fotoFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
    }
  }

  // Fotoğraf silme
  Future<void> fotoSil(String fotoUrl) async {
    try {
      Reference ref = _storage.refFromURL(fotoUrl);
      await ref.delete();
    } catch (e) {
      // Fotoğraf silinmese de hata fırlatmayalım
      print('Fotoğraf silinirken hata oluştu: $e');
    }
  }

  // Toplu veri güncelleme (batch)
  Future<void> topluGuncelleme(List<Urun> urunler) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (Urun urun in urunler) {
        if (urun.id != null) {
          urun.guncellemeTarihi = DateTime.now();
          DocumentReference docRef = _firestore
              .collection(_collectionName)
              .doc(urun.id);
          batch.update(docRef, urun.toMap());
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu güncelleme sırasında hata oluştu: $e');
    }
  }

  // İstatistik verileri
  Future<Map<String, dynamic>> istatistikleriGetir() async {
    try {
      List<Urun> tumUrunler = await tumUrunleriGetir();

      Map<String, int> kategoriSayilari = {};
      Map<String, double> kategoriDegerleri = {};
      double toplamDeger = 0;
      int dusukStokSayisi = 0;

      for (Urun urun in tumUrunler) {
        // Kategori sayıları
        kategoriSayilari[urun.kategori] =
            (kategoriSayilari[urun.kategori] ?? 0) + 1;

        // Kategori değerleri
        double urunDegeri = urun.fiyat * urun.stokMiktari;
        kategoriDegerleri[urun.kategori] =
            (kategoriDegerleri[urun.kategori] ?? 0) + urunDegeri;

        // Toplam değer
        toplamDeger += urunDegeri;

        // Düşük stok kontrolü
        if (urun.stokMiktari < 5) {
          dusukStokSayisi++;
        }
      }

      return {
        'toplam_urun': tumUrunler.length,
        'toplam_deger': toplamDeger,
        'dusuk_stok_sayisi': dusukStokSayisi,
        'kategori_sayilari': kategoriSayilari,
        'kategori_degerleri': kategoriDegerleri,
      };
    } catch (e) {
      throw Exception('İstatistikler getirilirken hata oluştu: $e');
    }
  }
}