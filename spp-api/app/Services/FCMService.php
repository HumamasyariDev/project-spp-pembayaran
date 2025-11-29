<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Exception;

class FCMService
{
    protected $messaging;

    public function __construct()
    {
        try {
            // Initialize Firebase Messaging
            // Try multiple paths for credentials:
            // 1. Environment variable: FIREBASE_CREDENTIALS
            // 2. storage/firebase/service-account.json (recommended)
            // 3. base_path/firebase-service-account.json (alternative)
            
            $credentialsPath = env('FIREBASE_CREDENTIALS');
            
            // Fallback paths
            if (!$credentialsPath || !file_exists($credentialsPath)) {
                $possiblePaths = [
                    storage_path('firebase/service-account.json'),
                    base_path('firebase-service-account.json'),
                    base_path('storage/firebase/service-account.json'),
                ];
                
                foreach ($possiblePaths as $path) {
                    if (file_exists($path)) {
                        $credentialsPath = $path;
                        break;
                    }
                }
            }
            
            if ($credentialsPath && file_exists($credentialsPath)) {
                $factory = (new Factory)->withServiceAccount($credentialsPath);
                $this->messaging = $factory->createMessaging();
                logger()->info("Firebase initialized with credentials: $credentialsPath");
            } else {
                // Fallback: FCM disabled if no credentials
                logger()->warning('Firebase credentials not found. FCM notifications disabled.');
                logger()->warning('Expected paths: storage/firebase/service-account.json or set FIREBASE_CREDENTIALS env');
                $this->messaging = null;
            }
        } catch (Exception $e) {
            logger()->error('Failed to initialize Firebase: ' . $e->getMessage());
            $this->messaging = null;
        }
    }

    /**
     * Send FCM notification to a specific device token
     */
    public function sendToDevice(string $token, string $title, string $body, array $data = [])
    {
        if (!$this->messaging) {
            logger()->warning('FCM messaging not initialized. Skipping notification.');
            return false;
        }

        try {
            logger()->info('📤 Preparing FCM message', [
                'title' => $title,
                'body' => $body,
                'data' => $data,
            ]);
            
            $notification = Notification::create($title, $body);
            
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification)
                ->withData($data);

            $result = $this->messaging->send($message);
            
            logger()->info("✅ FCM notification sent successfully", [
                'title' => $title,
                'result' => $result,
            ]);
            return true;
        } catch (Exception $e) {
            logger()->error('❌ Failed to send FCM notification: ' . $e->getMessage(), [
                'exception' => get_class($e),
                'trace' => $e->getTraceAsString(),
            ]);
            return false;
        }
    }

    /**
     * Send payment success notification - SeaBank Style 🏦
     */
    public function sendPaymentSuccessNotification(string $token, array $paymentData)
    {
        // Professional title
        $title = 'Pembayaran Berhasil';
        
        // SeaBank-style body: detailed & informative
        $bulan = $paymentData['bulan'] ?? '';
        $tahun = $paymentData['tahun'] ?? date('Y');
        $jumlah = number_format($paymentData['jumlah'] ?? 0, 0, ',', '.');
        
        // Format payment method from Midtrans to user-friendly name
        $metodeBayarRaw = $paymentData['metode_bayar'] ?? 'virtual account';
        $metodeBayar = $this->formatPaymentMethod($metodeBayarRaw);
        
        // Format tanggal Indonesia (05 Nov 2025 16:40 WIB) - REALTIME from database
        $tanggalBayar = $paymentData['tanggal_bayar'] ?? now();
        $tanggal = \Carbon\Carbon::parse($tanggalBayar)->locale('id')->isoFormat('DD MMM YYYY HH:mm');
        
        // Body format mirip SeaBank - with dynamic payment method
        $body = "Kamu telah melakukan transfer {$metodeBayar} sebesar Rp.{$jumlah} kepada Sekolah pada {$tanggal} WIB";

        $data = [
            'type' => 'payment_success',
            'payment_id' => (string) ($paymentData['id'] ?? ''),
            'bulan' => $paymentData['bulan'] ?? '',
            'jumlah' => (string) ($paymentData['jumlah'] ?? 0),
            'timestamp' => now()->toIso8601String(),
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'screen' => 'history', // Navigate to history screen
        ];

        return $this->sendToDevice($token, $title, $body, $data);
    }

    /**
     * Format Midtrans payment method to user-friendly name
     */
    private function formatPaymentMethod(string $method): string
    {
        $mappings = [
            'bank_transfer' => 'virtual account',
            'echannel' => 'virtual account',
            'bca_va' => 'virtual account BCA',
            'bni_va' => 'virtual account BNI',
            'bri_va' => 'virtual account BRI',
            'permata_va' => 'virtual account Permata',
            'other_va' => 'virtual account',
            'gopay' => 'GoPay',
            'shopeepay' => 'ShopeePay',
            'qris' => 'QRIS',
            'credit_card' => 'kartu kredit',
            'debit_card' => 'kartu debit',
            'cimb_clicks' => 'CIMB Clicks',
            'bca_klikbca' => 'BCA KlikBCA',
            'bca_klikpay' => 'BCA KlikPay',
            'bri_epay' => 'BRI e-Pay',
            'danamon_online' => 'Danamon Online Banking',
            'alfamart' => 'Alfamart',
            'indomaret' => 'Indomaret',
            'akulaku' => 'Akulaku',
        ];

        $lowerMethod = strtolower($method);
        return $mappings[$lowerMethod] ?? $method;
    }

    /**
     * Send payment reminder notification
     */
    public function sendPaymentReminderNotification(string $token, array $billData)
    {
        $title = '⏰ Pengingat Pembayaran SPP';
        $body = sprintf(
            'Tagihan SPP %s sebesar Rp %s akan jatuh tempo pada %s',
            $billData['bulan'] ?? '',
            number_format($billData['jumlah'] ?? 0, 0, ',', '.'),
            $billData['jatuh_tempo'] ?? ''
        );

        $data = [
            'type' => 'payment_reminder',
            'bill_id' => (string) ($billData['id'] ?? ''),
            'bulan' => $billData['bulan'] ?? '',
            'jumlah' => (string) ($billData['jumlah'] ?? 0),
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        return $this->sendToDevice($token, $title, $body, $data);
    }

    /**
     * Check if FCM is enabled
     */
    public function isEnabled(): bool
    {
        return $this->messaging !== null;
    }
}

