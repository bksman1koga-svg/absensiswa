# SISTEM INFORMASI SEKOLAH TERPADU OFFLINE

Implementasi berdasarkan spesifikasi yang diberikan: modul pembelajaran, absensi offline, rekap nilai offline, integrasi guru-kelas-peserta didik, PWA, IndexedDB, laporan, serta backup/restore lokal.

## Jalankan
- Untuk PWA/service worker gunakan HTTPS atau localhost.
- Ekstrak ZIP lalu host sebagai static website.
- Bisa dipasang di Vercel, Cloudflare Pages, GitHub Pages, atau hosting sekolah yang mendukung HTTPS.

## Modul V1
- Dashboard
- Guru, peserta didik, kelas, mata pelajaran
- Modul pembelajaran
- Absensi H/S/I/A offline + pencegahan duplikasi jadwal
- Input nilai offline dan jenis asesmen fleksibel
- Rekap absensi + rata-rata nilai
- Backup/restore JSON
- Pengaturan sekolah
- Service Worker/PWA

## Catatan keamanan
Login dalam V1 adalah demo lokal. Untuk penggunaan sekolah nyata, hak ADMIN, KEPALA SEKOLAH, GURU, ORANG TUA, SISWA, dan TAMU harus ditegakkan oleh backend/identity provider, bukan hanya JavaScript di browser. Sinkronisasi pusat juga perlu API dan audit log.
