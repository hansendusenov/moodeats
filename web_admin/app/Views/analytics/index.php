<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header & Engine Status -->
<div class="flex flex-wrap items-center justify-between gap-4 mb-6">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span>Admin Console</span>
            <span>/</span>
            <span>Telemetri Aplikasi Mobile</span>
            <span>/</span>
            <span class="text-red-600 font-bold">Log Percakapan & Rekomendasi</span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2.5">
            Log Penggunaan Mobile &amp; AI Analytics
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-300">
                DATABASE LIVE
            </span>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            Merekam seluruh interaksi curhatan emosi, input suara, analisis suasana hati, dan rekomendasi tempat makan (maksimal radius 10 km) dari aplikasi mobile Flutter.
        </p>
    </div>
    <div class="flex items-center gap-2">
        <span class="px-3 py-1.5 rounded-lg text-xs font-mono font-bold bg-white text-slate-700 border border-slate-200 shadow-xs flex items-center gap-2">
            <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Engine: Gemini 2.5 Flash
        </span>
    </div>
</div>

<!-- KPI Summary Cards -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
    <div class="bg-white rounded-xl p-4 border border-red-100 shadow-xs border-t-4 border-t-red-600">
        <div class="flex items-center justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Total Sesi Mobile</span>
            <span class="p-1 rounded bg-red-50 text-red-600">
                <span class="material-symbols-outlined text-[18px]">phone_android</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold font-mono text-slate-900"><?= $totalSessions ?></span>
            <span class="text-xs text-slate-500">kali curhat</span>
        </div>
        <p class="mt-2 text-[11px] text-slate-400">Tersimpan di tabel Supabase <code class="font-mono text-red-600 font-semibold">mood_sessions</code></p>
    </div>

    <div class="bg-white rounded-xl p-4 border border-red-100 shadow-xs border-t-4 border-t-emerald-600">
        <div class="flex items-center justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Sesi Hari Ini</span>
            <span class="p-1 rounded bg-emerald-50 text-emerald-600">
                <span class="material-symbols-outlined text-[18px]">today</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold font-mono text-slate-900"><?= $todaySessions ?></span>
            <span class="text-xs text-slate-500">interaksi hari ini</span>
        </div>
        <p class="mt-2 text-[11px] text-emerald-600 font-medium flex items-center gap-1">
            <span class="material-symbols-outlined text-[14px]">bolt</span> Real-time streaming
        </p>
    </div>

    <div class="bg-white rounded-xl p-4 border border-red-100 shadow-xs border-t-4 border-t-amber-500">
        <div class="flex items-center justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Variasi Sentimen</span>
            <span class="p-1 rounded bg-amber-50 text-amber-600">
                <span class="material-symbols-outlined text-[18px]">psychology</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold font-mono text-slate-900"><?= count($sentimentCounts) ?></span>
            <span class="text-xs text-slate-500">mood terdeteksi</span>
        </div>
        <p class="mt-2 text-[11px] text-slate-400">Analisis NLP bahasa Indonesia</p>
    </div>

    <div class="bg-white rounded-xl p-4 border border-red-100 shadow-xs border-t-4 border-t-indigo-600">
        <div class="flex items-center justify-between">
            <span class="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Area Populer</span>
            <span class="p-1 rounded bg-indigo-50 text-indigo-600">
                <span class="material-symbols-outlined text-[18px]">location_on</span>
            </span>
        </div>
        <div class="mt-2 flex items-baseline gap-2">
            <span class="text-xl font-extrabold font-mono text-slate-900 truncate">
                <?= !empty($cityCounts) ? esc(array_key_first($cityCounts)) : 'Jabodetabek' ?>
            </span>
        </div>
        <p class="mt-2 text-[11px] text-indigo-600 font-medium">Radius ketat &le; 10.0 km</p>
    </div>
</div>

