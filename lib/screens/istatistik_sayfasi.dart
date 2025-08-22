import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/urun.dart';
import '../services/firebase_service.dart';
import '../utils/helpers.dart';

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

class IstatistikSayfasi extends StatefulWidget {
  final List<Urun> urunler;

  const IstatistikSayfasi({
    Key? key,
    required this.urunler,
  }) : super(key: key);

  @override
  _IstatistikSayfasiState createState() => _IstatistikSayfasiState();
}

class _IstatistikSayfasiState extends State<IstatistikSayfasi>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  late TabController _tabController;
  Map<String, dynamic>? _istatistikler;
  bool _yukleniyor = true;

  // Hesaplanmış veriler
  Map<String, int> _kategoriSayilari = {};
  Map<String, double> _kategoriDegerleri = {};
  List<Urun> _dusukStokUrunleri = [];
  List<Urun> _enPahaliUrunler = [];
  List<Urun> _enCokStokluUrunler = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _istatistikleriHesapla();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _istatistikleriHesapla() {
    setState(() => _yukleniyor = true);

    try {
      final urunler = widget.urunler;

      // Kategori sayıları ve değerleri
      _kategoriSayilari.clear();
      _kategoriDegerleri.clear();

      for (var urun in urunler) {
        _kategoriSayilari[urun.kategori] =
            (_kategoriSayilari[urun.kategori] ?? 0) + 1;

        double urunDegeri = urun.fiyat * urun.stokMiktari;
        _kategoriDegerleri[urun.kategori] =
            (_kategoriDegerleri[urun.kategori] ?? 0) + urunDegeri;
      }

      // Düşük stoklu ürünler
      _dusukStokUrunleri = urunler
          .where((u) => AppHelpers.dusukStokMu(u.stokMiktari))
          .toList()
        ..sort((a, b) => a.stokMiktari.compareTo(b.stokMiktari));

      // En pahalı ürünler (Top 10)
      _enPahaliUrunler = List.from(urunler)
        ..sort((a, b) => b.fiyat.compareTo(a.fiyat))
        ..take(10).toList();

      // En çok stoklu ürünler (Top 10)
      _enCokStokluUrunler = List.from(urunler)
        ..sort((a, b) => b.stokMiktari.compareTo(a.stokMiktari))
        ..take(10).toList();

      // Genel istatistikler
      double toplamDeger = urunler.fold(0,
              (sum, urun) => sum + (urun.fiyat * urun.stokMiktari));

      _istatistikler = {
        'toplam_urun': urunler.length,
        'toplam_deger': toplamDeger,
        'dusuk_stok_sayisi': _dusukStokUrunleri.length,
        'kategori_sayisi': _kategoriSayilari.length,
        'ortalama_fiyat': urunler.isNotEmpty
            ? urunler.fold(0.0, (sum, u) => sum + u.fiyat) / urunler.length
            : 0.0,
        'toplam_stok': urunler.fold(0, (sum, u) => sum + u.stokMiktari),
      };

    } catch (e) {
      AppHelpers.hataMesaji(context, 'İstatistikler hesaplanırken hata oluştu: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İstatistikler'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _istatistikleriHesapla,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _istatistikleriPaylas,
            tooltip: 'Paylaş',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: 'Genel'),
            Tab(icon: Icon(Icons.category), text: 'Kategoriler'),
            Tab(icon: Icon(Icons.warning), text: 'Düşük Stok'),
            Tab(icon: Icon(Icons.trending_up), text: 'En İyiler'),
          ],
        ),
      ),
      body: _yukleniyor
          ? _yuklemeEkrani()
          : TabBarView(
        controller: _tabController,
        children: [
          _genelIstatistiklerTab(),
          _kategoriIstatistikleriTab(),
          _dusukStokTab(),
          _enIyilerTab(),
        ],
      ),
    );
  }

  Widget _yuklemeEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('İstatistikler hesaplanıyor...'),
        ],
      ),
    );
  }

  Widget _genelIstatistiklerTab() {
    if (_istatistikler == null) return SizedBox();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Özet kartları grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _ozetKarti(
                'Toplam Ürün',
                _istatistikler!['toplam_urun'].toString(),
                Icons.inventory,
                Colors.blue,
              ),
              _ozetKartiTL(
                'Toplam Değer',
                AppHelpers.paraFormati(_istatistikler!['toplam_deger']),
                Colors.green,
              ),
              _ozetKarti(
                'Düşük Stok',
                _istatistikler!['dusuk_stok_sayisi'].toString(),
                Icons.warning,
                Colors.orange,
              ),
              _ozetKarti(
                'Kategori Sayısı',
                _istatistikler!['kategori_sayisi'].toString(),
                Icons.category,
                Colors.purple,
              ),
              _ozetKarti(
                'Ortalama Fiyat',
                AppHelpers.paraFormati(_istatistikler!['ortalama_fiyat']),
                Icons.trending_up,
                Colors.indigo,
              ),
              _ozetKarti(
                'Toplam Stok',
                _istatistikler!['toplam_stok'].toString(),
                Icons.warehouse,
                Colors.teal,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Detaylı bilgiler
          _detayKarti(
            'Stok Durumu',
            [
              _detaySatiri('Toplam Ürün Sayısı', _istatistikler!['toplam_urun'].toString()),
              _detaySatiri('Normal Stok', (widget.urunler.length - _dusukStokUrunleri.length).toString()),
              _detaySatiri('Düşük Stok (5\'ten az)', _dusukStokUrunleri.length.toString()),
              _detaySatiri('Stok Durumu',
                  _dusukStokUrunleri.isEmpty
                      ? '✅ İyi'
                      : '⚠️ Dikkat Gerekli'),
            ],
          ),

          SizedBox(height: 16),

          _detayKarti(
            'Finansal Özet',
            [
              _detaySatiri('Toplam Envanter Değeri', AppHelpers.paraFormati(_istatistikler!['toplam_deger'])),
              _detaySatiri('Ortalama Ürün Fiyatı', AppHelpers.paraFormati(_istatistikler!['ortalama_fiyat'])),
              _detaySatiri('En Pahalı Ürün',
                  _enPahaliUrunler.isNotEmpty
                      ? AppHelpers.paraFormati(_enPahaliUrunler.first.fiyat)
                      : '₺0.00'),
              _detaySatiri('En Ucuz Ürün',
                  widget.urunler.isNotEmpty
                      ? AppHelpers.paraFormati(widget.urunler.map((u) => u.fiyat).reduce((a, b) => a < b ? a : b))
                      : '₺0.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kategoriIstatistikleriTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Kategori sayıları
          _detayKarti(
            'Kategorilere Göre Ürün Sayıları',
            _kategoriSayilari.entries.map((entry) =>
                _kategoriSatiri(entry.key, entry.value.toString(), entry.value)
            ).toList(),
          ),

          SizedBox(height: 16),

          // Kategori değerleri
          _detayKarti(
            'Kategorilere Göre Stok Değerleri',
            _kategoriDegerleri.entries.map((entry) =>
                _kategoriSatiri(entry.key, AppHelpers.paraFormati(entry.value), null)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dusukStokTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Düşük stok özeti
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Düşük Stok Uyarısı',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _dusukStokUrunleri.isEmpty
                        ? '✅ Tüm ürünlerin stok seviyesi yeterli!'
                        : '⚠️ ${_dusukStokUrunleri.length} ürünün stoku 5\'ten az!',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dusukStokUrunleri.isEmpty ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_dusukStokUrunleri.isNotEmpty) ...[
            SizedBox(height: 16),
            _detayKarti(
              'Düşük Stoklu Ürünler (${_dusukStokUrunleri.length} adet)',
              _dusukStokUrunleri.map((urun) =>
                  _urunSatiri(urun, urun.stokMiktari.toString() + ' adet', Colors.red)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _enIyilerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // En pahalı ürünler
          _detayKarti(
            'En Pahalı Ürünler',
            _enPahaliUrunler.take(10).map((urun) =>
                _urunSatiri(urun, AppHelpers.paraFormati(urun.fiyat), Colors.green)
            ).toList(),
          ),

          SizedBox(height: 16),

          // En çok stoklu ürünler
          _detayKarti(
            'En Çok Stoklu Ürünler',
            _enCokStokluUrunler.take(10).map((urun) =>
                _urunSatiri(urun, '${urun.stokMiktari} adet', Colors.blue)
            ).toList(),
          ),

          SizedBox(height: 16),

          // En değerli ürünler (fiyat x stok) - HATASI DÜZELTİLDİ
          _detayKarti(
            'En Değerli Ürünler (Toplam Değer)',
            _enDegerliUrunleriGetir(),
          ),
        ],
      ),
    );
  }

  // HATA DÜZELTİLDİ: Ayrı fonksiyon oluşturuldu
  List<Widget> _enDegerliUrunleriGetir() {
    // En değerli ürünleri hesapla
    List<MapEntry<Urun, double>> degerliUrunler = widget.urunler
        .map((urun) => MapEntry(urun, urun.fiyat * urun.stokMiktari))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Widget listesine dönüştür
    return degerliUrunler
        .take(10)
        .map((entry) => _urunSatiri(
        entry.key,
        AppHelpers.paraFormati(entry.value),
        Colors.purple
    ))
        .toList();
  }

  Widget _ozetKarti(String baslik, String deger, IconData icon, Color renk) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: renk, size: 32),
            SizedBox(height: 8),
            FittedBox(
              child: Text(
                deger,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
            ),
            SizedBox(height: 4),
            FittedBox(
              child: Text(
                baslik,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
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
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TLIcon(size: 32, color: renk),
            SizedBox(height: 8),
            FittedBox(
              child: Text(
                deger,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
            ),
            SizedBox(height: 4),
            FittedBox(
              child: Text(
                baslik,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detayKarti(String baslik, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detaySatiri(String baslik, String deger) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              baslik,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriSatiri(String kategori, String deger, int? sayi) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppHelpers.kategoriRengi(kategori),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              kategori,
              style: TextStyle(fontSize: 16),
            ),
          ),
          if (sayi != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppHelpers.kategoriRengi(kategori).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppHelpers.kategoriRengi(kategori).withOpacity(0.3),
                ),
              ),
              child: Text(
                deger,
                style: TextStyle(
                  color: AppHelpers.kategoriRengi(kategori),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Text(
              deger,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _urunSatiri(Urun urun, String deger, Color renk) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.metinKisalt(urun.ad, 30),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  urun.kategori,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: renk.withOpacity(0.3)),
            ),
            child: Text(
              deger,
              style: TextStyle(
                color: renk,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _istatistikleriPaylas() {
    if (_istatistikler == null) return;

    final metin = '''
📊 Stok Takip İstatistikleri

📦 Genel Durum:
• Toplam Ürün: ${_istatistikler!['toplam_urun']}
• Toplam Değer: ${AppHelpers.paraFormati(_istatistikler!['toplam_deger'])}
• Düşük Stok: ${_istatistikler!['dusuk_stok_sayisi']} ürün
• Kategori Sayısı: ${_istatistikler!['kategori_sayisi']}

📈 Kategori Dağılımı:
${_kategoriSayilari.entries.map((e) => '• ${e.key}: ${e.value} ürün').join('\n')}

⚠️ Dikkat Gereken Ürünler:
${_dusukStokUrunleri.isEmpty ? '• Tüm ürünlerin stoku yeterli ✅' : _dusukStokUrunleri.take(5).map((u) => '• ${u.ad}: ${u.stokMiktari} adet').join('\n')}

📱 Stok Takip Uygulaması ile oluşturuldu
''';

    Clipboard.setData(ClipboardData(text: metin)).then((_) {
      AppHelpers.basariMesaji(context, 'İstatistikler panoya kopyalandı');
    });
  }
}