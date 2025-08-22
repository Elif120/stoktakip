import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

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

class UrunEkleDuzenle extends StatefulWidget {
  final Urun? urun;
  final String? barkod;

  const UrunEkleDuzenle({
    Key? key,
    this.urun,
    this.barkod,
  }) : super(key: key);

  @override
  _UrunEkleDuzenleState createState() => _UrunEkleDuzenleState();
}

class _UrunEkleDuzenleState extends State<UrunEkleDuzenle> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late TextEditingController _adController;
  late TextEditingController _stokController;
  late TextEditingController _fiyatController;
  late TextEditingController _aciklamaController;
  late TextEditingController _barkodController;

  // State variables
  String _secilenKategori = AppConstants.kategoriler.first;
  File? _yeniFoto;
  String? _mevcutFotoUrl;
  bool _yukleniyor = false;
  bool _fotoYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _controllersBaslat();
    _verilerYukle();
  }

  void _controllersBaslat() {
    _adController = TextEditingController();
    _stokController = TextEditingController();
    _fiyatController = TextEditingController();
    _aciklamaController = TextEditingController();
    _barkodController = TextEditingController();
  }

  void _verilerYukle() {
    if (widget.urun != null) {
      // Düzenleme modu
      final urun = widget.urun!;
      _adController.text = urun.ad;
      _stokController.text = urun.stokMiktari.toString();
      _fiyatController.text = urun.fiyat.toString();
      _aciklamaController.text = urun.aciklama;
      _barkodController.text = urun.barkod;
      _secilenKategori = urun.kategori;
      _mevcutFotoUrl = urun.fotoUrl;
    } else {
      // Ekleme modu
      _barkodController.text = widget.barkod ?? AppHelpers.barkodUret();
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _stokController.dispose();
    _fiyatController.dispose();
    _aciklamaController.dispose();
    _barkodController.dispose();
    super.dispose();
  }

  bool get _duzenlemeModu => widget.urun != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu ? 'Ürün Düzenle' : 'Yeni Ürün Ekle'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _yukleniyor ? null : _kaydet,
          ),
        ],
      ),
      body: _yukleniyor
          ? _yuklemeEkrani()
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fotoSecimiWidget(),
              SizedBox(height: 24),
              _urunAdiWidget(),
              SizedBox(height: 16),
              _kategoriWidget(),
              SizedBox(height: 16),
              _stokVeFiyatWidget(),
              SizedBox(height: 16),
              _barkodWidget(),
              SizedBox(height: 16),
              _aciklamaWidget(),
              SizedBox(height: 24),
              _kaydetButonu(),
            ],
          ),
        ),
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
          Text(
            _duzenlemeModu ? 'Ürün güncelleniyor...' : 'Ürün ekleniyor...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _fotoSecimiWidget() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _fotoSec,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: _fotoWidget(),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _fotoYukleniyor ? null : () => _fotoSec(ImageSource.camera),
                icon: Icon(Icons.camera_alt, size: 20),
                label: Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _fotoYukleniyor ? null : () => _fotoSec(ImageSource.gallery),
                icon: Icon(Icons.photo_library, size: 20),
                label: Text('Galeri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_mevcutFotoUrl != null || _yeniFoto != null) ...[
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fotoSil,
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Fotoğrafı Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fotoWidget() {
    if (_fotoYukleniyor) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Yükleniyor...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_yeniFoto != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _yeniFoto!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (_mevcutFotoUrl != null && _mevcutFotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: _mevcutFotoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              Text('Fotoğraf yüklenemedi', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Fotoğraf Ekle',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          '(Maksimum 5MB)',
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _urunAdiWidget() {
    return TextFormField(
      controller: _adController,
      decoration: InputDecoration(
        labelText: 'Ürün Adı *',
        prefixIcon: Icon(Icons.shopping_bag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppConstants.urunAdiGerekli;
        }
        if (value.trim().length < 2) {
          return 'Ürün adı en az 2 karakter olmalıdır';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _kategoriWidget() {
    return DropdownButtonFormField<String>(
      value: _secilenKategori,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: AppConstants.kategoriler.map((kategori) {
        return DropdownMenuItem(
          value: kategori,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppHelpers.kategoriRengi(kategori),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Text(kategori),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _secilenKategori = value!;
        });
      },
    );
  }

  Widget _stokVeFiyatWidget() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _stokController,
            decoration: InputDecoration(
              labelText: 'Stok Miktarı *',
              prefixIcon: Icon(Icons.inventory),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppConstants.stokMiktariGerekli;
              }
              final stok = int.tryParse(value);
              if (stok == null || stok < 0) {
                return AppConstants.gecerliSayiGirin;
              }
              return null;
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _fiyatController,
            decoration: InputDecoration(
              labelText: 'Fiyat (₺) *',
              prefixIcon: TLIcon(size: 24, color: Colors.grey[600]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppConstants.fiyatGerekli;
              }
              final fiyat = double.tryParse(value);
              if (fiyat == null || fiyat <= 0) {
                return AppConstants.gecerliFiyatGirin;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _barkodWidget() {
    return TextFormField(
      controller: _barkodController,
      decoration: InputDecoration(
        labelText: 'Barkod',
        prefixIcon: Icon(Icons.qr_code),
        suffixIcon: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              _barkodController.text = AppHelpers.barkodUret();
            });
          },
          tooltip: 'Yeni barkod oluştur',
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      readOnly: true,
    );
  }

  Widget _aciklamaWidget() {
    return TextFormField(
      controller: _aciklamaController,
      decoration: InputDecoration(
        labelText: 'Açıklama',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Ürün hakkında detaylı bilgi...',
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _kaydetButonu() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _yukleniyor ? null : _kaydet,
        icon: _yukleniyor
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(Icons.save),
        label: Text(
          _yukleniyor
              ? 'Kaydediliyor...'
              : (_duzenlemeModu ? 'Güncelle' : 'Kaydet'),
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _fotoSec([ImageSource? source]) async {
    if (_fotoYukleniyor) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source ?? ImageSource.gallery,
        maxWidth: 800,        // Daha küçük boyut
        maxHeight: 800,       // Daha küçük boyut
        imageQuality: 60,     // Daha düşük kalite (daha küçük dosya)
      );

      if (image != null) {
        final File file = File(image.path);

        // Dosya boyutu kontrolü
        if (!AppHelpers.dosyaBoyutuGecerliMi(file, maxMB: AppConstants.maxFotoMB)) {
          AppHelpers.hataMesaji(context, AppConstants.dosyaCokBuyuk);
          return;
        }

        setState(() {
          _yeniFoto = file;
          _mevcutFotoUrl = null; // Yeni fotoğraf seçildi, eskisini kaldır
        });
      }
    } catch (e) {
      AppHelpers.hataMesaji(context, 'Fotoğraf seçilirken hata oluştu: $e');
    }
  }

  void _fotoSil() {
    setState(() {
      _yeniFoto = null;
      _mevcutFotoUrl = null;
    });
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    // İnternet kontrolü
    if (!await AppHelpers.internetVarMi()) {
      AppHelpers.hataMesaji(context, AppConstants.internetBaglantisiYok);
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      String? fotoUrl = _mevcutFotoUrl;

      // Yeni fotoğraf varsa yükle
      if (_yeniFoto != null) {
        setState(() => _fotoYukleniyor = true);

        // Eski fotoğrafı sil (düzenleme modunda)
        if (_duzenlemeModu && _mevcutFotoUrl != null) {
          await _firebaseService.fotoSil(_mevcutFotoUrl!);
        }

        // Yeni fotoğrafı yükle
        final tempId = _duzenlemeModu ? widget.urun!.id! : 'temp_${DateTime.now().millisecondsSinceEpoch}';
        fotoUrl = await _firebaseService.fotoYukle(_yeniFoto!, tempId);

        setState(() => _fotoYukleniyor = false);
      }

      // Ürün nesnesini oluştur
      final urun = Urun(
        id: _duzenlemeModu ? widget.urun!.id : null,
        ad: _adController.text.trim(),
        kategori: _secilenKategori,
        stokMiktari: int.parse(_stokController.text),
        fiyat: double.parse(_fiyatController.text),
        aciklama: _aciklamaController.text.trim(),
        fotoUrl: fotoUrl,
        barkod: _barkodController.text,
        olusturmaTarihi: _duzenlemeModu ? widget.urun!.olusturmaTarihi : DateTime.now(),
        guncellemeTarihi: DateTime.now(),
      );

      // Firebase'e kaydet
      if (_duzenlemeModu) {
        await _firebaseService.urunGuncelle(urun);
      } else {
        await _firebaseService.urunEkle(urun);
      }

      // Başarı mesajı ve geri dön
      Navigator.pop(context, true);

    } catch (e) {
      AppHelpers.hataMesaji(
        context,
        '${_duzenlemeModu ? 'Güncelleme' : 'Kaydetme'} sırasında hata oluştu: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _fotoYukleniyor = false;
        });
      }
    }
  }
}