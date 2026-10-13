<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span>Admin Console</span>
            <span>/</span>
            <span>Katalog Kuliner</span>
            <span>/</span>
            <span class="text-red-600 font-bold">Menu Kurasi</span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2">
            Default Curated Menus
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-amber-50 text-amber-700 border border-amber-200">
                Fallback Cards
            </span>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            Daftar menu kurasi makanan lokal yang tampil di beranda aplikasi mobile sebelum rekomendasi AI dihasilkan.
        </p>
    </div>
    <div class="flex items-center gap-2">
        <a href="/menus/create" class="px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1.5 transition-all shadow-sm">
            <span class="material-symbols-outlined text-[16px]">add</span>
            Tambah Menu Baru
        </a>
    </div>
</div>

<!-- Toolbar: Search & Filter -->
<div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs mb-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
        <!-- Search Input -->
        <div class="relative flex-1 min-w-[260px] max-w-md">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-slate-400">search</span>
            <input type="text" id="menuSearchInput" 
                   placeholder="Cari nama makanan, kategori, harga, atau deskripsi..." 
                   class="w-full pl-9 pr-8 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
            <button id="clearMenuSearchBtn" class="hidden absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <span class="material-symbols-outlined text-[16px]">cancel</span>
            </button>
        </div>

        <!-- Filter Status Buttons -->
        <div class="flex items-center gap-1.5 text-xs">
            <button type="button" onclick="filterMenuStatus('all')" id="menuFilterBtnAll" class="px-2.5 py-1.5 rounded-lg font-semibold text-red-600 bg-red-50 border border-red-200 transition-colors">
                Semua (<span id="menuCountAll"><?= count($menus) ?></span>)
            </button>
            <button type="button" onclick="filterMenuStatus('active')" id="menuFilterBtnActive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Aktif (<span id="menuCountActive"><?= count(array_filter($menus, fn($m) => $m['is_active'])) ?></span>)
            </button>
            <button type="button" onclick="filterMenuStatus('inactive')" id="menuFilterBtnInactive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Nonaktif (<span id="menuCountInactive"><?= count(array_filter($menus, fn($m) => !$m['is_active'])) ?></span>)
            </button>
        </div>
    </div>
</div>