<!-- Top Mood Tags Breakdown -->
<div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs mb-6">
    <div class="flex items-center justify-between mb-3">
        <h2 class="text-xs font-mono uppercase tracking-wider text-slate-500 font-bold flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px] text-red-600">sentiment_satisfied</span>
            Distribusi Sentimen Terdeteksi di Mobile
        </h2>
        <span class="text-[11px] font-mono text-slate-400">Terbanyak &rarr; Terendah</span>
    </div>
    <div class="flex flex-wrap gap-2">
        <?php foreach ($sentimentCounts as $moodText => $count): ?>
            <?php
                $lower = strtolower($moodText);
                $badgeStyle = 'bg-slate-100 text-slate-700 border-slate-200';
                if (str_contains($lower, 'lelah') || str_contains($lower, 'tired')) {
                    $badgeStyle = 'bg-amber-50 text-amber-800 border-amber-300';
                } elseif (str_contains($lower, 'stres') || str_contains($lower, 'stress')) {
                    $badgeStyle = 'bg-red-50 text-red-800 border-red-300';
                } elseif (str_contains($lower, 'ngidam') || str_contains($lower, 'pedas') || str_contains($lower, 'crave')) {
                    $badgeStyle = 'bg-rose-50 text-rose-800 border-rose-300';
                } elseif (str_contains($lower, 'dingin') || str_contains($lower, 'kurang nyaman')) {
                    $badgeStyle = 'bg-cyan-50 text-cyan-800 border-cyan-300';
                } elseif (str_contains($lower, 'senang') || str_contains($lower, 'happy')) {
                    $badgeStyle = 'bg-emerald-50 text-emerald-800 border-emerald-300';
                }
            ?>
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-medium border <?= $badgeStyle ?>">
                <span><?= esc($moodText) ?></span>
                <span class="font-mono font-bold px-1.5 py-0.2 rounded-full bg-white/80 text-[10px] shadow-2xs">
                    <?= $count ?>
                </span>
            </span>
        <?php endforeach; ?>
    </div>
</div>

<!-- Telemetri Perangkat & Versi Aplikasi -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <!-- Card 1: Distribusi OS -->
    <div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs">
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-xs font-mono uppercase tracking-wider text-slate-500 font-bold flex items-center gap-1.5">
                <span class="material-symbols-outlined text-[16px] text-emerald-600">smartphone</span>
                Sistem Operasi (OS)
            </h3>
            <span class="text-[10px] font-mono text-slate-400"><?= $activeDevicesCount ?> Perangkat</span>
        </div>
        <?php if (empty($osCounts)): ?>
            <p class="text-xs text-slate-400 italic py-2">Belum ada data OS tercatat.</p>
        <?php else: ?>
            <div class="space-y-2.5">
                <?php foreach ($osCounts as $osName => $cnt): 
                    $percent = $activeDevicesCount > 0 ? round(($cnt / $activeDevicesCount) * 100) : 0;
                    $isAndroid = str_contains(strtolower($osName), 'android');
                    $isIos = str_contains(strtolower($osName), 'ios');
                ?>
                    <div>
                        <div class="flex items-center justify-between text-xs mb-1">
                            <span class="font-semibold text-slate-800 flex items-center gap-1.5 truncate">
                                <span class="material-symbols-outlined text-[14px] <?= $isAndroid ? 'text-emerald-600' : ($isIos ? 'text-slate-800' : 'text-slate-500') ?>">
                                    <?= $isIos ? 'phone_iphone' : 'phone_android' ?>
                                </span>
                                <?= esc($osName) ?>
                            </span>
                            <span class="font-mono font-bold text-slate-600"><?= $cnt ?> (<?= $percent ?>%)</span>
                        </div>
                        <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                            <div class="h-full <?= $isAndroid ? 'bg-emerald-500' : 'bg-slate-700' ?> rounded-full" style="width: <?= $percent ?>%"></div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

    <!-- Card 2: Model Perangkat -->
    <div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs">
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-xs font-mono uppercase tracking-wider text-slate-500 font-bold flex items-center gap-1.5">
                <span class="material-symbols-outlined text-[16px] text-blue-600">devices</span>
                Model Perangkat Teratas
            </h3>
            <span class="text-[10px] font-mono text-slate-400"><?= count($deviceCounts) ?> Tipe</span>
        </div>
        <?php if (empty($deviceCounts)): ?>
            <p class="text-xs text-slate-400 italic py-2">Belum ada data model perangkat.</p>
        <?php else: ?>
            <div class="space-y-2.5">
                <?php foreach (array_slice($deviceCounts, 0, 5, true) as $devModel => $cnt): 
                    $percent = $activeDevicesCount > 0 ? round(($cnt / $activeDevicesCount) * 100) : 0;
                ?>
                    <div>
                        <div class="flex items-center justify-between text-xs mb-1">
                            <span class="font-semibold text-slate-800 truncate max-w-[170px]" title="<?= esc($devModel) ?>">
                                <?= esc($devModel) ?>
                            </span>
                            <span class="font-mono font-bold text-slate-600"><?= $cnt ?> device</span>
                        </div>
                        <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                            <div class="h-full bg-blue-600 rounded-full" style="width: <?= $percent ?>%"></div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

    <!-- Card 3: Adopsi Versi Aplikasi -->
    <div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs">
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-xs font-mono uppercase tracking-wider text-slate-500 font-bold flex items-center gap-1.5">
                <span class="material-symbols-outlined text-[16px] text-purple-600">deployed_code</span>
                Versi Aplikasi Mobile
            </h3>
            <span class="text-[10px] font-mono text-emerald-600 font-bold">Build Aktif</span>
        </div>
        <?php if (empty($appVersionCounts)): ?>
            <p class="text-xs text-slate-400 italic py-2">Belum ada data versi aplikasi.</p>
        <?php else: ?>
            <div class="space-y-2.5">
                <?php foreach ($appVersionCounts as $appVer => $cnt): 
                    $percent = $activeDevicesCount > 0 ? round(($cnt / $activeDevicesCount) * 100) : 0;
                ?>
                    <div>
                        <div class="flex items-center justify-between text-xs mb-1">
                            <span class="font-mono font-bold text-purple-700 bg-purple-50 px-2 py-0.5 rounded border border-purple-200">
                                <?= esc($appVer) ?>
                            </span>
                            <span class="font-mono font-bold text-slate-600"><?= $cnt ?> (<?= $percent ?>%)</span>
                        </div>
                        <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                            <div class="h-full bg-purple-600 rounded-full" style="width: <?= $percent ?>%"></div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Main Table: Log Penggunaan Mobile -->
