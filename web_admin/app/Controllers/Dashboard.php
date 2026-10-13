<?php

namespace App\Controllers;

use App\Models\BannerModel;
use App\Models\DefaultMenuModel;
use App\Models\SponsoredMerchantModel;
use App\Models\MoodSessionModel;

class Dashboard extends BaseController
{
    public function index()
    {
        $bannerModel   = new BannerModel();
        $menuModel     = new DefaultMenuModel();
        $merchantModel = new SponsoredMerchantModel();
        $sessionModel  = new MoodSessionModel();

        $activeBannersCount   = $bannerModel->where('is_active', true)->countAllResults();
        $menusCount           = $menuModel->countAllResults();
        $merchantsCount       = $merchantModel->countAllResults();
        $totalSessionsCount   = $sessionModel->countAllResults();

        // Sessions today
        $today = date('Y-m-d 00:00:00');
        $todaySessionsCount   = $sessionModel->where('created_at >=', $today)->countAllResults();

        // Recent sessions
        $recentSessions       = $sessionModel->getRecentSessions(8);

        $data = [
            'title'               => 'Overview & Sentiment Analytics',
            'active_menu'         => 'dashboard',
            'activeBannersCount'  => $activeBannersCount,
            'menusCount'          => $menusCount,
            'merchantsCount'      => $merchantsCount,
            'totalSessionsCount'  => $totalSessionsCount,
            'todaySessionsCount'  => $todaySessionsCount,
            'recentSessions'      => $recentSessions,
        ];

        return view('dashboard/index', $data);
    }
}
