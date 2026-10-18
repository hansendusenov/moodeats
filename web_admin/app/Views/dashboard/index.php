<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header & Control Bar -->
<div class="flex flex-wrap items-center justify-between gap-4">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span><?= esc(lang('Admin.brand_name')) ?></span>
            <span>/</span>
            <span><?= esc(lang('Admin.dashboard_telemetry')) ?></span>
            <span>/</span>
            <span class="text-red-600 font-bold"><?= esc(lang('Admin.dashboard_node')) ?></span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2">
            <?= esc(lang('Admin.dashboard_title')) ?>
            <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-300">
                <?= esc(lang('Admin.dashboard_live_badge')) ?>
            </span>
        </h1>
    </div>

    <!-- Quick Action Buttons -->
    <div class="flex items-center gap-2">
        <a href="<?= site_url('menus/create') ?>" class="h-8 px-3 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-semibold flex items-center gap-1.5 transition-colors shadow-xs">
            <span class="material-symbols-outlined text-[16px] text-red-600">add_circle</span>
            <?= esc(lang('Admin.dashboard_btn_menu')) ?>
        </a>
        <a href="<?= site_url('banners/create') ?>" class="h-8 px-3.5 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1.5 transition-all shadow-sm">
            <span class="material-symbols-outlined text-[16px]">campaign</span>
            <?= esc(lang('Admin.dashboard_btn_banner')) ?>
        </a>
    </div>
</div>

<!-- KPI Cards Grid (Row 1) -->
<section class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
    <!-- Card 1: Active Banners -->
    <div class="bg-white border border-red-100 rounded-xl p-4 border-t-4 border-t-red-600 shadow-xs">
        <div class="flex items-start justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold"><?= esc(lang('Admin.dashboard_kpi_banners')) ?></span>
            <span class="p-1 rounded bg-red-50 text-red-600">
                <span class="material-symbols-outlined text-[18px]">ad_units</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-slate-900 font-mono"><?= $activeBannersCount ?></span>
            <span class="text-xs text-slate-500 font-medium"><?= esc(lang('Admin.dashboard_kpi_banners_sub')) ?></span>
        </div>
        <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
            <a href="<?= site_url('banners') ?>" class="text-red-600 hover:text-red-700 font-semibold flex items-center gap-1">
                <?= esc(lang('Admin.view')) ?> <span class="material-symbols-outlined text-[14px]">arrow_forward</span>
            </a>
            <span class="text-[10px] text-slate-400 font-mono">Time-Parting</span>
        </div>
    </div>

    <!-- Card 2: Curated Menus -->
    <div class="bg-white border border-red-100 rounded-xl p-4 border-t-4 border-t-amber-500 shadow-xs">
        <div class="flex items-start justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold"><?= esc(lang('Admin.dashboard_kpi_menus')) ?></span>
            <span class="p-1 rounded bg-amber-50 text-amber-600">
                <span class="material-symbols-outlined text-[18px]">restaurant_menu</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-slate-900 font-mono"><?= $menusCount ?></span>
            <span class="text-xs text-slate-500 font-medium"><?= esc(lang('Admin.dashboard_kpi_menus_sub')) ?></span>
        </div>
        <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
            <a href="<?= site_url('menus') ?>" class="text-amber-600 hover:text-amber-700 font-semibold flex items-center gap-1">
                <?= esc(lang('Admin.view')) ?> <span class="material-symbols-outlined text-[14px]">arrow_forward</span>
            </a>
            <span class="text-[10px] text-slate-400 font-mono">Curated Local</span>
        </div>
    </div>

    <!-- Card 3: Sponsored Merchants -->
    <div class="bg-white border border-red-100 rounded-xl p-4 border-t-4 border-t-emerald-600 shadow-xs">
        <div class="flex items-start justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold"><?= esc(lang('Admin.dashboard_kpi_merchants')) ?></span>
            <span class="p-1 rounded bg-emerald-50 text-emerald-600">
                <span class="material-symbols-outlined text-[18px]">confirmation_number</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-slate-900 font-mono"><?= $merchantsCount ?></span>
            <span class="text-xs text-slate-500 font-medium"><?= esc(lang('Admin.dashboard_kpi_merchants_sub')) ?></span>
        </div>
        <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
            <a href="<?= site_url('merchants') ?>" class="text-emerald-600 hover:text-emerald-700 font-semibold flex items-center gap-1">
                <?= esc(lang('Admin.view')) ?> <span class="material-symbols-outlined text-[14px]">arrow_forward</span>
            </a>
            <span class="text-[10px] text-slate-400 font-mono">15m Timer Promo</span>
        </div>
    </div>

    <!-- Card 4: Total AI Sessions -->
    <div class="bg-white border border-red-100 rounded-xl p-4 border-t-4 border-t-indigo-600 shadow-xs">
        <div class="flex items-start justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold"><?= esc(lang('Admin.dashboard_kpi_sessions')) ?></span>
            <span class="p-1 rounded bg-indigo-50 text-indigo-600">
                <span class="material-symbols-outlined text-[18px]">psychology</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-slate-900 font-mono"><?= $totalSessionsCount ?></span>
            <span class="text-xs text-slate-500 font-medium"><?= esc(lang('Admin.dashboard_kpi_sessions_sub')) ?></span>
        </div>
        <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
            <span class="text-emerald-600 font-semibold flex items-center gap-1">
                <span class="material-symbols-outlined text-[14px]">trending_up</span> <?= esc(lang('Admin.dashboard_kpi_today')) ?>: <?= $todaySessionsCount ?>
            </span>
            <span class="text-[10px] text-slate-400 font-mono">Gemini 2.5 Flash</span>
        </div>
    </div>
