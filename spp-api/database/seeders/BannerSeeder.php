<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Banner;
use Carbon\Carbon;

class BannerSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $banners = [
            [
                'title' => 'Selamat Datang di SPP Digital',
                'description' => 'Bayar SPP lebih mudah dan cepat dengan sistem pembayaran digital.',
                'image' => 'banner_welcome',
                'link_url' => null,
                'is_active' => true,
                'order' => 1,
                'start_date' => null,
                'end_date' => null,
                'created_by' => 1,
            ],
            [
                'title' => 'Promo Pembayaran Tepat Waktu',
                'description' => 'Dapatkan diskon 10% untuk pembayaran SPP sebelum tanggal 10 setiap bulan.',
                'image' => 'banner_promo',
                'link_url' => null,
                'is_active' => true,
                'order' => 2,
                'start_date' => Carbon::now(),
                'end_date' => Carbon::now()->addMonths(3),
                'created_by' => 1,
            ],
            [
                'title' => 'Antrian Digital Tersedia',
                'description' => 'Ambil nomor antrian secara online, tidak perlu menunggu lama di loket.',
                'image' => 'banner_queue',
                'link_url' => null,
                'is_active' => true,
                'order' => 3,
                'start_date' => null,
                'end_date' => null,
                'created_by' => 1,
            ],
        ];

        foreach ($banners as $banner) {
            Banner::create($banner);
        }
    }
}