<div class="bg-white rounded-xl border border-red-100 shadow-xs overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/70 text-slate-500 font-mono uppercase text-[10px]">
                    <th class="py-3 px-4 text-center w-12">No</th>
                    <th class="py-3 px-4">Menu &amp; Gambar</th>
                    <th class="py-3 px-4">Kategori Emosional</th>
                    <th class="py-3 px-4">Estimasi Harga</th>
                    <th class="py-3 px-4">Deskripsi</th>
                    <th class="py-3 px-4 text-center">Status</th>
                    <th class="py-3 px-4 text-right">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100" id="menuTableBody">
                <?php if (empty($menus)): ?>
                    <tr id="emptyMenuInitial">
                        <td colspan="7" class="py-8 text-center text-slate-400">Belum ada menu kurasi.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($menus as $menu): ?>
                        <tr class="menu-row hover:bg-slate-50/60 transition-colors"
                            data-active="<?= $menu['is_active'] ? '1' : '0' ?>"
                            data-name="<?= esc(strtolower($menu['food_name'])) ?>"
                            data-category="<?= esc(strtolower($menu['category'])) ?>"
                            data-price="<?= esc(strtolower($menu['price_est'] ?? '')) ?>"
                            data-desc="<?= esc(strtolower($menu['description'] ?? '')) ?>">
                            <td class="py-3 px-4 font-mono font-bold text-slate-500 text-center w-12">
                                <?= $menu['display_order'] ?>
                            </td>
                            <td class="py-3 px-4">
                                <div class="flex items-center gap-3">
                                    <img src="<?= esc($menu['image_url']) ?>" alt="<?= esc($menu['food_name']) ?>"
                                         class="w-12 h-12 rounded-lg object-cover border border-slate-200 flex-shrink-0 bg-slate-100"
                                         onerror="this.src='https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100'"/>
                                    <div>
                                        <span class="font-bold text-slate-900 block"><?= esc($menu['food_name']) ?></span>
                                        <span class="text-[10px] text-slate-400 font-mono">ID: <?= substr($menu['id'], 0, 8) ?>...</span>
                                    </div>
                                </div>
                            </td>
                            <td class="py-3 px-4 whitespace-nowrap">
                                <span class="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-red-50 text-red-700 border border-red-200">
                                    <?= esc($menu['category']) ?>
                                </span>
                            </td>
                            <td class="py-3 px-4 font-mono font-semibold text-slate-700 whitespace-nowrap">
                                <?= esc($menu['price_est'] ?? '-') ?>
                            </td>
                            <td class="py-3 px-4 text-slate-600 max-w-xs truncate" title="<?= esc($menu['description'] ?? '') ?>">
                                <?= esc($menu['description'] ?? '-') ?>
                            </td>
                            <td class="py-3 px-4 text-center whitespace-nowrap">
                                <a href="/menus/toggle/<?= $menu['id'] ?>" class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold font-mono transition-colors <?= $menu['is_active'] ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100' : 'bg-slate-100 text-slate-500 border border-slate-200 hover:bg-slate-200' ?>" title="Klik untuk ubah status">
                                    <span class="w-1.5 h-1.5 rounded-full <?= $menu['is_active'] ? 'bg-emerald-500' : 'bg-slate-400' ?>"></span>
                                    <?= $menu['is_active'] ? 'AKTIF' : 'NONAKTIF' ?>
                                </a>
                            </td>
                            <td class="py-3 px-4 text-right whitespace-nowrap">
                                <div class="inline-flex items-center gap-1">
                                    <a href="/menus/edit/<?= $menu['id'] ?>" class="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-colors shadow-2xs" title="Edit">
                                        <span class="material-symbols-outlined text-[16px]">edit</span>
                                    </a>
                                    <a href="/menus/delete/<?= $menu['id'] ?>" 
                                       data-confirm="Apakah Anda yakin ingin menghapus menu '<?= esc($menu['food_name']) ?>'?" 
                                       data-confirm-title="Hapus Menu Kurasi" 
                                       data-confirm-btn="Hapus Menu" 
                                       data-confirm-type="danger" 
                                       class="p-1.5 rounded-lg border border-red-100 bg-white hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors shadow-2xs cursor-pointer" 
                                       title="Hapus">
                                        <span class="material-symbols-outlined text-[16px]">delete</span>
                                    </a>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <tr id="emptySearchMenuRow" class="hidden">
                        <td colspan="7" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">search_off</span>
                            Tidak ada menu kurasi yang cocok dengan kata kunci pencarian.
                        </td>
                    </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Pagination Footer -->
    <div id="menuPaginationBar" class="p-3.5 bg-slate-50/70 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2 text-slate-600">
            <span>Tampilkan</span>
            <select id="menuPageSizeSelect" class="py-1 px-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold focus:ring-1 focus:ring-red-500">
                <option value="6">6</option>
                <option value="10" selected>10</option>
                <option value="20">20</option>
            </select>
            <span>per halaman</span>
            <span class="text-slate-300">|</span>
            <span id="menuPageInfoText" class="font-mono text-slate-500">Menampilkan 0 - 0 dari 0 data</span>
        </div>

        <div class="flex items-center gap-1" id="menuPaginationButtons">
            <!-- Dynamically generated page buttons -->
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('menuSearchInput');
    const clearBtn = document.getElementById('clearMenuSearchBtn');
    const menuRows = Array.from(document.querySelectorAll('.menu-row'));
    const emptyRow = document.getElementById('emptySearchMenuRow');
    const pageSizeSelect = document.getElementById('menuPageSizeSelect');
    const pageInfoText = document.getElementById('menuPageInfoText');
    const paginationButtons = document.getElementById('menuPaginationButtons');

    let currentFilter = 'all';
    let currentPage = 1;
    let pageSize = parseInt(pageSizeSelect ? pageSizeSelect.value : 10);
    let filteredRows = [...menuRows];

    function renderPagination() {
        const total = filteredRows.length;
        const totalPages = Math.max(1, Math.ceil(total / pageSize));
        if (currentPage > totalPages) currentPage = totalPages;

        const startIdx = (currentPage - 1) * pageSize;
        const endIdx = Math.min(startIdx + pageSize, total);

        menuRows.forEach(r => r.classList.add('hidden'));
        filteredRows.slice(startIdx, endIdx).forEach(r => r.classList.remove('hidden'));

        if (total === 0) {
            pageInfoText.textContent = 'Menampilkan 0 data';
            if (emptyRow) emptyRow.classList.remove('hidden');
        } else {
            pageInfoText.textContent = `Menampilkan ${startIdx + 1} - ${endIdx} dari ${total} menu`;
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

        filteredRows = menuRows.filter(row => {
            const name = row.getAttribute('data-name') || '';
            const cat = row.getAttribute('data-category') || '';
            const price = row.getAttribute('data-price') || '';
            const desc = row.getAttribute('data-desc') || '';
            const isActive = row.getAttribute('data-active') === '1';

            const matchesText = !query || name.includes(query) || cat.includes(query) || price.includes(query) || desc.includes(query);
            
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

    window.filterMenuStatus = function(status) {
        currentFilter = status;
        const btnAll = document.getElementById('menuFilterBtnAll');
        const btnActive = document.getElementById('menuFilterBtnActive');
        const btnInactive = document.getElementById('menuFilterBtnInactive');

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
