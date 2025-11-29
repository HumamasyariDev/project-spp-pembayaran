# Mapping Kolom Database (English → Indonesia)

## Tabel Users
| English | Indonesia |
|---------|-----------|
| name | name (tetap) |
| email | email (tetap) |
| phone | telepon |
| address | alamat |
| class | kelas |
| gender | jenis_kelamin |

## Tabel Queues
| English | Indonesia |
|---------|-----------|
| queue_number | nomor_antrian |
| status | status (tetap, nilai berubah) |
| queue_date | tanggal_antrian |
| called_by | dipanggil_oleh |
| called_at | waktu_dipanggil |
| served_at | waktu_dilayani |
| completed_at | waktu_selesai |

### Status Queue
| English | Indonesia |
|---------|-----------|
| waiting | menunggu |
| called | dipanggil |
| served | dilayani |
| completed | selesai |
| cancelled | dibatalkan |

## Tabel SPP Bills
| English | Indonesia |
|---------|-----------|
| bill_number | nomor_tagihan |
| month | bulan |
| year | tahun |
| amount | jumlah |
| status | status (tetap, nilai berubah) |
| due_date | tanggal_jatuh_tempo |

### Status SPP Bill
| English | Indonesia |
|---------|-----------|
| unpaid | belum_dibayar |
| pending | menunggu_verifikasi |
| paid | lunas |

## Tabel Payments
| English | Indonesia |
|---------|-----------|
| payment_number | nomor_pembayaran |
| amount | jumlah |
| payment_method | metode_pembayaran |
| proof_image | bukti_pembayaran |
| status | status (tetap, nilai berubah) |
| verified_by | diverifikasi_oleh |
| verified_at | waktu_verifikasi |
| notes | catatan |

### Status Payment
| English | Indonesia |
|---------|-----------|
| pending | menunggu |
| verified | diverifikasi |
| rejected | ditolak |

### Metode Pembayaran
| English | Indonesia |
|---------|-----------|
| cash | tunai |
| transfer | transfer |
| e-wallet | e-wallet (tetap) |
