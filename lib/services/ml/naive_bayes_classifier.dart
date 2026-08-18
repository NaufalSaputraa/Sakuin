import 'dart:math';

class NaiveBayesClassifier {
  final Map<String, Map<String, int>> _wordCounts = {};
  final Map<String, int> _categoryCounts = {};
  int _totalDocuments = 0;
  final Set<String> _vocabulary = {};

  NaiveBayesClassifier() {
    _trainDefaultDataset();
  }

  void train(String text, String category) {
    final tokens = _tokenize(text);
    _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    _totalDocuments++;

    _wordCounts.putIfAbsent(category, () => {});
    for (final token in tokens) {
      _vocabulary.add(token);
      _wordCounts[category]![token] = (_wordCounts[category]![token] ?? 0) + 1;
    }
  }

  String? classify(String text) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty || _totalDocuments == 0) return null;

    String? bestCategory;
    double bestScore = -double.infinity;

    for (final category in _categoryCounts.keys) {
      // Log prior probability P(C)
      double score = log(_categoryCounts[category]! / _totalDocuments);

      final totalWordsInCategory = _wordCounts[category]!.values.fold(0, (a, b) => a + b);
      final vocabSize = _vocabulary.length;

      // Log likelihood sum P(W|C) with Laplace smoothing (+1)
      for (final token in tokens) {
        final count = _wordCounts[category]![token] ?? 0;
        score += log((count + 1) / (totalWordsInCategory + vocabSize));
      }

      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    }

    return bestCategory;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();
  }

  void _trainDefaultDataset() {
    final dataset = <String, List<String>>{
      'food': [
        'nasi padang rendang ayam bakar lele',
        'kopi kenangan janji jiwa starling cafe americano latte',
        'martabak manis terang bulan telur bebek bangka',
        'bakso urat mie ayam pangsit cwie mie',
        'makan siang warteg tahu tempe sayur asem',
        'sate ayam kambing madura bumbu kacang',
        'jajan cilok cireng batagor siomay seblak pedas',
        'makan malam mcdonalds burger king kfc richeese',
        'indomaret point alfamart roti tawar sari roti',
        'haus boba chatime mixue es krim teh solo',
        'angkringan nasi kucing jahe susu gorengan',
      ],
      'transport': [
        'ojol gojek motor gopay goride',
        'grab bike car gocars maxim indriver',
        'isi saldo kartu krl commuter line mrt lrt jaklingko',
        'transjakarta busway feeder busway tiket',
        'parkir mobil motor mall stasiun pasar',
        'tarif tol jorr jagorawi cipularang etoll',
        'bensin pertalite pertamax shell vpower spbu pertamina',
      ],
      'pulsa': [
        'isi pulsa telkomsel simpati as kuota byu',
        'paket data indosat im3 freedom internetan',
        'pulsa xl prioritas axis kuota hemat',
        'smartfren unlimited kuota malam tri three data',
      ],
      'bills': [
        'token pln listrik pascabayar tagihan rumah',
        'bayar pdam air tirta langganan meteran',
        'wifi indihome firstmedia biznet myrepublic internet rumah',
        'iuran kebersihan rt rw sampah keamanan warga',
        'bpjs kesehatan jamsostek premi asuransi',
      ],
      'housing': [
        'bayar sewa kos kost bulanan kamar ac wifi',
        'kontrakan rumah tahunan petakan',
        'ipl maintenance service charge apartemen listrik air',
      ],
      'shopping': [
        'beli baju kaos celana jeans polo uniqlo hnm',
        'tokopedia shopee lazada checkout keranjang gratis ongkir',
        'sepatu sneakers running sandal swallow compass ventela',
        'skincare sunscreen moisturizer facial wash cetaphil somethinc',
        'perabot rumah tangga ace hardware miniso krisbow',
      ],
      'entertainment': [
        'nonton bioskop xxi cgv cinepolis premiere popcorn',
        'topup diamond mobile legends free fire genshin steam wallet',
        'langganan netflix premium spotify family youtube premium vidio',
        'game console ps5 nintendo switch games',
      ],
      'health': [
        'beli obat panadol paracetamol tolak angin bodrex apotek k24 kimia farma',
        'periksa dokter gigi spesialis klinik klinik pratama',
        'vitamin booster c d3 zinc enervon hemaviton',
        'biaya lab darah rontgen cek kolesterol gula darah',
      ],
      'salary': [
        'gaji pokok payroll transfer kantor bulanan',
        'bonus tahunan insentif kinerja reward perusahaan',
        'thr tunjangan hari raya idul fitri lebaran',
      ],
      'freelance': [
        'pembayaran invoice project klien desain logo',
        'fee pembuatan website aplikasi honor narasumber pembicara',
        'komisi affiliate affiliator penjualan tiktok shopee',
      ],
    };

    for (final entry in dataset.entries) {
      for (final doc in entry.value) {
        train(doc, entry.key);
      }
    }
  }
}
