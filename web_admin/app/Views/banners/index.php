<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span>Admin Console</span>
            <span>/</span>
            <span>Promosi &amp; Ads</span>
            <span>/</span>
            <span class="text-red-600 font-bold">Banner Iklan</span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2">
            Banner &amp; Time-Parting Ads Management
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-purple-50 text-purple-700 border border-purple-200">
                Geofenced &amp; Scheduled
            </span>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            Iklan banner dengan kemampuan geofencing (radius/kota) dan penjadwalan jam aktif (time-parting).
        </p>
    </div>
    <div class="flex items-center gap-2">
        <a href="/banners/create" class="px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1.5 transition-all shadow-sm">
            <span class="material-symbols-outlined text-[16px]">campaign</span>
            Buat Kampanye Banner
        </a>
    </div>
</div>

<!-- Toolbar: Search & Filter -->
<div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs mb-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
        <!-- Search Input -->
        <div class="relative flex-1 min-w-[260px] max-w-md">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-slate-400">search</span>
            <input type="text" id="bannerSearchInput" 
                   placeholder="Cari judul iklan, kota target, atau jam tayang..." 
                   class="w-full pl-9 pr-8 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
            <button id="clearBannerSearchBtn" class="hidden absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <span class="material-symbols-outlined text-[16px]">cancel</span>
            </button>
        </div>

        <!-- Filter Status Buttons -->
        <div class="flex items-center gap-1.5 text-xs">
            <button type="button" onclick="filterBannerStatus('all')" id="bannerFilterBtnAll" class="px-2.5 py-1.5 rounded-lg font-semibold text-red-600 bg-red-50 border border-red-200 transition-colors">
                Semua (<span id="bannerCountAll"><?= count($banners) ?></span>)
            </button>
            <button type="button" onclick="filterBannerStatus('active')" id="bannerFilterBtnActive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Aktif (<span id="bannerCountActive"><?= count(array_filter($banners, fn($b) => $b['is_active'])) ?></span>)
            </button>
            <button type="button" onclick="filterBannerStatus('inactive')" id="bannerFilterBtnInactive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Nonaktif (<span id="bannerCountInactive"><?= count(array_filter($banners, fn($b) => !$b['is_active'])) ?></span>)
            </button>
        </div>
    </div>
</div>

