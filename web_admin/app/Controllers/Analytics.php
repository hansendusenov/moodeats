<?php

namespace App\Controllers;

use App\Models\MoodSessionModel;
use App\Models\UserProfileModel;

class Analytics extends BaseController
{
    public function index()
    {
        $sessionModel = new MoodSessionModel();
        $sessions = $sessionModel->orderBy('created_at', 'DESC')->findAll(100);

        $totalSessions = count($sessions);
        $todayStr = date('Y-m-d');
        $todaySessions = 0;
        $sentimentCounts = [];
        $cityCounts = [];

        foreach ($sessions as $s) {
            if (str_starts_with($s['created_at'] ?? '', $todayStr)) {
                $todaySessions++;
            }

            $mood = trim($s['detected_mood'] ?? '');
            if ($mood === '') {
                $mood = 'Neutral';
            }
            $sentimentCounts[$mood] = ($sentimentCounts[$mood] ?? 0) + 1;

            $city = trim($s['city_detected'] ?? 'Jakarta');
            $cityCounts[$city] = ($cityCounts[$city] ?? 0) + 1;
        }

        arsort($sentimentCounts);
        arsort($cityCounts);

        // Telemetry Analitik Perangkat, OS & Versi Aplikasi
        $userModel = new UserProfileModel();
        $users = $userModel->findAll();

        $osCounts = [];
        $deviceCounts = [];
        $appVersionCounts = [];
        $activeDevicesCount = 0;

        foreach ($users as $u) {
            $os = trim($u['device_os'] ?? '');
            if ($os !== '') {
                $osCounts[$os] = ($osCounts[$os] ?? 0) + 1;
                $activeDevicesCount++;
            }

            $model = trim($u['device_model'] ?? '');
            if ($model !== '') {
                $deviceCounts[$model] = ($deviceCounts[$model] ?? 0) + 1;
            }

            $ver = trim($u['app_version'] ?? '');
            if ($ver !== '') {
                $appVersionCounts[$ver] = ($appVersionCounts[$ver] ?? 0) + 1;
            }
        }

        arsort($osCounts);
        arsort($deviceCounts);
        arsort($appVersionCounts);

        return view('analytics/index', [
            'title'              => 'AI Sentiment Analytics & Live Mobile Telemetry',
            'active_menu'        => 'analytics',
            'sessions'           => $sessions,
            'totalSessions'      => $totalSessions,
            'todaySessions'      => $todaySessions,
            'sentimentCounts'    => $sentimentCounts,
            'cityCounts'         => $cityCounts,
            'osCounts'           => $osCounts,
            'deviceCounts'       => $deviceCounts,
            'appVersionCounts'   => $appVersionCounts,
            'activeDevicesCount' => $activeDevicesCount,
        ]);
    }
}
