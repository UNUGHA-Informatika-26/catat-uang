# CatatUang

CatatUang adalah aplikasi pencatatan keuangan pribadi yang dibuat dengan
Flutter. Aplikasi membantu pengguna mencatat pemasukan dan pengeluaran,
memantau saldo, mengatur anggaran, serta melihat ringkasan dan laporan
keuangan. Pengguna masuk dengan akun Supabase; data transaksi dan anggaran
disimpan di perangkat menggunakan Hive dan disinkronkan dengan Supabase.

## Fitur

- Membuat akun, Log In, Log Out, dan memulihkan kata sandi melalui Supabase
  Auth.
- Mencatat, mengubah, dan menghapus transaksi pemasukan maupun pengeluaran.
- Mengelompokkan transaksi berdasarkan kategori dan tanggal.
- Menampilkan saldo serta ringkasan keuangan di beranda.
- Membuat dan mengelola batas anggaran.
- Melihat laporan transaksi dalam periode tertentu.
- Menyimpan perubahan secara lokal terlebih dahulu. Perubahan yang belum
  tersinkron masuk ke antrean lokal dan dicoba lagi saat koneksi tersedia,
  aplikasi dibuka kembali, atau aplikasi kembali aktif.

## Teknologi dan komponen

| Komponen | Kegunaan |
| --- | --- |
| Flutter dan Dart | UI, navigasi, dan logika aplikasi lintas platform. |
| `flutter_bloc` dan `equatable` | Mengelola alur status autentikasi dan event-nya. |
| Supabase Auth | Pendaftaran, sesi, login, reset kata sandi, dan identitas pengguna. |
| Supabase Database | Menyimpan profil, transaksi, dan anggaran. |
| Hive CE | Penyimpanan lokal untuk cache, antrean sinkronisasi, dan data per pengguna. |
| `connectivity_plus` | Memberi tahu aplikasi saat status koneksi berubah agar sinkronisasi dapat dicoba lagi. |
| `shared_preferences` | Dependensi untuk preferensi sederhana; penyimpanan transaksi utama menggunakan Hive. |

### Gambaran arsitektur

1. `main.dart` menyiapkan Hive dan Supabase, lalu menampilkan aplikasi.
2. `AuthBloc` memulihkan sesi pengguna dan mengatur perubahan status autentikasi.
3. Setelah login, `HomeShell` membuat `AppData` untuk memuat data akun dari Hive
   dan menyelaraskannya dengan Supabase.
4. Perubahan transaksi atau anggaran ditulis ke Hive beserta antrean operasi
   sebelum dikirim ke Supabase. Jika sinkronisasi gagal, data lokal tetap
   tersedia dan aplikasi melaporkan bahwa sinkronisasi akan dicoba lagi.
5. Kebijakan Row Level Security (RLS) di Supabase membatasi data ke pemilik akun.

## Struktur dan fungsi file

### Titik masuk dan konfigurasi Flutter

| File | Fungsi |
| --- | --- |
| `lib/main.dart` | Titik masuk aplikasi; inisialisasi Hive/Supabase, konfigurasi tema dan navigasi, serta penyedia `AuthBloc`. |
| `lib/core/supabase_config.dart` | Project URL dan publishable/anon key Supabase; mendukung penggantian nilai menggunakan `--dart-define`. |
| `lib/core/tema.dart` | Palet warna, tema Material, gradien, bayangan, transisi, dan perilaku scroll bersama. |
| `lib/core/format.dart` | Format Rupiah/tanggal, label hari, snackbar, dan dialog konfirmasi yang dipakai lintas halaman. |
| `lib/core/widgets.dart` | Widget UI umum, seperti kartu, tombol, field, indikator progres, dan baris transaksi. |
| `pubspec.yaml` | Nama package, versi, batas SDK, dependencies, dan daftar aset Flutter. |
| `pubspec.lock` | Versi dependency yang terkunci agar resolusi package konsisten. |
| `analysis_options.yaml` | Aturan analisis dan lint Dart. |
| `flutter_launcher_icons.yaml` | Sumber logo dan konfigurasi generator ikon Android, iOS, serta web. |

### Autentikasi — `lib/features/auth/`

| File | Fungsi |
| --- | --- |
| `bloc/auth_bloc.dart` | Menangani event autentikasi, memanggil repository, dan menerbitkan status autentikasi. |
| `bloc/auth_event.dart` | Definisi event seperti pemulihan sesi, login, daftar, reset kata sandi, dan logout. |
| `bloc/auth_state.dart` | Definisi status seperti memuat, login, belum login, gagal, dan konfirmasi email. |
| `data/auth_repository.dart` | Kontrak repository autentikasi dan implementasinya dengan Supabase Auth. |
| `models/akun.dart` | Model akun pengguna: ID, nama, dan email. |
| `presentation/pages/splash/splash_screen.dart` | Layar awal; memicu pemulihan sesi lalu mengarahkan pengguna ke beranda atau onboarding. |
| `presentation/pages/onboarding/onboarding_screen.dart` | Halaman pengenalan dan titik masuk ke pendaftaran/login. |
| `presentation/pages/login/login_screen.dart` | Form dan UI login. |
| `presentation/pages/register/register_screen.dart` | Form dan UI pembuatan akun. |
| `presentation/pages/forgot_password/forgot_password_screen.dart` | Form permintaan email pemulihan kata sandi. |
| `presentation/pages/reset_password/reset_password_screen.dart` | Form untuk menetapkan kata sandi baru setelah membuka tautan pemulihan. |
| `presentation/widgets/auth_scaffold.dart` | Kerangka UI yang digunakan bersama oleh layar autentikasi. |