<div class="bg-white rounded-xl border border-red-100 shadow-xs overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/70 text-slate-500 font-mono uppercase text-[10px]">
                    <th class="py-3 px-4">Banner &amp; Judul</th>
                    <th class="py-3 px-4">Targeting</th>
                    <th class="py-3 px-4">Time-Parting (Jam)</th>
                    <th class="py-3 px-4">Periode Tayang</th>
                    <th class="py-3 px-4 text-center">Prioritas</th>
                    <th class="py-3 px-4 text-center">Status</th>
                    <th class="py-3 px-4 text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100" id="bannerTableBody">
                <?php if (empty($banners)): ?>
                    <tr id="emptyBannerInitial">
                        <td colspan="7" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">ad_off</span>
                            Belum ada kampanye banner aktif. Klik "Buat Kampanye Banner" untuk memulai promosi bersponsor.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($banners as $b): ?>
                        <tr class="banner-row hover:bg-slate-50/60 transition-colors"
                            data-active="<?= $b['is_active'] ? '1' : '0' ?>"
                            data-title="<?= esc(strtolower($b['title'])) ?>"
                            data-target="<?= esc(strtolower($b['targeting_type'] . ' ' . ($b['target_city'] ?? ''))) ?>"
                            data-hours="<?= esc(strtolower(($b['start_hour'] ?? '') . ' ' . ($b['end_hour'] ?? ''))) ?>">
                            <td class="py-3 px-4">
                                <div class="flex items-center gap-3">
                                    <img src="<?= esc($b['image_url']) ?>" alt="<?= esc($b['title']) ?>"
                                         class="w-16 h-10 rounded-md object-cover border border-slate-200 bg-slate-100 flex-shrink-0"
                                         onerror="this.src='https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200'"/>
                                    <div>
                                        <span class="font-bold text-slate-900 block"><?= esc($b['title']) ?></span>
                                        <?php if (!empty($b['target_url'])): ?>
                                            <a href="<?= esc($b['target_url']) ?>" target="_blank" class="text-[10px] text-blue-600 hover:underline flex items-center gap-0.5">
                                                Link Target <span class="material-symbols-outlined text-[10px]">open_in_new</span>
                                            </a>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </td>
                            <td class="py-3 px-4 whitespace-nowrap">
                                <?php if ($b['targeting_type'] === 'radius'): ?>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-purple-50 text-purple-700 border border-purple-200">
                                        Radius <?= $b['radius_km'] ?> km
                                    </span>
                                <?php elseif ($b['targeting_type'] === 'city'): ?>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-blue-50 text-blue-700 border border-blue-200">
                                        Kota: <?= esc($b['target_city']) ?>
                                    </span>
                                <?php else: ?>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold font-mono bg-slate-100 text-slate-700 border border-slate-200">
                                        Global
                                    </span>
                                <?php endif; ?>
                            </td>
                            <td class="py-3 px-4 font-mono text-[11px] text-slate-600 whitespace-nowrap">
                                <?= ($b['start_hour'] && $b['end_hour']) ? substr($b['start_hour'], 0, 5) . ' - ' . substr($b['end_hour'], 0, 5) : '24 Jam Penuh' ?>
                            </td>
                            <td class="py-3 px-4 text-slate-600 whitespace-nowrap">
                                <div class="text-[11px] font-mono">
                                    <span><?= date('d M Y', strtotime($b['start_date'])) ?></span> s/d
                                    <span><?= date('d M Y', strtotime($b['end_date'])) ?></span>
                                </div>
                            </td>
                            <td class="py-3 px-4 text-center font-mono font-bold text-slate-700">
                                <?= $b['priority'] ?>
                            </td>
                            <td class="py-3 px-4 text-center whitespace-nowrap">
                                <a href="/banners/toggle/<?= $b['id'] ?>" class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold font-mono transition-colors <?= $b['is_active'] ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100' : 'bg-slate-100 text-slate-500 border border-slate-200 hover:bg-slate-200' ?>">
                                    <span class="w-1.5 h-1.5 rounded-full <?= $b['is_active'] ? 'bg-emerald-500' : 'bg-slate-400' ?>"></span>
                                    <?= $b['is_active'] ? 'AKTIF' : 'NONAKTIF' ?>
                                </a>
                            </td>
                            <td class="py-3 px-4 text-right whitespace-nowrap">
                                <div class="inline-flex items-center gap-1">
                                    <a href="/banners/edit/<?= $b['id'] ?>" class="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-colors shadow-2xs" title="Edit">
                                        <span class="material-symbols-outlined text-[16px]">edit</span>
                                    </a>
                                    <a href="/banners/delete/<?= $b['id'] ?>" 
                                       data-confirm="Apakah Anda yakin ingin menghapus kampanye banner '<?= esc($b['title']) ?>'?" 
                                       data-confirm-title="Hapus Banner Iklan" 
                                       data-confirm-btn="Hapus Banner" 
                                       data-confirm-type="danger" 
                                       class="p-1.5 rounded-lg border border-red-100 bg-white hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors shadow-2xs cursor-pointer" 
                                       title="Hapus">
                                        <span class="material-symbols-outlined text-[16px]">delete</span>
                                    </a>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <tr id="emptySearchBannerRow" class="hidden">
                        <td colspan="7" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">search_off</span>
                            Tidak ada kampanye banner yang cocok dengan pencarian Anda.
                        </td>
                    </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Pagination Footer -->
    <div id="bannerPaginationBar" class="p-3.5 bg-slate-50/70 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2 text-slate-600">
            <span>Tampilkan</span>
            <select id="bannerPageSizeSelect" class="py-1 px-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold focus:ring-1 focus:ring-red-500">
                <option value="5" selected>5</option>
                <option value="10">10</option>
                <option value="25">25</option>
            </select>
            <span>per halaman</span>
            <span class="text-slate-300">|</span>
            <span id="bannerPageInfoText" class="font-mono text-slate-500">Menampilkan 0 - 0 dari 0 data</span>
        </div>

        <div class="flex items-center gap-1" id="bannerPaginationButtons">
            <!-- Dynamically generated page buttons -->
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('bannerSearchInput');
    const clearBtn = document.getElementById('clearBannerSearchBtn');
    const bannerRows = Array.from(document.querySelectorAll('.banner-row'));
    const emptyRow = document.getElementById('emptySearchBannerRow');
    const pageSizeSelect = document.getElementById('bannerPageSizeSelect');
    const pageInfoText = document.getElementById('bannerPageInfoText');
    const paginationButtons = document.getElementById('bannerPaginationButtons');

    let currentFilter = 'all';
    let currentPage = 1;
    let pageSize = parseInt(pageSizeSelect ? pageSizeSelect.value : 5);
    let filteredRows = [...bannerRows];

    function renderPagination() {
        const total = filteredRows.length;
        const totalPages = Math.max(1, Math.ceil(total / pageSize));
        if (currentPage > totalPages) currentPage = totalPages;

        const startIdx = (currentPage - 1) * pageSize;
        const endIdx = Math.min(startIdx + pageSize, total);

        bannerRows.forEach(r => r.classList.add('hidden'));
        filteredRows.slice(startIdx, endIdx).forEach(r => r.classList.remove('hidden'));

        if (total === 0) {
            pageInfoText.textContent = 'Menampilkan 0 data';
            if (emptyRow) emptyRow.classList.remove('hidden');
        } else {
            pageInfoText.textContent = `Menampilkan ${startIdx + 1} - ${endIdx} dari ${total} banner`;
            if (emptyRow) emptyRow.classList.add('hidden');
        }

        paginationButtons.innerHTML = '';
        if (totalPages <= 1) return;

        const prevBtn = document.createElement('button');
        prevBtn.type = 'button';
        prevBtn.className = `px-2 py-1 rounded-lg border text-xs font-semibold ${currentPage === 1 ? 'text-slate-300 border-slate-200 cursor-not-allowed' : 'text-slate-600 border-slate-200 hover:bg-slate-100'}`;
        prevBtn.innerHTML = '&lsaquo; Prev';
        prevBtn.disabled = currentPage === 1;
        prevBtn.onclick = () => { if (currentPage > 1) { currentPage--; renderPagination(); } };
        paginationButtons.appendChild(prevBtn);

        for (let p = 1; p <= totalPages; p++) {
            const pageBtn = document.createElement('button');
            pageBtn.type = 'button';
            const isActive = p === currentPage;
            pageBtn.className = `w-7 h-7 rounded-lg border text-xs font-bold transition-colors ${isActive ? 'bg-red-600 text-white border-red-600' : 'text-slate-600 border-slate-200 hover:bg-slate-100'}`;
            pageBtn.textContent = p;
            pageBtn.onclick = () => { currentPage = p; renderPagination(); };
            paginationButtons.appendChild(pageBtn);
        }

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

    function applyFilters() {
        const query = (searchInput.value || '').trim().toLowerCase();

        if (query.length > 0) {
            clearBtn.classList.remove('hidden');
        } else {
            clearBtn.classList.add('hidden');
        }

        filteredRows = bannerRows.filter(row => {
            const title = row.getAttribute('data-title') || '';
            const target = row.getAttribute('data-target') || '';
            const hours = row.getAttribute('data-hours') || '';
            const isActive = row.getAttribute('data-active') === '1';

            const matchesText = !query || title.includes(query) || target.includes(query) || hours.includes(query);
            
            let matchesStatus = true;
            if (currentFilter === 'active') matchesStatus = isActive;
            else if (currentFilter === 'inactive') matchesStatus = !isActive;

            return matchesText && matchesStatus;
        });

        currentPage = 1;
        renderPagination();
    }

    searchInput.addEventListener('input', applyFilters);

    clearBtn.addEventListener('click', () => {
        searchInput.value = '';
        applyFilters();
        searchInput.focus();
    });

    window.filterBannerStatus = function(status) {
        currentFilter = status;
        const btnAll = document.getElementById('bannerFilterBtnAll');
        const btnActive = document.getElementById('bannerFilterBtnActive');
        const btnInactive = document.getElementById('bannerFilterBtnInactive');

        const activeClass = 'bg-red-50 text-red-600 border-red-200';
        const defaultClass = 'text-slate-600 hover:bg-slate-50 border-slate-200';

        [btnAll, btnActive, btnInactive].forEach(btn => {
            btn.className = 'px-2.5 py-1.5 rounded-lg font-semibold border transition-colors ' + defaultClass;
        });

        if (status === 'all') btnAll.className = 'px-2.5 py-1.5 rounded-lg font-semibold border transition-colors ' + activeClass;
        if (status === 'active') btnActive.className = 'px-2.5 py-1.5 rounded-lg font-semibold border transition-colors ' + activeClass;
        if (status === 'inactive') btnInactive.className = 'px-2.5 py-1.5 rounded-lg font-semibold border transition-colors ' + activeClass;

        applyFilters();
    };

    renderPagination();
});
</script>

<?= $this->endSection() ?>
