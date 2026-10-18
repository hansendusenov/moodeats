<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header & Add Button -->
<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span><?= esc(lang('Admin.brand_name')) ?></span>
            <span>/</span>
            <span><?= esc(lang('Admin.nav_merchants')) ?></span>
            <span>/</span>
            <span class="text-red-600 font-bold"><?= esc(lang('Admin.merchants_badge')) ?></span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2">
            <?= esc(lang('Admin.merchants_title')) ?>
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-red-50 text-red-700 border border-red-200">
                <?= esc(lang('Admin.merchants_badge')) ?>
            </span>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            <?= esc(lang('Admin.merchants_desc')) ?>
        </p>
    </div>
    <div class="flex items-center gap-2">
        <a href="<?= site_url('merchants/create') ?>" class="px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1.5 transition-all shadow-sm">
            <span class="material-symbols-outlined text-[16px]">add_business</span>
            <?= esc(lang('Admin.merchants_btn_create')) ?>
        </a>
    </div>
</div>

<!-- Toolbar: Search & Bulk Action Bar -->
<div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs mb-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
        <!-- Search Input -->
        <div class="relative flex-1 min-w-[260px] max-w-md">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-slate-400">search</span>
            <input type="text" id="merchantSearchInput" value="<?= esc($search ?? '') ?>" 
                   placeholder="<?= esc(lang('Admin.merchants_search_placeholder')) ?>" 
                   class="w-full pl-9 pr-8 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
            <button id="clearSearchBtn" class="hidden absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <span class="material-symbols-outlined text-[16px]">cancel</span>
            </button>
        </div>

        <!-- Filter Status Buttons -->
        <div class="flex items-center gap-1.5 text-xs">
            <button type="button" onclick="filterStatus('all')" id="filterBtnAll" class="px-2.5 py-1.5 rounded-lg font-semibold text-red-600 bg-red-50 border border-red-200 transition-colors">
                <?= esc(lang('Admin.filter_all')) ?> (<span id="countAll"><?= count($merchants) ?></span>)
            </button>
            <button type="button" onclick="filterStatus('active')" id="filterBtnActive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                <?= esc(lang('Admin.filter_active')) ?> (<span id="countActive"><?= count(array_filter($merchants, fn($m) => !empty($m['is_active']) && $m['is_active'] !== 'f' && $m['is_active'] !== false)) ?></span>)
            </button>
            <button type="button" onclick="filterStatus('inactive')" id="filterBtnInactive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                <?= esc(lang('Admin.filter_inactive')) ?> (<span id="countInactive"><?= count(array_filter($merchants, fn($m) => empty($m['is_active']) || $m['is_active'] === 'f' || $m['is_active'] === false)) ?></span>)
            </button>
        </div>
    </div>

    <!-- Bulk Actions Floating Bar (Toggled when 1+ checkboxes selected) -->
    <form id="bulkActionForm" action="<?= site_url('merchants/bulk') ?>" method="post" class="mt-3 pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3">
        <?= csrf_field() ?>
        <input type="hidden" name="action" id="bulkActionType" value="">
        
        <div class="flex items-center gap-2">
            <label class="inline-flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-700">
                <input type="checkbox" id="checkAllMaster" class="w-4 h-4 rounded text-red-600 border-slate-300 focus:ring-red-500">
                <span><?= esc(lang('Admin.select_all')) ?></span>
            </label>
            <span id="selectedCountBadge" class="hidden text-xs font-mono font-bold px-2 py-0.5 rounded-full bg-red-100 text-red-700">
                0 <?= esc(lang('Admin.selected_count')) ?>
            </span>
        </div>

        <div id="bulkButtonsContainer" class="hidden flex items-center gap-2">
            <button type="button" onclick="submitBulkAction('disable')" class="px-2.5 py-1.5 rounded-lg bg-amber-50 hover:bg-amber-100 border border-amber-200 text-amber-800 text-xs font-bold flex items-center gap-1 transition-colors">
                <span class="material-symbols-outlined text-[16px]">block</span>
                <?= esc(lang('Admin.merchants_bulk_disable')) ?>
            </button>
            <button type="button" onclick="submitBulkAction('enable')" class="px-2.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 text-emerald-800 text-xs font-bold flex items-center gap-1 transition-colors">
                <span class="material-symbols-outlined text-[16px]">check_circle</span>
                <?= esc(lang('Admin.merchants_bulk_enable')) ?>
            </button>
            <button type="button" onclick="submitBulkAction('delete')" class="px-2.5 py-1.5 rounded-lg bg-red-50 hover:bg-red-100 border border-red-200 text-red-700 text-xs font-bold flex items-center gap-1 transition-colors">
                <span class="material-symbols-outlined text-[16px]">delete</span>
                <?= esc(lang('Admin.merchants_bulk_delete')) ?>
            </button>
        </div>
    </form>
