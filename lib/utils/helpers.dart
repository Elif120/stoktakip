import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';

class AppHelpers {
  static String barkodUret() {
    final random = Random();
    String barkod = '';
    for (int i = 0; i < 13; i++) {
      barkod += random.nextInt(10).toString();
    }
    return barkod;
  }

  static String paraFormati(double tutar) {
    return '₺${tutar.toStringAsFixed(2)}';
  }

  static bool dusukStokMu(int stokMiktari, {int minStok = 5}) {
    return stokMiktari < minStok;
  }

  static Color kategoriRengi(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'elektronik':
        return Colors.blue;
      case 'ev eşyası':
        return Colors.orange;
      case 'giyim':
        return Colors.purple;
      case 'kitap':
        return Colors.brown;
      case 'spor':
        return Colors.green;
      case 'kozmetik':
        return Colors.pink;
      case 'gıda':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String metinKisalt(String metin, int maxUzunluk) {
    if (metin.length <= maxUzunluk) return metin;
    return '${metin.substring(0, maxUzunluk)}...';
  }

  static String tarihFormati(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}/'
        '${tarih.month.toString().padLeft(2, '0')}/'
        '${tarih.year}';
  }

  static void basariMesaji(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void hataMesaji(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void yukleniyorMesaji(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text(mesaj),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> onayDialoguGoster(
      BuildContext context,
      String baslik,
      String mesaj,
      ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(baslik),
          content: Text(mesaj),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Onayla', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static void loadingDialogGoster(BuildContext context, String mesaj) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(mesaj)),
            ],
          ),
        );
      },
    );
  }

  static void loadingDialogKapat(BuildContext context) {
    Navigator.of(context).pop();
  }

  // İnternet bağlantısı kontrolü (basit)
  static Future<bool> internetVarMi() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Dosya boyutu kontrolü
  static bool dosyaBoyutuGecerliMi(File file, {int maxMB = 5}) {
    int fileSizeInBytes = file.lengthSync();
    int maxSizeInBytes = maxMB * 1024 * 1024;
    return fileSizeInBytes <= maxSizeInBytes;
  }

  // Dosya boyutu formatı
  static String dosyaBoyutuFormati(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class AppConstants {
  static const List<String> kategoriler = [
    'Elektronik',
    'Ev Eşyası',
    'Giyim',
    'Kitap',
    'Spor',
    'Kozmetik',
    'Gıda',
    'Diğer'
  ];

  static const int minStokUyari = 5;
  static const int maxFotoMB = 5;
  static const String appName = 'Stok Takip Sistemi';

  // Hata mesajları
  static const String internetBaglantisiYok = 'İnternet bağlantısı yok';
  static const String dosyaCokBuyuk = 'Dosya boyutu 5MB\'dan küçük olmalıdır';
  static const String beklenmedikHata = 'Beklenmedik bir hata oluştu';

  // Validasyon mesajları
  static const String urunAdiGerekli = 'Ürün adı gerekli';
  static const String stokMiktariGerekli = 'Stok miktarı gerekli';
  static const String fiyatGerekli = 'Fiyat gerekli';
  static const String gecerliSayiGirin = 'Geçerli bir sayı girin';
  static const String gecerliFiyatGirin = 'Geçerli bir fiyat girin';

  // Firebase Collection Names
  static const String urunlerCollection = 'urunler';
  static const String kullanicilarCollection = 'kullanicilar';
}