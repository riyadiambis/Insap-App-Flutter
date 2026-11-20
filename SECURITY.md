# Kebijakan Keamanan

## Melaporkan celah

Jika menemukan celah keamanan atau kebocoran data di Insap, mohon **jangan** membuka issue publik. Kirim laporan ke **rahmatriyadiambis@gmail.com** dengan subjek `[Keamanan Insap]`, berisi:

- ringkasan celah dan dampaknya,
- langkah untuk mengulang (versi aplikasi, perangkat, contoh permintaan bila ada),
- kontak yang bisa dihubungi.

Kami akan membalas dalam 7 hari kerja, memberi kabar perkembangan perbaikan, dan mencantumkan nama pelapor bila diinginkan setelah perbaikan rilis. Mohon beri waktu perbaikan sebelum mengungkapkan celah ke publik.

## Versi yang didukung

Perbaikan keamanan hanya diberikan untuk versi terbaru yang tersedia di Google Play.

## Catatan

Konfigurasi klien Firebase (`google-services.json`, `lib/firebase_options.dart`) memang bersifat publik pada aplikasi Android. Keamanan data dijaga oleh aturan Firestore (`firestore.rules`) dan pembatasan kunci di Google Cloud, bukan oleh kerahasiaan berkas tersebut.
