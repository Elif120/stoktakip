import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/urun.dart';
import '../services/firebase_service.dart';
import '../utils/helpers.dart';
import 'urun_ekle_duzenle.dart';
import 'istatistik_sayfasi.dart';

class TLIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const TLIcon({Key? key, this.size, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 24,
      height: size ?? 24,
      alignment: Alignment.center,
      child: Text(
        '₺',
        style: TextStyle(
          fontSize: (size ?? 24) * 0.8,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black,
        ),
      ),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Urun> _urunler = [];
  List<Urun> _filtrelenmisUrunler = [];
  TextEditingController _aramaController = TextEditingController();
  bool _yukleniyor = true;
  bool _internetVarMi = true;

  @override
  void initState() {
    super.initState();
    _internetKontrolEt();
    _urunleriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _internetKontrolEt() async {
    bool internetDurumu = await AppHelpers.internetVarMi();
    setState(() {
      _internetVarMi = internetDurumu;
    });

    if (!internetDurumu) {
      AppHelpers.hataMesaji(context, AppConstants.internetBaglantisiYok);
    }
  }

  Future<void> _urunleriYukle() async {
    if (!_internetVarMi) return;

    setState(() => _yukleniyor = true);

    try {
      final urunListesi = await _firebaseService.tumUrunleriGetir();
      setState(() {
        _urunler = urunListesi;
        _filtrelenmisUrunler = urunListesi;
      });
    } catch (e) {
      AppHelpers.hataMesaji(context, 'Ürünler yüklenirken hata oluştu: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  void _urunAra(String anahtar) {
    setState(() {
      if (anahtar.isEmpty) {
        _filtrelenmisUrunler = _urunler;
      } else {
        _filtrelenmisUrunler = _urunler.where((urun) =>
        urun.ad.toLowerCase().contains(anahtar.toLowerCase()) ||
            urun.kategori.toLowerCase().contains(anahtar.toLowerCase()) ||
            urun.barkod.contains(anahtar)).toList();
      }
    });
  }

  Future<void> _yenile() async {
    await _internetKontrolEt();
    if (_internetVarMi) {
      await _urunleriYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _internetVarMi ? () => _istatistikSayfasinaGit() : null,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _yenile,
          ),
          // İnternet durumu göstergesi
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Icon(
              _internetVarMi ? Icons.cloud_done : Icons.cloud_off,
              color: _internetVarMi ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _yenile,
        child: Column(
          children: [
            if (!_internetVarMi) _internetUyarisi(),
            _aramaWidget(),
            _ozetKartlari(),
            Expanded(child: _urunListesi()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _internetVarMi ? _yeniUrunEkle : null,
        child: Icon(Icons.add),
        tooltip: 'Yeni Ürün Ekle',
        backgroundColor: _internetVarMi ? null : Colors.grey,
      ),
    );
  }

  Widget _internetUyarisi() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.red[100],
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'İnternet bağlantısı yok. Veriler güncel olmayabilir.',
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aramaWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _aramaController,
        decoration: InputDecoration(
          hintText: 'Ürün adı, kategori veya barkod ara...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _aramaController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _aramaController.clear();
              _urunAra('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: _urunAra,
      ),
    );
  }

  Widget _ozetKartlari() {
    final toplamDeger = _urunler.fold(0.0,
            (sum, urun) => sum + (urun.fiyat * urun.stokMiktari));
    final dusukStokSayisi = _urunler.where(
            (u) => AppHelpers.dusukStokMu(u.stokMiktari)).length;

    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ozetKarti(
              'Toplam Ürün',
              _urunler.length.toString(),
              Icons.inventory,
              Colors.blue,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _ozetKarti(
              'Düşük Stok',
              dusukStokSayisi.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _ozetKartiTL(
              'Toplam Değer',
              AppHelpers.paraFormati(toplamDeger),
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKarti(String baslik, String deger, IconData icon, Color renk) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: renk, size: 24),
            SizedBox(height: 4),
            FittedBox(
              child: Text(
                deger,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                baslik,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ozetKartiTL(String baslik, String deger, Color renk) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TLIcon(size: 24, color: renk),
            SizedBox(height: 4),
            FittedBox(
              child: Text(
                deger,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                baslik,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urunListesi() {
    if (_yukleniyor) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ürünler yükleniyor...'),
          ],
        ),
      );
    }

    if (_filtrelenmisUrunler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _urunler.isEmpty
                  ? 'Henüz ürün eklenmemiş'
                  : 'Arama kriterine uygun ürün bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_urunler.isEmpty && _internetVarMi) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _yeniUrunEkle,
                icon: Icon(Icons.add),
                label: Text('İlk Ürünü Ekle'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filtrelenmisUrunler.length,
      itemBuilder: (context, index) {
        final urun = _filtrelenmisUrunler[index];
        return _urunKarti(urun);
      },
    );
  }

  Widget _urunKarti(Urun urun) {
    final dusukStok = AppHelpers.dusukStokMu(urun.stokMiktari);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: _urunFotosu(urun),
        title: Text(
          urun.ad,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppHelpers.kategoriRengi(urun.kategori).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                urun.kategori,
                style: TextStyle(
                  color: AppHelpers.kategoriRengi(urun.kategori),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Stok: ${urun.stokMiktari}',
              style: TextStyle(
                color: dusukStok ? Colors.red : Colors.black,
                fontWeight: dusukStok ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text('Fiyat: ${AppHelpers.paraFormati(urun.fiyat)}'),
            Text(
              'Güncelleme: ${AppHelpers.tarihFormati(urun.guncellemeTarihi)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dusukStok)
              Icon(Icons.warning, color: Colors.orange, size: 20),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'duzenle',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'barkod',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Barkod Göster'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _menuSecenekleri(value, urun),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urunFotosu(Urun urun) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: urun.fotoUrl != null && urun.fotoUrl!.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: urun.fotoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
              Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      )
          : Icon(Icons.image, color: Colors.grey),
    );
  }

  void _menuSecenekleri(String secim, Urun urun) {
    if (!_internetVarMi && (secim == 'duzenle' || secim == 'sil')) {
      AppHelpers.hataMesaji(context, AppConstants.internetBaglantisiYok);
      return;
    }

    switch (secim) {
      case 'duzenle':
        _urunDuzenle(urun);
        break;
      case 'barkod':
        _barkodGoster(urun);
        break;
      case 'sil':
        _urunSil(urun);
        break;
    }
  }

  Future<void> _yeniUrunEkle() async {
    if (!_internetVarMi) {
      AppHelpers.hataMesaji(context, AppConstants.internetBaglantisiYok);
      return;
    }

    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunEkleDuzenle(barkod: AppHelpers.barkodUret()),
      ),
    );

    if (sonuc == true) {
      AppHelpers.yukleniyorMesaji(context, 'Ürünler güncelleniyor...');
      await _urunleriYukle();
      AppHelpers.basariMesaji(context, 'Ürün başarıyla eklendi');
    }
  }

  Future<void> _urunDuzenle(Urun urun) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunEkleDuzenle(urun: urun),
      ),
    );

    if (sonuc == true) {
      AppHelpers.yukleniyorMesaji(context, 'Ürünler güncelleniyor...');
      await _urunleriYukle();
      AppHelpers.basariMesaji(context, 'Ürün başarıyla güncellendi');
    }
  }

  void _barkodGoster(Urun urun) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Barkod - ${AppHelpers.metinKisalt(urun.ad, 20)}'),
        content: Container(
          width: 250,
          height: 120,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: urun.barkod,
            drawText: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _urunSil(Urun urun) async {
    final onay = await AppHelpers.onayDialoguGoster(
      context,
      'Ürün Sil',
      '${urun.ad} ürününü silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
    );

    if (onay) {
      AppHelpers.loadingDialogGoster(context, 'Ürün siliniyor...');

      try {
        await _firebaseService.urunSil(urun.id!);
        AppHelpers.loadingDialogKapat(context);
        await _urunleriYukle();
        AppHelpers.basariMesaji(context, 'Ürün başarıyla silindi');
      } catch (e) {
        AppHelpers.loadingDialogKapat(context);
        AppHelpers.hataMesaji(context, 'Ürün silinirken hata oluştu: $e');
      }
    }
  }

  void _istatistikSayfasinaGit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IstatistikSayfasi(urunler: _urunler),
      ),
    );
  }
}