### Beranda — `lib/features/home/`

| File | Fungsi |
| --- | --- |
| `presentation/pages/home_shell/home_shell.dart` | Kerangka setelah login; menyediakan navigasi tab dan aksi tambah transaksi, serta panel profil/logout. |
| `presentation/pages/beranda/beranda_tab.dart` | Ringkasan saldo dan informasi keuangan untuk tab Beranda. |

### Keuangan — `lib/features/keuangan/`

| File | Fungsi |
| --- | --- |
| `data/app_data.dart` | Sumber data aplikasi; memuat/menyimpan cache Hive, mengelola transaksi dan anggaran, serta antrean sinkronisasi Supabase. |
| `models/transaksi.dart` | Model transaksi dan fungsi perhitungan total pemasukan/pengeluaran. |
| `models/anggaran.dart` | Model anggaran dan kunci kategori untuk anggaran keseluruhan. |
| `models/kategori.dart` | Daftar kategori pemasukan/pengeluaran beserta ikon dan warnanya. |
| `presentation/pages/transaksi/transaksi_tab.dart` | Daftar dan tampilan tab transaksi. |
| `presentation/pages/transaksi/transaksi_form.dart` | Form tambah dan ubah transaksi. |
| `presentation/pages/anggaran/anggaran_tab.dart` | Tampilan dan pengelolaan anggaran. |
| `presentation/pages/laporan/laporan_tab.dart` | Ringkasan/grafik laporan keuangan. |
| `presentation/widgets/dialogs.dart` | Dialog input nominal dan anggaran. |

### Aset, backend, pengujian, dan platform

| File/folder | Fungsi |
| --- | --- |
| `assets/logo/logo.png` | Logo utama yang digunakan sebagai sumber ikon aplikasi. |
| `assets/logo/logo_foreground.png` | Lapisan depan ikon adaptif Android. |
| `assets/logo/logo_bulat.png` | Logo berbentuk bulat yang ditampilkan pada layar splash di dalam aplikasi. |
| `supabase/migrations/20261031000000_initial_schema.sql` | Membuat tabel profil, transaksi, anggaran, trigger profil, indeks, grants, dan kebijakan RLS. |
| `test/widget_test.dart` | Widget test untuk layar splash dan onboarding. |
| `android/app/src/main/AndroidManifest.xml` | Nama/ikon aplikasi Android, deep link autentikasi, izin jaringan, dan pengaturan keamanan/backup. |
| `android/app/src/main/res/xml/backup_rules.xml` | Aturan backup Android versi lama; mengecualikan data aplikasi. |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | Pengecualian data untuk cloud backup dan transfer perangkat Android modern. |
| `android/app/build.gradle.kts` | Konfigurasi build aplikasi Android, application ID, SDK, dan versi. |
| `android/app/src/main/res/` | Ikon launcher, splash bawaan Android, warna, dan tema native. |
| `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Runner dan konfigurasi native Flutter untuk platform terkait; konfigurasi platform dapat berbeda. |

File seperti registrant plugin di folder `*/flutter/` dihasilkan oleh Flutter.
Biasanya file tersebut tidak perlu diedit secara manual.

## Menyiapkan Supabase

1. Buat project di Supabase.
2. Buka **SQL Editor**, lalu jalankan
   `supabase/migrations/20261031000000_initial_schema.sql`.
3. Di **Authentication → URL Configuration → Redirect URLs**, tambahkan:
   - `catatuang://login-callback`
   - `catatuang://reset-password`
4. Atur project URL dan publishable/anon key melalui
   `lib/core/supabase_config.dart` atau berikan saat menjalankan Flutter
   menggunakan `--dart-define`.

Jangan pernah menggunakan `service_role` key di aplikasi klien. Gunakan hanya
publishable/anon key dan pastikan kebijakan RLS aktif di Supabase.

Contoh menjalankan dengan konfigurasi Supabase melalui CLI:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```

Ganti nilai contoh dengan konfigurasi milik project Supabase Anda. Jangan
memasukkan `service_role` key.

## Menjalankan dan menguji

Pastikan Flutter SDK sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

Untuk memeriksa kode dan widget test:

```bash
flutter analyze
flutter test
```

Untuk membuat APK debug Android:

```bash
flutter build apk --debug
```

## Catatan data dan keamanan

- Saat ini, aturan Android menonaktifkan backup dan mengecualikan data aplikasi
  dari cloud backup maupun transfer perangkat. Data lokal tidak otomatis
  dipulihkan melalui mekanisme backup Android.
- HTTP cleartext dinonaktifkan pada Android. Endpoint Supabase harus
  menggunakan HTTPS.
- Cache dan antrean Hive diberi prefix berdasarkan ID pengguna agar data lokal
  tidak tercampur antar akun.
- Jika autentikasi email Supabase memerlukan konfirmasi, pengguna perlu
  menyelesaikan konfirmasi melalui email sebelum masuk, sesuai konfigurasi
  project.