</div>

<!-- Table Card -->
<div class="bg-white rounded-xl border border-red-100 shadow-xs overflow-hidden">
    <table class="w-full text-left text-xs table-fixed">
        <colgroup>
            <col style="width: 44px;">
            <col style="width: 28%;">
            <col style="width: 14%;">
            <col style="width: 28%;">
            <col style="width: 13%;">
            <col style="width: 13%;">
        </colgroup>
        <thead>
            <tr class="border-b border-slate-100 bg-slate-50/80 text-slate-500 font-mono uppercase text-[10px]">
                <th class="py-3 px-3 text-center">
                    <input type="checkbox" id="checkAllHead" class="w-4 h-4 rounded text-red-600 border-slate-300 focus:ring-red-500 cursor-pointer" title="<?= esc(lang('Admin.select_all')) ?>">
                </th>
                <th class="py-3 px-3"><?= esc(lang('Admin.merchants_col_merchant')) ?></th>
                <th class="py-3 px-3"><?= esc(lang('Admin.merchants_col_timer')) ?></th>
                <th class="py-3 px-3"><?= esc(lang('Admin.merchants_col_voucher')) ?></th>
                <th class="py-3 px-3 text-center"><?= esc(lang('Admin.merchants_col_status')) ?></th>
                <th class="py-3 px-3 text-right"><?= esc(lang('Admin.merchants_col_action')) ?></th>
            </tr>
        </thead>
        <tbody class="divide-y divide-slate-100" id="merchantTableBody">
            <?php if (empty($merchants)): ?>
                <tr id="emptyRowInitial">
                    <td colspan="6" class="py-12 text-center text-slate-400">
                        <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">storefront</span>
                        <?= esc(lang('Admin.merchants_empty')) ?>
                    </td>
                </tr>
            <?php else: ?>
                <?php foreach ($merchants as $m): ?>
                    <?php $isActive = (!empty($m['is_active']) && $m['is_active'] !== 'f' && $m['is_active'] !== false); ?>
                    <tr class="merchant-row hover:bg-slate-50/70 transition-colors"
                        data-id="<?= esc($m['id']) ?>"
                        data-active="<?= $isActive ? '1' : '0' ?>"
                        data-name="<?= esc(strtolower($m['merchant_name'])) ?>"
                        data-category="<?= esc(strtolower($m['category'])) ?>"
                        data-voucher="<?= esc(strtolower($m['voucher_code'])) ?>"
                        data-desc="<?= esc(strtolower($m['discount_description'])) ?>"
                        data-address="<?= esc(strtolower($m['address'])) ?>">
                        
                        <!-- Checkbox -->
                        <td class="py-3 px-3 text-center align-middle">
                            <input type="checkbox" name="ids[]" form="bulkActionForm" value="<?= esc($m['id']) ?>" 
                                   class="row-checkbox w-4 h-4 rounded text-red-600 border-slate-300 focus:ring-red-500 cursor-pointer">
                        </td>

                        <!-- Mitra & Lokasi -->
                        <td class="py-3 px-3 align-middle">
                            <div class="truncate">
                                <div class="flex items-center gap-1.5 truncate">
                                    <span class="font-bold text-slate-900 truncate" title="<?= esc($m['merchant_name']) ?>">
                                        <?= esc($m['merchant_name']) ?>
                                    </span>
                                </div>
                                <div class="flex items-center gap-1 text-[11px] text-slate-500 mt-0.5 truncate" title="<?= esc($m['address']) ?>">
                                    <span class="material-symbols-outlined text-[13px] text-slate-400 shrink-0">location_on</span>
                                    <span class="truncate"><?= esc($m['address']) ?></span>
                                </div>
                            </div>
                        </td>

                        <!-- Kategori & Timer -->
                        <td class="py-3 px-3 align-middle">
                            <div class="space-y-1">
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold bg-slate-100 text-slate-700 truncate max-w-full" title="<?= esc($m['category']) ?>">
                                    <?= esc($m['category']) ?>
                                </span>
                                <div class="text-[10px] font-mono font-bold text-amber-700 flex items-center gap-1">
                                    <span class="material-symbols-outlined text-[13px] text-amber-600">timer</span>
                                    <?= (int) ($m['countdown_minutes'] ?? 15) ?> min
                                </div>
                            </div>
                        </td>

                        <!-- Kode & Promo Voucher -->
                        <td class="py-3 px-3 align-middle">
                            <div>
                                <div class="flex items-center gap-1.5 flex-wrap">
                                    <span class="px-2 py-0.5 rounded font-mono font-bold text-red-700 bg-red-50 border border-red-200 text-[11px]">
                                        <?= esc($m['voucher_code']) ?>
                                    </span>
                                    <?php if (!empty($m['promo_badge'])): ?>
                                        <span class="px-1.5 py-0.2 rounded text-[9px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                            <?= esc($m['promo_badge']) ?>
                                        </span>
                                    <?php endif; ?>
                                </div>
                                <div class="text-[11px] text-slate-600 mt-1 truncate" title="<?= esc($m['discount_description']) ?>">
                                    <?= esc($m['discount_description']) ?>
                                </div>
                            </div>
                        </td>

                        <!-- Status Toggle Button -->
                        <td class="py-3 px-3 text-center align-middle whitespace-nowrap">
                            <a href="<?= site_url('merchants/toggle/' . $m['id']) ?>" 
                               class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold font-mono transition-all <?= $isActive ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100' : 'bg-slate-100 text-slate-500 border border-slate-200 hover:bg-slate-200' ?>"
                               title="<?= esc(lang('Admin.status')) ?>">
                                <span class="w-1.5 h-1.5 rounded-full <?= $isActive ? 'bg-emerald-500' : 'bg-slate-400' ?>"></span>
                                <?= $isActive ? esc(strtoupper(lang('Admin.active'))) : esc(strtoupper(lang('Admin.inactive'))) ?>
                            </a>
                        </td>

                        <!-- Aksi -->
                        <td class="py-3 px-3 text-right align-middle whitespace-nowrap">
                            <div class="inline-flex items-center gap-1">
                                <a href="<?= site_url('merchants/edit/' . $m['id']) ?>" 
                                   class="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-colors shadow-2xs" 
                                   title="<?= esc(lang('Admin.edit')) ?>">
                                    <span class="material-symbols-outlined text-[16px]">edit</span>
                                </a>
                                <a href="<?= site_url('merchants/delete/' . $m['id']) ?>" 
                                   data-confirm="<?= esc(lang('Admin.confirm_delete_msg')) ?>"
                                   data-confirm-title="<?= esc(lang('Admin.confirm_delete_title')) ?>"
                                   data-confirm-btn="<?= esc(lang('Admin.confirm_delete_btn')) ?>"
                                   data-confirm-type="danger"
                                   class="p-1.5 rounded-lg border border-red-100 bg-white hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors shadow-2xs cursor-pointer" 
                                   title="<?= esc(lang('Admin.delete')) ?>">
                                    <span class="material-symbols-outlined text-[16px]">delete</span>
                                </a>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                <tr id="emptySearchRow" class="hidden">
                    <td colspan="6" class="py-12 text-center text-slate-400">
                        <span class="material-symbols-outlined text-4xl text-slate-300 block mb-2">search_off</span>
                        <?= esc(lang('Admin.no_data')) ?>
                    </td>
                </tr>
            <?php endif; ?>
        </tbody>
    </table>

    <!-- Pagination Footer -->
    <div id="paginationBar" class="p-3.5 bg-slate-50/70 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2 text-slate-600">
            <span>Show</span>
            <select id="pageSizeSelect" class="py-1 px-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold focus:ring-1 focus:ring-red-500">
                <option value="5" selected>5</option>
                <option value="10">10</option>
                <option value="25">25</option>
            </select>
            <span>/ page</span>
            <span class="text-slate-300">|</span>
            <span id="pageInfoText" class="font-mono text-slate-500">Loading...</span>
        </div>

        <div class="flex items-center gap-1" id="paginationButtons">
            <!-- Dynamically generated page buttons -->
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const searchInput = document.getElementById('merchantSearchInput');
    const clearBtn = document.getElementById('clearSearchBtn');
    const checkAllMaster = document.getElementById('checkAllMaster');
    const checkAllHead = document.getElementById('checkAllHead');
    const rowCheckboxes = document.querySelectorAll('.row-checkbox');
    const selectedCountBadge = document.getElementById('selectedCountBadge');
    const bulkButtonsContainer = document.getElementById('bulkButtonsContainer');
    const merchantRows = Array.from(document.querySelectorAll('.merchant-row'));
    const emptySearchRow = document.getElementById('emptySearchRow');
    const pageSizeSelect = document.getElementById('pageSizeSelect');
    const pageInfoText = document.getElementById('pageInfoText');
    const paginationButtons = document.getElementById('paginationButtons');

    let currentFilter = 'all';
    let currentPage = 1;
    let pageSize = parseInt(pageSizeSelect ? pageSizeSelect.value : 5);
    let filteredRows = [...merchantRows];

    const isIndo = <?= json_encode(service('request')->getLocale() === 'id') ?>;

    // Master checkboxes syncing
    function updateMasterCheckboxes() {
        const visibleChecked = filteredRows
            .filter(r => !r.classList.contains('hidden'))
            .map(r => r.querySelector('.row-checkbox'))
            .filter(Boolean)
            .filter(cb => cb.checked);

        const visibleTotal = filteredRows
            .filter(r => !r.classList.contains('hidden'))
            .map(r => r.querySelector('.row-checkbox'))
            .filter(Boolean);

        const allChecked = Array.from(document.querySelectorAll('.row-checkbox:checked'));
        const count = allChecked.length;

        const isAll = visibleTotal.length > 0 && visibleChecked.length === visibleTotal.length;
        const isIndeterminate = visibleChecked.length > 0 && visibleChecked.length < visibleTotal.length;

        if (checkAllMaster) {
            checkAllMaster.checked = isAll;
            checkAllMaster.indeterminate = isIndeterminate;
        }
        if (checkAllHead) {
            checkAllHead.checked = isAll;
            checkAllHead.indeterminate = isIndeterminate;
        }

        if (count > 0) {
            selectedCountBadge.textContent = count + (isIndo ? ' dipilih' : ' selected');
            selectedCountBadge.classList.remove('hidden');
            bulkButtonsContainer.classList.remove('hidden');
        } else {
            selectedCountBadge.classList.add('hidden');
            bulkButtonsContainer.classList.add('hidden');
        }
    }

    function toggleVisibleCheckboxes(checked) {
        filteredRows.filter(r => !r.classList.contains('hidden')).forEach(row => {
            const cb = row.querySelector('.row-checkbox');
            if (cb) cb.checked = checked;
        });
        updateMasterCheckboxes();
    }

    if (checkAllMaster) checkAllMaster.addEventListener('change', (e) => toggleVisibleCheckboxes(e.target.checked));
    if (checkAllHead) checkAllHead.addEventListener('change', (e) => toggleVisibleCheckboxes(e.target.checked));

    rowCheckboxes.forEach(cb => {
        cb.addEventListener('change', updateMasterCheckboxes);
    });

    // Pagination Render
    function renderPagination() {
        const total = filteredRows.length;
        const totalPages = Math.max(1, Math.ceil(total / pageSize));
        if (currentPage > totalPages) currentPage = totalPages;

        const startIdx = (currentPage - 1) * pageSize;
        const endIdx = Math.min(startIdx + pageSize, total);

        merchantRows.forEach(r => r.classList.add('hidden'));
        filteredRows.slice(startIdx, endIdx).forEach(r => r.classList.remove('hidden'));

        if (total === 0) {
            pageInfoText.textContent = isIndo ? 'Menampilkan 0 data' : 'Showing 0 entries';
            if (emptySearchRow) emptySearchRow.classList.remove('hidden');
        } else {
            pageInfoText.textContent = isIndo 
                ? `Menampilkan ${startIdx + 1} - ${endIdx} dari ${total} mitra`
                : `Showing ${startIdx + 1} - ${endIdx} of ${total} partners`;
            if (emptySearchRow) emptySearchRow.classList.add('hidden');
        }

        paginationButtons.innerHTML = '';
        if (totalPages <= 1) {
            updateMasterCheckboxes();
            return;
        }

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

        updateMasterCheckboxes();
    }

    if (pageSizeSelect) {
        pageSizeSelect.addEventListener('change', (e) => {
            pageSize = parseInt(e.target.value);
            currentPage = 1;
            renderPagination();
        });
    }

    // Filter + Search Logic
    function applyFilters() {
        const query = (searchInput.value || '').trim().toLowerCase();

        if (query.length > 0) {
            clearBtn.classList.remove('hidden');
        } else {
            clearBtn.classList.add('hidden');
        }

        filteredRows = merchantRows.filter(row => {
            const name = row.getAttribute('data-name') || '';
            const cat = row.getAttribute('data-category') || '';
            const voucher = row.getAttribute('data-voucher') || '';
            const desc = row.getAttribute('data-desc') || '';
            const address = row.getAttribute('data-address') || '';
            const isActive = row.getAttribute('data-active') === '1';

            const matchesText = !query || name.includes(query) || cat.includes(query) || voucher.includes(query) || desc.includes(query) || address.includes(query);
            
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

    window.filterStatus = function(status) {
        currentFilter = status;
        const btnAll = document.getElementById('filterBtnAll');
        const btnActive = document.getElementById('filterBtnActive');
        const btnInactive = document.getElementById('filterBtnInactive');

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

    // Bulk Action via Global Modal
    window.submitBulkAction = function(actionType) {
        const checkedCheckboxes = document.querySelectorAll('.row-checkbox:checked');
        if (checkedCheckboxes.length === 0) {
            window.showConfirmDialog({
                title: isIndo ? 'Perhatian' : 'Attention',
                message: isIndo ? 'Silakan pilih minimal satu mitra restoran terlebih dahulu.' : 'Please select at least one restaurant partner first.',
                confirmText: 'OK',
                type: 'warning'
            });
            return;
        }

        let title = isIndo ? 'Konfirmasi Aksi Massal' : 'Bulk Action Confirmation';
        let confirmMsg = '';
        let btnText = isIndo ? 'Lanjutkan' : 'Continue';
        let modalType = 'danger';

        if (actionType === 'disable') {
            title = isIndo ? 'Nonaktifkan Mitra Terpilih' : 'Disable Selected Partners';
            confirmMsg = isIndo 
                ? `Apakah Anda yakin ingin menonaktifkan ${checkedCheckboxes.length} mitra yang dipilih?` 
                : `Are you sure you want to disable ${checkedCheckboxes.length} selected partners?`;
            btnText = isIndo ? 'Nonaktifkan' : 'Disable';
            modalType = 'warning';
        } else if (actionType === 'enable') {
            title = isIndo ? 'Aktifkan Mitra Terpilih' : 'Enable Selected Partners';
            confirmMsg = isIndo 
                ? `Apakah Anda yakin ingin mengaktifkan ${checkedCheckboxes.length} mitra yang dipilih?` 
                : `Are you sure you want to enable ${checkedCheckboxes.length} selected partners?`;
            btnText = isIndo ? 'Aktifkan' : 'Enable';
            modalType = 'success';
        } else if (actionType === 'delete') {
            title = isIndo ? 'Hapus Mitra Terpilih' : 'Delete Selected Partners';
            confirmMsg = isIndo 
                ? `Peringatan: Tindakan ini permanen. Apakah Anda yakin ingin MENGHAPUS ${checkedCheckboxes.length} mitra restoran terpilih?` 
                : `Warning: This action is permanent. Are you sure you want to DELETE ${checkedCheckboxes.length} selected partners?`;
            btnText = isIndo ? 'Hapus Permanen' : 'Delete Permanently';
            modalType = 'danger';
        }

        window.showConfirmDialog({
            title: title,
            message: confirmMsg,
            confirmText: btnText,
            type: modalType,
            onConfirm: function() {
                document.getElementById('bulkActionType').value = actionType;
                document.getElementById('bulkActionForm').submit();
            }
        });
    };

    // Initial render
    renderPagination();
});
</script>

<?= $this->endSection() ?>