<div class="bg-white rounded-xl border border-red-100 shadow-xs overflow-hidden">
    <div class="p-4 border-b border-slate-100 flex flex-wrap items-center justify-between gap-3 bg-slate-50/50">
        <div>
            <h2 class="text-sm font-bold text-slate-900 flex items-center gap-2">
                <span class="material-symbols-outlined text-[18px] text-red-600">table_rows</span>
                Daftar Riwayat Sesi Percakapan Mobile (Terkini)
            </h2>
            <p class="text-[11px] text-slate-500">Klik "Detail AI" pada tiap baris untuk melihat kuliner, tempat makan, serta mitra voucher yang disarankan AI.</p>
        </div>
        <div class="flex items-center gap-2.5 flex-1 max-w-sm justify-end">
            <div class="relative w-full">
                <span class="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-[16px] text-slate-400">search</span>
                <input type="text" id="logSearchInput" placeholder="Cari curhatan, mood, session ID, atau kota..." 
                       class="w-full pl-8 pr-7 py-1.5 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                <button id="clearLogSearchBtn" class="hidden absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                    <span class="material-symbols-outlined text-[14px]">cancel</span>
                </button>
            </div>
        </div>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50 text-slate-500 font-mono uppercase text-[10px]">
                    <th class="py-3 px-4">Waktu (WIB)</th>
                    <th class="py-3 px-4">Curhatan Pengguna (Prompt)</th>
                    <th class="py-3 px-4">Sentimen Terdeteksi</th>
                    <th class="py-3 px-4">Kategori Kuliner</th>
                    <th class="py-3 px-4">Lokasi &amp; Radius</th>
                    <th class="py-3 px-4 text-center">Aksi / Detail</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php if (empty($sessions)): ?>
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">inbox</span>
                            Belum ada sesi curhat mobile yang tercatat. Lakukan rekomendasi di aplikasi Android untuk menguji.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($sessions as $index => $s): ?>
                        <?php
                            $mood = $s['detected_mood'] ?? 'Neutral';
                            $lowerMood = strtolower($mood);
                            $badgeClass = 'bg-slate-50 text-slate-700 border-slate-200';
                            if (str_contains($lowerMood, 'lelah') || str_contains($lowerMood, 'tired')) {
                                $badgeClass = 'bg-amber-50 text-amber-700 border-amber-300';
                            } elseif (str_contains($lowerMood, 'stres') || str_contains($lowerMood, 'stress')) {
                                $badgeClass = 'bg-red-50 text-red-700 border-red-300';
                            } elseif (str_contains($lowerMood, 'ngidam') || str_contains($lowerMood, 'pedas') || str_contains($lowerMood, 'crave')) {
                                $badgeClass = 'bg-rose-50 text-rose-700 border-rose-300';
                            } elseif (str_contains($lowerMood, 'dingin') || str_contains($lowerMood, 'kurang nyaman')) {
                                $badgeClass = 'bg-cyan-50 text-cyan-700 border-cyan-300';
                            } elseif (str_contains($lowerMood, 'senang') || str_contains($lowerMood, 'happy')) {
                                $badgeClass = 'bg-emerald-50 text-emerald-700 border-emerald-300';
                            }

                            $categories = json_decode($s['food_categories'] ?? '[]', true) ?: [];
                            $payload = json_decode($s['ai_response_payload'] ?? '{}', true) ?: [];
                            $places = $payload['places'] ?? [];
                            $menus = $payload['menus'] ?? [];
                            $sponsor = $payload['sponsored_merchant'] ?? null;
                            $rationale = $payload['rationale'] ?? $payload['comfort_explanation'] ?? '';
                        ?>
                        <tr class="log-row hover:bg-slate-50/70 transition-colors"
                            data-index="<?= $index ?>"
                            data-search="<?= esc(strtolower($s['message_text'] . ' ' . $mood . ' ' . ($s['city_detected'] ?? '') . ' ' . $s['session_id'])) ?>">
                            <!-- Waktu -->
                            <td class="py-3 px-4 font-mono text-slate-500 whitespace-nowrap">
                                <div class="font-semibold text-slate-700"><?= date('d M Y', strtotime($s['created_at'])) ?></div>
                                <div class="text-[11px] text-slate-400"><?= date('H:i:s', strtotime($s['created_at'])) ?> WIB</div>
                            </td>

                            <!-- Curhatan Pengguna -->
                            <td class="py-3 px-4 max-w-sm">
                                <div class="text-slate-800 font-medium line-clamp-2" title="<?= esc($s['message_text']) ?>">
                                    "<?= esc($s['message_text']) ?>"
                                </div>
                                <div class="font-mono text-[10px] text-slate-400 mt-0.5">
                                    ID: <?= substr($s['session_id'], 0, 8) ?>...
                                </div>
                            </td>

                            <!-- Mood -->
                            <td class="py-3 px-4 whitespace-nowrap">
                                <span class="px-2.5 py-1 rounded text-[11px] font-bold border <?= $badgeClass ?>">
                                    <?= esc($mood) ?>
                                </span>
                            </td>

                            <!-- Kategori Kuliner -->
                            <td class="py-3 px-4">
                                <div class="flex flex-wrap gap-1 max-w-xs">
                                    <?php if (!empty($categories)): ?>
                                        <?php foreach ($categories as $cat): ?>
                                            <span class="px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 text-[10px] font-medium">
                                                <?= esc($cat) ?>
                                            </span>
                                        <?php endforeach; ?>
                                    <?php else: ?>
                                        <span class="text-slate-400 text-[11px]">-</span>
                                    <?php endif; ?>
                                </div>
                            </td>

                            <!-- Lokasi & Radius -->
                            <td class="py-3 px-4 whitespace-nowrap">
                                <div class="font-semibold text-slate-800 flex items-center gap-1">
                                    <span class="material-symbols-outlined text-[14px] text-red-600">location_on</span>
                                    <?= esc($s['city_detected'] ?? 'Jakarta') ?>
                                </div>
                                <?php if ($s['location_lat'] && $s['location_lng']): ?>
                                    <div class="font-mono text-[10px] text-slate-400 mt-0.5">
                                        <?= number_format($s['location_lat'], 4) ?>, <?= number_format($s['location_lng'], 4) ?>
                                    </div>
                                <?php endif; ?>
                            </td>

                            <!-- Detail Trigger Button -->
                            <td class="py-3 px-4 text-center whitespace-nowrap">
                                <button type="button" onclick="toggleDetail('detail-<?= $index ?>')" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-red-50 hover:border-red-200 hover:text-red-600 font-semibold text-[11px] text-slate-700 transition-colors shadow-2xs">
                                    <span class="material-symbols-outlined text-[14px]">visibility</span>
                                    Detail AI
                                </button>
                            </td>
                        </tr>

                        <!-- Expandable Accordion Detail Row -->
                        <tr id="detail-<?= $index ?>" class="log-detail-row hidden bg-slate-50/80 border-b border-red-100" data-detail-for="<?= $index ?>">
                            <td colspan="6" class="p-4">
                                <div class="bg-white rounded-xl p-4 border border-slate-200 shadow-xs space-y-4">
                                    <!-- Header Info -->
                                    <div class="flex flex-wrap items-center justify-between border-b border-slate-100 pb-2.5 gap-2">
                                        <div class="flex items-center gap-2">
                                            <span class="p-1 rounded bg-red-100 text-red-700 material-symbols-outlined text-[16px]">smart_toy</span>
                                            <span class="font-bold text-slate-900 text-xs">Hasil Lengkap Rekomendasi AI Gemini</span>
                                        </div>
                                        <span class="text-[10px] font-mono text-slate-400">Session UUID: <?= esc($s['session_id']) ?></span>
                                    </div>

                                    <!-- AI Rationale -->
                                    <?php if (!empty($rationale)): ?>
                                        <div class="bg-amber-50/60 border border-amber-200 rounded-lg p-3 text-xs text-amber-900">
                                            <span class="font-bold block mb-1 flex items-center gap-1 text-amber-800">
                                                <span class="material-symbols-outlined text-[14px]">psychology</span>
                                                Alasan / Mood Rationale:
                                            </span>
                                            <?= esc($rationale) ?>
                                        </div>
                                    <?php endif; ?>

                                    <!-- 2-Column: Menus & Places -->
                                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        <!-- Comfort Foods Recommended -->
                                        <div class="border border-slate-100 rounded-lg p-3 bg-slate-50/40">
                                            <span class="font-bold text-xs text-slate-800 block mb-2 flex items-center gap-1.5">
                                                <span class="material-symbols-outlined text-[16px] text-red-600">soup_kitchen</span>
                                                Menu Comfort Food Disarankan
                                            </span>
                                            <?php if (!empty($menus)): ?>
                                                <div class="space-y-2">
                                                    <?php foreach ($menus as $m): ?>
                                                        <div class="bg-white p-2.5 rounded border border-slate-200">
                                                            <div class="font-bold text-slate-900 text-xs"><?= esc($m['name'] ?? '-') ?></div>
                                                            <div class="text-[11px] text-slate-500 mt-0.5"><?= esc($m['description'] ?? '') ?></div>
                                                            <?php if (!empty($m['reason'])): ?>
                                                                <div class="text-[10px] text-amber-700 bg-amber-50 p-1 rounded mt-1">💡 <?= esc($m['reason']) ?></div>
                                                            <?php endif; ?>
                                                        </div>
                                                    <?php endforeach; ?>
                                                </div>
                                            <?php else: ?>
                                                <div class="text-xs text-slate-400 italic">Tidak ada rincian menu.</div>
                                            <?php endif; ?>
                                        </div>

                                        <!-- Nearby Places (Radius <= 10km) -->
                                        <div class="border border-slate-100 rounded-lg p-3 bg-slate-50/40">
                                            <span class="font-bold text-xs text-slate-800 block mb-2 flex items-center gap-1.5">
                                                <span class="material-symbols-outlined text-[16px] text-emerald-600">storefront</span>
                                                Tempat Makan Terdekat (&le; 10.0 km)
                                            </span>
                                            <?php if (!empty($places)): ?>
                                                <div class="space-y-2">
                                                    <?php foreach ($places as $p): ?>
                                                        <div class="bg-white p-2.5 rounded border border-slate-200">
                                                            <div class="flex items-center justify-between">
                                                                <span class="font-bold text-slate-900 text-xs"><?= esc($p['name'] ?? '-') ?></span>
                                                                <span class="px-1.5 py-0.5 rounded font-mono font-bold text-[10px] bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                                    <?= esc($p['distance_km'] ?? '0.0') ?> km
                                                                </span>
                                                            </div>
                                                            <div class="text-[11px] text-slate-500 mt-1 line-clamp-1"><?= esc($p['address'] ?? '-') ?></div>
                                                            <div class="flex items-center gap-2 mt-1.5 text-[10px]">
                                                                <span class="text-amber-600 font-bold flex items-center gap-0.5">
                                                                    ★ <?= esc($p['rating'] ?? '4.5') ?>
                                                                </span>
                                                                <?php if (!empty($p['voucher']) && ($p['voucher']['has_voucher'] ?? false)): ?>
                                                                    <span class="px-1.5 py-0.2 rounded bg-red-100 text-red-700 font-bold">
                                                                        🎟️ Voucher: <?= esc($p['voucher']['voucher_code'] ?? '') ?>
                                                                    </span>
                                                                <?php endif; ?>
                                                            </div>
                                                        </div>
                                                    <?php endforeach; ?>
                                                </div>
                                            <?php else: ?>
                                                <div class="text-xs text-slate-400 italic">Tidak ada tempat makan terdekat.</div>
                                            <?php endif; ?>
                                        </div>
                                    </div>

                                    <!-- Sponsored Merchant (if any) -->
                                    <?php if (!empty($sponsor)): ?>
                                        <div class="bg-red-50/60 border border-red-200 rounded-lg p-3 text-xs">
                                            <div class="flex items-center justify-between mb-1">
                                                <span class="font-bold text-red-800 flex items-center gap-1.5">
                                                    <span class="material-symbols-outlined text-[16px] text-red-600">workspace_premium</span>
                                                    Mitra Sponsor &amp; Promo Aktif
                                                </span>
                                                <span class="font-mono font-bold text-[10px] bg-red-600 text-white px-2 py-0.5 rounded">
                                                    Diskon <?= esc($sponsor['discount_percentage'] ?? '0') ?>%
                                                </span>
                                            </div>
                                            <div class="font-semibold text-slate-900"><?= esc($sponsor['name'] ?? '-') ?> &bull; <?= esc($sponsor['promo_title'] ?? '') ?></div>
                                            <div class="text-slate-600 text-[11px] mt-0.5">Kode: <code class="font-bold text-red-700 bg-white px-1.5 py-0.5 rounded border border-red-200"><?= esc($sponsor['voucher_code'] ?? '-') ?></code> (Jarak: <?= esc($sponsor['distance_km'] ?? '0.0') ?> km)</div>
                                        </div>
                                    <?php endif; ?>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
                <tr id="emptySearchLogRow" class="hidden">
                    <td colspan="6" class="py-12 text-center text-slate-400">
                        <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">search_off</span>
                        Tidak ada log percakapan yang cocok dengan kata kunci pencarian.
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- Pagination Footer -->
    <div id="logPaginationBar" class="p-3.5 bg-slate-50/70 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2 text-slate-600">
            <span>Tampilkan</span>
            <select id="logPageSizeSelect" class="py-1 px-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold focus:ring-1 focus:ring-red-500">
                <option value="10" selected>10</option>
                <option value="25">25</option>
                <option value="50">50</option>
            </select>
            <span>per halaman</span>
            <span class="text-slate-300">|</span>
            <span id="logPageInfoText" class="font-mono text-slate-500">Menampilkan 0 - 0 dari 0 data</span>
        </div>

        <div class="flex items-center gap-1" id="logPaginationButtons">
            <!-- Dynamically generated page buttons -->
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const searchInput = document.getElementById('logSearchInput');
    const clearBtn = document.getElementById('clearLogSearchBtn');
    const logRows = Array.from(document.querySelectorAll('.log-row'));
    const emptySearchRow = document.getElementById('emptySearchLogRow');
    const pageSizeSelect = document.getElementById('logPageSizeSelect');
    const pageInfoText = document.getElementById('logPageInfoText');
    const paginationButtons = document.getElementById('logPaginationButtons');

    let currentPage = 1;
    let pageSize = parseInt(pageSizeSelect ? pageSizeSelect.value : 10);
    let filteredRows = [...logRows];

    window.toggleDetail = function(id) {
        const el = document.getElementById(id);
        if (!el) return;
        el.classList.toggle('hidden');
    };

    function renderPagination() {
        const total = filteredRows.length;
        const totalPages = Math.max(1, Math.ceil(total / pageSize));
        if (currentPage > totalPages) currentPage = totalPages;

        const startIdx = (currentPage - 1) * pageSize;
        const endIdx = Math.min(startIdx + pageSize, total);

        // Hide all rows and their open details first
        logRows.forEach(r => {
            r.classList.add('hidden');
            const idx = r.getAttribute('data-index');
            const detailRow = document.querySelector(`.log-detail-row[data-detail-for="${idx}"]`);
            if (detailRow) detailRow.classList.add('hidden');
        });

        // Show only rows in current slice
        filteredRows.slice(startIdx, endIdx).forEach(r => r.classList.remove('hidden'));

        if (total === 0) {
            pageInfoText.textContent = 'Menampilkan 0 data';
            if (emptySearchRow) emptySearchRow.classList.remove('hidden');
        } else {
            pageInfoText.textContent = `Menampilkan ${startIdx + 1} - ${endIdx} dari ${total} log percakapan`;
            if (emptySearchRow) emptySearchRow.classList.add('hidden');
        }

        // Render page buttons
        paginationButtons.innerHTML = '';
        if (totalPages <= 1) return;

        // Prev Button
        const prevBtn = document.createElement('button');
        prevBtn.type = 'button';
        prevBtn.className = `px-2 py-1 rounded-lg border text-xs font-semibold ${currentPage === 1 ? 'text-slate-300 border-slate-200 cursor-not-allowed' : 'text-slate-600 border-slate-200 hover:bg-slate-100'}`;
        prevBtn.innerHTML = '&lsaquo; Prev';
        prevBtn.disabled = currentPage === 1;
        prevBtn.onclick = () => { if (currentPage > 1) { currentPage--; renderPagination(); } };
        paginationButtons.appendChild(prevBtn);

        // Page Number Buttons
        for (let p = 1; p <= totalPages; p++) {
            const pageBtn = document.createElement('button');
            pageBtn.type = 'button';
            const isActive = p === currentPage;
            pageBtn.className = `w-7 h-7 rounded-lg border text-xs font-bold transition-colors ${isActive ? 'bg-red-600 text-white border-red-600' : 'text-slate-600 border-slate-200 hover:bg-slate-100'}`;
            pageBtn.textContent = p;
            pageBtn.onclick = () => { currentPage = p; renderPagination(); };
            paginationButtons.appendChild(pageBtn);
        }

        // Next Button
        const nextBtn = document.createElement('button');
        nextBtn.type = 'button';
        nextBtn.className = `px-2 py-1 rounded-lg border text-xs font-semibold ${currentPage === totalPages ? 'text-slate-300 border-slate-200 cursor-not-allowed' : 'text-slate-600 border-slate-200 hover:bg-slate-100'}`;
        nextBtn.innerHTML = 'Next &rsaquo;';
        nextBtn.disabled = currentPage === totalPages;
        nextBtn.onclick = () => { if (currentPage < totalPages) { currentPage++; renderPagination(); } };
        paginationButtons.appendChild(nextBtn);
    }

    if (pageSizeSelect) {
        pageSizeSelect.addEventListener('change', (e) => {
            pageSize = parseInt(e.target.value);
            currentPage = 1;
            renderPagination();
        });
    }

    function applySearch() {
        const query = (searchInput.value || '').trim().toLowerCase();

        if (query.length > 0) {
            clearBtn.classList.remove('hidden');
        } else {
            clearBtn.classList.add('hidden');
        }

        filteredRows = logRows.filter(row => {
            const searchData = row.getAttribute('data-search') || '';
            return !query || searchData.includes(query);
        });

        currentPage = 1;
        renderPagination();
    }

    if (searchInput) searchInput.addEventListener('input', applySearch);

    if (clearBtn) {
        clearBtn.addEventListener('click', () => {
            searchInput.value = '';
            applySearch();
            searchInput.focus();
        });
    }

    // Initial render
    renderPagination();
});
</script>

<?= $this->endSection() ?>