</section>

<!-- Main Row: Live Sentiment History Table & Architecture Summary -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Recent Sessions Table (Span 2) -->
    <div class="lg:col-span-2 bg-white rounded-xl border border-red-100 shadow-xs p-5">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h2 class="text-base font-bold text-slate-900"><?= esc(lang('Admin.dashboard_history_title')) ?></h2>
                <p class="text-xs text-slate-500"><?= esc(lang('Admin.dashboard_history_desc')) ?></p>
            </div>
            <a href="<?= site_url('analytics') ?>" class="text-xs font-semibold text-red-600 hover:text-red-700 flex items-center gap-1">
                <?= esc(lang('Admin.dashboard_view_all')) ?> <span class="material-symbols-outlined text-[14px]">chevron_right</span>
            </a>
        </div>

        <?php if (empty($recentSessions)): ?>
            <div class="py-12 text-center text-slate-400 text-xs">
                <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">forum</span>
                <?= esc(lang('Admin.dashboard_history_empty')) ?>
            </div>
        <?php else: ?>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs">
                    <thead>
                        <tr class="border-b border-slate-100 text-slate-400 font-mono uppercase text-[10px]">
                            <th class="py-2.5 px-3"><?= esc(lang('Admin.dashboard_col_time_loc')) ?></th>
                            <th class="py-2.5 px-3"><?= esc(lang('Admin.dashboard_col_story')) ?></th>
                            <th class="py-2.5 px-3"><?= esc(lang('Admin.dashboard_col_mood')) ?></th>
                            <th class="py-2.5 px-3">City / Region</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <?php foreach ($recentSessions as $session): ?>
                            <?php
                                $mood = strtoupper($session['detected_mood'] ?? 'NEUTRAL');
                                $badgeClass = match($mood) {
                                    'TIRED'     => 'bg-amber-50 text-amber-700 border-amber-200',
                                    'STRESSED'  => 'bg-red-50 text-red-700 border-red-200',
                                    'HAPPY'     => 'bg-emerald-50 text-emerald-700 border-emerald-200',
                                    'SAD'       => 'bg-blue-50 text-blue-700 border-blue-200',
                                    'ANXIOUS'   => 'bg-purple-50 text-purple-700 border-purple-200',
                                    default     => 'bg-slate-50 text-slate-700 border-slate-200',
                                };
                            ?>
                            <tr class="hover:bg-slate-50/60 transition-colors">
                                <td class="py-3 px-3 text-slate-500 font-mono text-[11px] whitespace-nowrap">
                                    <?= date('d M, H:i', strtotime($session['created_at'])) ?>
                                </td>
                                <td class="py-3 px-3 font-medium text-slate-800 max-w-xs truncate" title="<?= esc($session['message_text']) ?>">
                                    "<?= esc($session['message_text']) ?>"
                                </td>
                                <td class="py-3 px-3 whitespace-nowrap">
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono border <?= $badgeClass ?>">
                                        <?= esc($mood) ?>
                                    </span>
                                </td>
                                <td class="py-3 px-3 text-slate-600 whitespace-nowrap">
                                    <?= esc($session['city_detected'] ?? 'Jakarta') ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>

    <!-- Right Sidebar Widget: Fast Action & Telemetry -->
    <div class="space-y-4">
        <!-- Telemetry Widget -->
        <div class="bg-white rounded-xl border border-red-100 p-5 shadow-xs">
            <h3 class="text-xs font-bold text-slate-900 uppercase tracking-wider font-mono mb-3 flex items-center gap-1.5">
                <span class="material-symbols-outlined text-red-600 text-[16px]">sensors</span>
                Engine Integration
            </h3>
            <ul class="space-y-2.5 text-xs">
                <li class="flex items-center justify-between p-2 rounded bg-slate-50 border border-slate-100">
                    <span class="text-slate-600">Database Supabase</span>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-200">CONNECTED</span>
                </li>
                <li class="flex items-center justify-between p-2 rounded bg-slate-50 border border-slate-100">
                    <span class="text-slate-600">Google Gemini 2.5 Flash</span>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-200">ACTIVE</span>
                </li>
                <li class="flex items-center justify-between p-2 rounded bg-slate-50 border border-slate-100">
                    <span class="text-slate-600">Places API (New v1)</span>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-200">ACTIVE</span>
                </li>
                <li class="flex items-center justify-between p-2 rounded bg-slate-50 border border-slate-100">
                    <span class="text-slate-600">Places Cache Quota Saver</span>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-indigo-50 text-indigo-700 border border-indigo-200">7-DAY TTL</span>
                </li>
            </ul>
        </div>

        <!-- Quick Info Card -->
        <div class="bg-gradient-to-br from-red-600 to-red-700 rounded-xl p-5 text-white shadow-sm">
            <div class="flex items-center gap-2 mb-2">
                <span class="material-symbols-outlined text-[20px]">auto_awesome</span>
                <span class="text-xs font-bold uppercase tracking-wider font-mono">Autonomous Commerce</span>
            </div>
            <p class="text-xs text-red-100 leading-relaxed mb-4">
                <?= esc(lang('Admin.merchants_desc')) ?>
            </p>
            <a href="<?= site_url('merchants') ?>" class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white text-red-700 font-bold text-xs hover:bg-red-50 transition-colors shadow-xs">
                <span><?= esc(lang('Admin.nav_merchants')) ?></span>
                <span class="material-symbols-outlined text-[14px]">arrow_forward</span>
            </a>
        </div>
    </div>
</div>

<?= $this->endSection() ?>
