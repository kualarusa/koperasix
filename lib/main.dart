import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

// ============================================================
// FUNGSI FORMAT ANGKA INDONESIA
// ============================================================

String formatAngkaIndonesia(dynamic value) {
  if (value == null) {
    return '0';
  }

  double number;

  try {
    if (value is num) {
      number = value.toDouble();
    } else {
      String raw = value.toString().trim();

      if (raw.isEmpty) {
        return '0';
      }

      // Jika format dari database misalnya:
      // 141032.00
      // maka langsung diproses.
      //
      // Jika suatu saat API mengirim:
      // 141.032,00
      // maka titik dianggap pemisah ribuan
      // dan koma sebagai desimal.
      if (raw.contains(',') && raw.contains('.')) {
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else if (raw.contains(',')) {
        raw = raw.replaceAll(',', '.');
      }

      number = double.parse(raw);
    }
  } catch (_) {
    return value.toString();
  }

  // Untuk angka bulat
  if (number == number.roundToDouble()) {
    String result = number.toInt().toString();

    bool isNegative = result.startsWith('-');

    if (isNegative) {
      result = result.substring(1);
    }

    // Tambahkan titik setiap tiga digit
    result = result.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return isNegative ? '-$result' : result;
  }

  // Untuk angka yang memiliki desimal
  String result = number.toStringAsFixed(2);

  List<String> parts = result.split('.');

  String integerPart = parts[0];
  String decimalPart = parts[1];

  bool isNegative = integerPart.startsWith('-');

  if (isNegative) {
    integerPart = integerPart.substring(1);
  }

  integerPart = integerPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return '${isNegative ? '-' : ''}$integerPart,$decimalPart';
}

// ============================================================
// FORMAT RUPIAH
// ============================================================

String formatRupiah(dynamic value) {
  return 'Rp${formatAngkaIndonesia(value)},00';
}

// ============================================================
// FORMAT RUPIAH DENGAN DESIMAL YANG BENAR
// ============================================================

String formatRupiahIndonesia(dynamic value) {
  if (value == null) {
    return 'Rp0,00';
  }

  double number;

  try {
    if (value is num) {
      number = value.toDouble();
    } else {
      String raw = value.toString().trim();

      if (raw.isEmpty) {
        return 'Rp0,00';
      }

      if (raw.contains(',') && raw.contains('.')) {
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else if (raw.contains(',')) {
        raw = raw.replaceAll(',', '.');
      }

      number = double.parse(raw);
    }
  } catch (_) {
    return 'Rp${value.toString()}';
  }

  bool isNegative = number < 0;

  if (isNegative) {
    number = number.abs();
  }

  String fixed = number.toStringAsFixed(2);

  List<String> parts = fixed.split('.');

  String integerPart = parts[0];
  String decimalPart = parts[1];

  integerPart = integerPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return '${isNegative ? '-Rp' : 'Rp'}$integerPart,$decimalPart';
}

// ============================================================
// 1. APLIKASI UTAMA
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KPU Mart Lampung',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// 2. SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splash.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. HALAMAN LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  // Google Sign In
  // JANGAN DIUBAH karena konfigurasi saat ini sudah berhasil.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Endpoint API backend untuk login Google
  final String baseUrl =
      'http://202.179.185.94/koperasi/api/google_login';

  void showSnackBar(
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      // Memunculkan pilihan akun Google
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      String email = googleUser.email;

      // Mengirim email ke API backend
      final response = await http
          .post(
            Uri.parse(baseUrl),
            body: {
              'email': email,
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          final String noAnggota =
              jsonResponse['data']['no_anggota'] ?? '';

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDashboard(
                noAnggota: noAnggota,
              ),
            ),
          );
        } else {
          await _googleSignIn.signOut();

          showSnackBar(
            jsonResponse['message'] ??
                'Email tidak terdaftar sebagai anggota.',
          );
        }
      } else {
        showSnackBar(
          'Terjadi gangguan pada server '
          '(Error ${response.statusCode})',
        );
      }
    } on SocketException {
      showSnackBar(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
      );
    } on TimeoutException {
      showSnackBar(
        'Koneksi internet lambat / server lama merespon.',
      );
    } catch (e) {
      showSnackBar(
        'Terjadi kesalahan tak terduga: $e',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 70,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'KPU Mart Lampung',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Silakan masuk menggunakan akun Google '
                    'yang terdaftar di perangkat Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      onPressed:
                          isLoading ? null : handleGoogleLogin,
                      icon: isLoading
                          ? const SizedBox.shrink()
                          : Image.network(
                              'https://www.gstatic.com/images/branding/'
                              'product/1x/googleg_48dp.png',
                              height: 24,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                              ),
                            ),
                      label: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Masuk dengan Google',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 4. DASHBOARD ANGGOTA
// ============================================================

class MemberDashboard extends StatefulWidget {
  final String noAnggota;

  const MemberDashboard({
    super.key,
    required this.noAnggota,
  });

  @override
  State<MemberDashboard> createState() =>
      _MemberDashboardState();
}

class _MemberDashboardState
    extends State<MemberDashboard> {
  Map<String, dynamic>? memberData;

  bool isLoading = true;

  String errorMessage = '';

  final String baseUrl =
      'http://202.179.185.94/koperasi/api/get_member';

  // ==========================================================
  // AMBIL DATA ANGGOTA
  // ==========================================================

  Future<void> fetchMemberData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl?no_anggota=${widget.noAnggota}',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          setState(() {
            memberData = jsonResponse['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                jsonResponse['message'] ??
                    'Data tidak ditemukan';

            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Gagal terhubung ke server';

          isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessage =
            'Tidak ada koneksi internet.';

        isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        errorMessage =
            'Koneksi terlalu lama / timeout.';

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            'Terjadi kesalahan sistem.';

        isLoading = false;
      });
    }
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    fetchMemberData();
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  // ==========================================================
  // DASHBOARD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final List riwayatBelanja =
        memberData?['riwayat_belanja'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Anggota',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Refresh Data',
            onPressed: fetchMemberData,
          ),

          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Keluar',
            onPressed: logout,
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchMemberData,

                  child: CustomScrollView(
                    slivers: [
                      // ==================================================
                      // BAGIAN ATAS DASHBOARD
                      // ==================================================

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            8.0,
                            8.0,
                            8.0,
                            16.0,
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              // ==================================================
                              // BARCODE ANGGOTA
                              // ==================================================

                              Card(
                                elevation: 4,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),

                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    12.0,
                                    18.0,
                                    12.0,
                                    20.0,
                                  ),

                                  child: Column(
                                    children: [
                                      const Text(
                                        'BARCODE ANGGOTA',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.grey,
                                          letterSpacing: 0.5,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 14,
                                      ),

                                      // ==================================================
                                      // BARCODE BESAR
                                      // ==================================================

                                      SizedBox(
                                        width:
                                            double.infinity,
                                        height: 78,

                                        child: Image.network(
                                          'https://bwipjs-api.metafloor.com/'
                                          '?bcid=code128'
                                          '&text=${memberData!['no_anggota']}'
                                          '&scale=3'
                                          '&height=18',

                                          fit: BoxFit.fill,

                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Center(
                                              child: Text(
                                                'Gagal memuat barcode',
                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.red,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 14,
                                      ),

                                      // ==================================================
                                      // NOMOR ANGGOTA
                                      // ==================================================

                                      Text(
                                        memberData![
                                            'no_anggota'],
                                        style:
                                            const TextStyle(
                                          fontSize: 22,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      // ==================================================
                                      // NAMA ANGGOTA
                                      // ==================================================

                                      Text(
                                        memberData!['nama'],
                                        textAlign:
                                            TextAlign.center,
                                        style:
                                            const TextStyle(
                                          fontSize: 17,
                                          color:
                                              Colors.indigo,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ==================================================
                              // TOTAL SALDO POIN
                              // ==================================================

                              Card(
                                elevation: 3,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),

                                color:
                                    Colors.amber.shade50,

                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    20.0,
                                  ),

                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,

                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [
                                          const Text(
                                            'Total Saldo Poin',
                                            style:
                                                TextStyle(
                                              fontSize: 13,
                                              color: Colors
                                                  .black54,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 5,
                                          ),

                                          Text(
                                            '${formatAngkaIndonesia(memberData!['saldo_poin'])} Poin',
                                            style:
                                                const TextStyle(
                                              fontSize: 26,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: Colors
                                                  .orangeAccent,
                                            ),
                                          ),
                                        ],
                                      ),

                                      CircleAvatar(
                                        backgroundColor:
                                            Colors.orange,

                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            color:
                                                Colors.white,
                                          ),
                                          onPressed:
                                              fetchMemberData,
                                          tooltip:
                                              'Refresh Poin',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ==================================================
                              // INFORMASI IURAN
                              // ==================================================

                              const Text(
                                'Informasi Iuran Anggota',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Row(
                                children: [
                                  // ==================================================
                                  // IURAN POKOK
                                  // ==================================================

                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          16.0,
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            const Text(
                                              'Iuran Pokok',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),

                                            const SizedBox(
                                              height: 8,
                                            ),

                                            Text(
                                              formatRupiahIndonesia(
                                                memberData![
                                                    'total_iuran_pokok'],
                                              ),

                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  // ==================================================
                                  // IURAN WAJIB
                                  // ==================================================

                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          16.0,
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            const Text(
                                              'Iuran Wajib',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),

                                            const SizedBox(
                                              height: 8,
                                            ),

                                            Text(
                                              formatRupiahIndonesia(
                                                memberData![
                                                    'total_iuran_wajib'],
                                              ),

                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              // ==================================================
                              // RIWAYAT PEMBELIAN
                              // ==================================================

                              const Text(
                                'Riwayat Pembelian',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ==================================================
                      // JIKA TIDAK ADA RIWAYAT
                      // ==================================================

                      riwayatBelanja.isEmpty
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),

                                child: Card(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(
                                      20.0,
                                    ),

                                    child: Center(
                                      child: Text(
                                        'Belum ada riwayat transaksi belanja.',
                                        style: TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )

                          // ==================================================
                          // DAFTAR RIWAYAT PEMBELIAN
                          // ==================================================

                          : SliverList(
                              delegate:
                                  SliverChildBuilderDelegate(
                                (
                                  context,
                                  index,
                                ) {
                                  final belanja =
                                      riwayatBelanja[
                                          index];

                                  return Padding(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 16.0,
                                      vertical: 4.0,
                                    ),

                                    child: Card(
                                      child: ListTile(
                                        // ==================================================
                                        // ICON
                                        // ==================================================

                                        leading:
                                            const CircleAvatar(
                                          backgroundColor:
                                              Colors.indigo,

                                          child: Icon(
                                            Icons
                                                .shopping_bag,
                                            color:
                                                Colors.white,
                                            size: 18,
                                          ),
                                        ),

                                        // ==================================================
                                        // NOMINAL BELANJA
                                        // ==================================================

                                        title: Text(
                                          formatRupiahIndonesia(
                                            belanja[
                                                'nominal'],
                                          ),

                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        // ==================================================
                                        // TANGGAL
                                        // ==================================================

                                        subtitle: Text(
                                          belanja[
                                              'created_at'],
                                          style:
                                              const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),

                                        // ==================================================
                                        // POIN
                                        // ==================================================

                                        trailing:
                                            Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),

                                          decoration:
                                              BoxDecoration(
                                            color: Colors
                                                .green
                                                .shade50,

                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              8,
                                            ),
                                          ),

                                          child: Text(
                                            '+${formatAngkaIndonesia(belanja['poin'])} Poin',

                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.green,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },

                                childCount:
                                    riwayatBelanja.length,
                              ),
                            ),

                      // ==================================================
                      // SPASI BAWAH
                      // ==================================================

                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}