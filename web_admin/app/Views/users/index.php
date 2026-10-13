<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header -->
<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span>Admin Console</span>
            <span>/</span>
            <span>Pelanggan</span>
            <span>/</span>
            <span class="text-red-600 font-bold">Manajemen User &amp; Voucher</span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-2">
            User Management &amp; Voucher Injection
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-red-50 text-red-700 border border-red-200">
                Live Profiles
            </span>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            Pantau akun pengguna, status blokir (banned), dan berikan kupon promo khusus (injeksi voucher) secara instan.
        </p>
    </div>
</div>

<!-- Stats Overview Cards -->
<div class="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-4">
    <div class="bg-white p-3.5 rounded-xl border border-red-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Total Pengguna</div>
            <div class="text-2xl font-black text-slate-900 mt-0.5"><?= $totalUsers ?></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-600">
            <span class="material-symbols-outlined text-[20px]">group</span>
        </div>
    </div>
    <div class="bg-white p-3.5 rounded-xl border border-red-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold text-emerald-600 uppercase tracking-wider">Pengguna Aktif</div>
            <div class="text-2xl font-black text-emerald-600 mt-0.5"><?= $activeCount ?></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-200 flex items-center justify-center text-emerald-600">
            <span class="material-symbols-outlined text-[20px]">check_circle</span>
        </div>
    </div>
    <div class="bg-white p-3.5 rounded-xl border border-red-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold text-red-600 uppercase tracking-wider">Akun Diblokir (Banned)</div>
            <div class="text-2xl font-black text-red-600 mt-0.5"><?= $bannedCount ?></div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-red-50 border border-red-200 flex items-center justify-center text-red-600">
            <span class="material-symbols-outlined text-[20px]">block</span>
        </div>
    </div>
</div>

<!-- Toolbar: Search & Filter -->
<div class="bg-white rounded-xl border border-red-100 p-4 shadow-xs mb-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
        <!-- Search Input -->
        <div class="relative flex-1 min-w-[260px] max-w-md">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-slate-400">search</span>
            <input type="text" id="userSearchInput" value="<?= esc($search ?? '') ?>" 
                   placeholder="Cari nama, email, no. hp, atau preferensi diet..." 
                   class="w-full pl-9 pr-8 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
            <button id="clearSearchBtn" class="hidden absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <span class="material-symbols-outlined text-[16px]">cancel</span>
            </button>
        </div>

        <!-- Filter Status Buttons -->
        <div class="flex items-center gap-1.5 text-xs">
            <button type="button" onclick="filterStatus('all')" id="filterBtnAll" class="px-2.5 py-1.5 rounded-lg font-semibold text-red-600 bg-red-50 border border-red-200 transition-colors">
                Semua (<span id="countAll"><?= $totalUsers ?></span>)
            </button>
            <button type="button" onclick="filterStatus('active')" id="filterBtnActive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Aktif (<span id="countActive"><?= $activeCount ?></span>)
            </button>
            <button type="button" onclick="filterStatus('banned')" id="filterBtnBanned" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Diblokir (<span id="countBanned"><?= $bannedCount ?></span>)
            </button>
        </div>
    </div>
</div>

<!-- Table Card -->
<div class="bg-white rounded-xl border border-red-100 shadow-xs overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse text-xs">
            <thead>
                <tr class="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                    <th class="py-3 px-4">Pengguna</th>
                    <th class="py-3 px-3">Gender &amp; Lahir</th>
                    <th class="py-3 px-3">Diet &amp; Preferensi</th>
                    <th class="py-3 px-3">Perangkat &amp; App</th>
                    <th class="py-3 px-3 text-center">Status Akun</th>
                    <th class="py-3 px-3 text-center">Voucher Aktif</th>
                    <th class="py-3 px-3">Terdaftar</th>
                    <th class="py-3 px-4 text-right">Aksi</th>
                </tr>
            </thead>
            <tbody id="userTableBody" class="divide-y divide-slate-100">
                <?php if (empty($users)): ?>
                    <tr id="emptyRow">
                        <td colspan="8" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-[36px] text-slate-300 block mb-2">person_off</span>
                            Belum ada profil pengguna yang ditemukan.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($users as $u): ?>
                        <tr class="user-row hover:bg-red-50/30 transition-colors"
                            data-name="<?= strtolower(esc($u['display_name'] ?? '')) ?>"
                            data-email="<?= strtolower(esc($u['email'] ?? '')) ?>"
                            data-phone="<?= strtolower(esc($u['phone'] ?? '')) ?>"
                            data-diet="<?= strtolower(esc($u['dietary_type'] ?? '')) ?>"
                            data-device="<?= strtolower(esc($u['device_model'] ?? '')) ?>"
                            data-os="<?= strtolower(esc($u['device_os'] ?? '')) ?>"
                            data-app="<?= strtolower(esc($u['app_version'] ?? '')) ?>"
                            data-status="<?= $u['is_banned'] ? 'banned' : 'active' ?>">
                            
                            <!-- Pengguna -->
                            <td class="py-3 px-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-9 h-9 rounded-full <?= $u['is_banned'] ? 'bg-red-100 text-red-600' : 'bg-red-50 text-red-600' ?> font-black flex items-center justify-center text-xs shrink-0 border <?= $u['is_banned'] ? 'border-red-200' : 'border-red-100' ?>">
                                        <?= strtoupper(substr($u['display_name'] ?? 'U', 0, 1)) ?>
                                    </div>
                                    <div class="min-w-0">
                                        <div class="font-bold text-slate-900 truncate flex items-center gap-1.5">
                                            <?= esc($u['display_name'] ?? 'Pengguna') ?>
                                            <?php if ($u['is_banned']): ?>
                                                <span class="inline-flex items-center px-1.5 py-0.2 rounded text-[9px] font-bold bg-red-100 text-red-700 border border-red-200">
                                                    BANNED
                                                </span>
                                            <?php endif; ?>
                                        </div>
                                        <div class="text-[11px] text-slate-500 font-mono truncate"><?= esc($u['email'] ?? '-') ?></div>
                                        <?php if (!empty($u['phone'])): ?>
                                            <div class="text-[10px] text-slate-400 font-mono"><?= esc($u['phone']) ?></div>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </td>

                            <!-- Gender & Lahir -->
                            <td class="py-3 px-3">
                                <div class="font-semibold text-slate-700">
                                    <?= esc($u['gender'] ?? '-') ?>
                                </div>
                                <div class="text-[10px] text-slate-400 font-mono">
                                    <?= esc($u['birth_date'] ?? '-') ?>
                                </div>
                            </td>

                            <!-- Diet & Preferensi -->
                            <td class="py-3 px-3">
                                <div class="flex flex-wrap items-center gap-1">
                                    <?php if ($u['is_halal_only']): ?>
                                        <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                            Halal Only
                                        </span>
                                    <?php endif; ?>
                                    <?php if (!empty($u['dietary_type']) && $u['dietary_type'] !== 'none'): ?>
                                        <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-50 text-amber-700 border border-amber-200">
                                            <?= esc(ucfirst($u['dietary_type'])) ?>
                                        </span>
                                    <?php endif; ?>
                                    <?php if (empty($u['dietary_type']) || $u['dietary_type'] === 'none'): ?>
                                        <span class="text-slate-400 text-[11px]">Bebas / Standar</span>
                                    <?php endif; ?>
                                </div>
                            </td>

                            <!-- Perangkat & App -->
                            <td class="py-3 px-3">
                                <?php if (!empty($u['device_model']) || !empty($u['device_os'])): ?>
                                    <div class="flex flex-col gap-1">
                                        <div class="font-bold text-slate-800 text-xs flex items-center gap-1.5">
                                            <span class="material-symbols-outlined text-[15px] <?= str_contains(strtolower($u['device_os'] ?? ''), 'android') ? 'text-emerald-600' : (str_contains(strtolower($u['device_os'] ?? ''), 'ios') ? 'text-slate-700' : 'text-slate-500') ?>">
                                                <?= str_contains(strtolower($u['device_os'] ?? ''), 'ios') ? 'phone_iphone' : 'smartphone' ?>
                                            </span>
                                            <span class="truncate max-w-[150px]" title="<?= esc($u['device_model'] ?? 'Mobile Device') ?>">
                                                <?= esc($u['device_model'] ?? 'Mobile Device') ?>
                                            </span>
                                        </div>
                                        <div class="flex items-center gap-1 flex-wrap">
                                            <?php if (!empty($u['device_os'])): ?>
                                                <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                                                    <?= esc($u['device_os']) ?>
                                                </span>
                                            <?php endif; ?>
                                            <?php if (!empty($u['app_version'])): ?>
                                                <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-mono font-bold bg-blue-50 text-blue-700 border border-blue-200">
                                                    <?= esc($u['app_version']) ?>
                                                </span>
                                            <?php endif; ?>
                                        </div>
                                        <?php if (!empty($u['last_active_at'])): ?>
                                            <div class="text-[10px] text-slate-400">
                                                Aktif: <?= date('d/m/y H:i', strtotime($u['last_active_at'])) ?>
                                            </div>
                                        <?php endif; ?>
                                    </div>
                                <?php else: ?>
                                    <span class="text-slate-400 text-xs italic">Belum terhubung</span>
                                <?php endif; ?>
                            </td>

                            <!-- Status Akun -->
                            <td class="py-3 px-3 text-center">
                                <?php if ($u['is_banned']): ?>
                                    <div class="inline-flex flex-col items-center">
                                        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">
                                            <span class="material-symbols-outlined text-[12px]">block</span>
                                            Diblokir
                                        </span>
                                        <?php if (!empty($u['banned_reason'])): ?>
                                            <span class="text-[9px] text-red-500 max-w-[130px] truncate mt-0.5" title="<?= esc($u['banned_reason']) ?>">
                                                <?= esc($u['banned_reason']) ?>
                                            </span>
                                        <?php endif; ?>
                                    </div>
                                <?php else: ?>
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        <span class="material-symbols-outlined text-[12px]">check_circle</span>
                                        Aktif
                                    </span>
                                <?php endif; ?>
                            </td>

                            <!-- Voucher Aktif -->
                            <td class="py-3 px-3 text-center">
                                <button type="button" 
                                        onclick="viewUserVouchers('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>')"
                                        class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold transition-all border <?= $u['active_vouchers'] > 0 ? 'bg-amber-50 text-amber-800 border-amber-200 hover:bg-amber-100' : 'bg-slate-50 text-slate-500 border-slate-200 hover:bg-slate-100' ?>">
                                    <span class="material-symbols-outlined text-[14px]">confirmation_number</span>
                                    <span><?= $u['active_vouchers'] ?> Kupon</span>
                                </button>
                            </td>

                            <!-- Terdaftar -->
                            <td class="py-3 px-3 text-slate-500 font-mono text-[11px]">
                                <?= date('d M Y', strtotime($u['created_at'] ?? 'now')) ?>
                            </td>

                            <!-- Aksi -->
                            <td class="py-3 px-4 text-right">
                                <div class="flex items-center justify-end gap-1.5">
                                    <!-- Injeksi Voucher Button -->
                                    <button type="button" 
                                            onclick="openInjectModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>', '<?= esc($u['email']) ?>', <?= $u['is_banned'] ? 'true' : 'false' ?>)"
                                            class="px-2.5 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-2xs"
                                            title="Injeksi Voucher ke Pengguna">
                                        <span class="material-symbols-outlined text-[14px]">add_card</span>
                                        <span>Injeksi Voucher</span>
                                    </button>

                                    <!-- Ban / Unban Button -->
                                    <?php if ($u['is_banned']): ?>
                                        <button type="button" 
                                                onclick="openBanModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>', true)"
                                                class="p-1.5 rounded-lg border border-emerald-200 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 transition-colors shadow-2xs"
                                                title="Buka Blokir (Unban)">
                                            <span class="material-symbols-outlined text-[16px]">lock_open</span>
                                        </button>
                                    <?php else: ?>
                                        <button type="button" 
                                                onclick="openBanModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>', false)"
                                                class="p-1.5 rounded-lg border border-red-200 bg-white hover:bg-red-50 text-red-600 transition-colors shadow-2xs"
                                                title="Blokir Akun (Ban)">
                                            <span class="material-symbols-outlined text-[16px]">block</span>
                                        </button>
                                    <?php endif; ?>

                                    <!-- Delete Button -->
                                    <button type="button"
                                            onclick="openDeleteModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>')"
                                            class="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-red-50 hover:border-red-200 text-slate-400 hover:text-red-600 transition-colors shadow-2xs"
                                            title="Hapus Profil">
                                        <span class="material-symbols-outlined text-[16px]">delete</span>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Pagination Footer -->
    <div class="px-4 py-3 bg-slate-50 border-t border-slate-200 flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="text-slate-500">
            Menampilkan <span id="showingStart" class="font-bold text-slate-800">1</span>-<span id="showingEnd" class="font-bold text-slate-800">10</span> dari <span id="showingTotal" class="font-bold text-slate-800"><?= $totalUsers ?></span> pengguna
        </div>
        <div class="flex items-center gap-1.5">
            <button type="button" id="prevPageBtn" onclick="changePage(-1)" class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 font-semibold text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed">
                Sebelumnya
            </button>
            <div id="pageNumbers" class="flex items-center gap-1"></div>
            <button type="button" id="nextPageBtn" onclick="changePage(1)" class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 font-semibold text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed">
                Berikutnya
            </button>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: INJEKSI VOUCHER KE USER -->
<!-- ========================================================================= -->
<div id="injectVoucherModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeInjectModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
            <div class="flex items-center gap-2.5">
                <div class="w-9 h-9 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100">
                    <span class="material-symbols-outlined text-[20px]">add_card</span>
                </div>
                <div>
                    <h3 class="text-base font-extrabold text-slate-900">Injeksi Voucher Khusus</h3>
                    <p class="text-xs text-slate-500">Kirim kupon promo eksklusif ke akun pengguna</p>
                </div>
            </div>
            <button type="button" onclick="closeInjectModal()" class="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>

        <form action="/users/inject-voucher" method="post" class="space-y-4">
            <?= csrf_field() ?>
            <input type="hidden" name="user_id" id="injectUserId">

            <!-- Target User Card -->
            <div class="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
                <div>
                    <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Target Pengguna:</span>
                    <span id="injectUserName" class="text-sm font-extrabold text-slate-900 block mt-0.5">Nama Pengguna</span>
                    <span id="injectUserEmail" class="text-xs text-slate-500 font-mono">email@example.com</span>
                </div>
                <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                    Akun Aktif
                </span>
            </div>

            <!-- Pilih Mitra Sponsor (Opsional) -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Pilih Dari Restoran Mitra (Opsional)</label>
                <select name="merchant_id" id="injectMerchantSelect" onchange="onMerchantSelectChanged()"
                        class="w-full px-3 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                    <option value="">-- Kupon Bebas / Khusus (Custom Voucher) --</option>
                    <?php foreach ($merchants as $m): ?>
                        <option value="<?= esc($m['id']) ?>" 
                                data-code="<?= esc($m['voucher_code']) ?>" 
                                data-desc="<?= esc($m['discount_description']) ?>">
                            <?= esc($m['merchant_name']) ?> (<?= esc($m['voucher_code']) ?> - <?= esc($m['discount_description']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
                <p class="text-[10px] text-slate-400 mt-1">Memilih resto mitra akan otomatis mengisi kode dan deskripsi diskon.</p>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <!-- Kode Voucher -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1">Kode Voucher <span class="text-red-500">*</span></label>
                    <input type="text" name="voucher_code" id="injectVoucherCode" required placeholder="MISAL: VIPMOOD50"
                           class="w-full px-3 py-2 text-xs font-mono uppercase font-bold rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                </div>

                <!-- Masa Berlaku -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1">Masa Berlaku <span class="text-red-500">*</span></label>
                    <select name="duration_hours" class="w-full px-3 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                        <option value="1">1 Jam (Flash Deal)</option>
                        <option value="6">6 Jam (Same Day)</option>
                        <option value="24" selected>24 Jam (1 Hari)</option>
                        <option value="72">3 Hari</option>
                        <option value="168">7 Hari (1 Minggu)</option>
                    </select>
                </div>
            </div>

            <!-- Deskripsi Diskon -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Deskripsi Diskon / Keuntungan <span class="text-red-500">*</span></label>
                <input type="text" name="discount_description" id="injectDiscountDesc" required placeholder="Contoh: Diskon 50% Khusus Mood Lover"
                       class="w-full px-3 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
            </div>

            <div class="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button type="button" onclick="closeInjectModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    Batal
                </button>
                <button type="submit" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1.5 transition-colors shadow-sm">
                    <span class="material-symbols-outlined text-[16px]">send</span>
                    Injeksi Voucher Sekarang
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: DAFTAR VOUCHER USER -->
<!-- ========================================================================= -->
<div id="userVouchersModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeVouchersModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
            <div class="flex items-center gap-2.5">
                <div class="w-9 h-9 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center border border-amber-200">
                    <span class="material-symbols-outlined text-[20px]">confirmation_number</span>
                </div>
                <div>
                    <h3 class="text-base font-extrabold text-slate-900">Koleksi Kupon Pengguna</h3>
                    <p class="text-xs text-slate-500" id="vouchersModalSubtitle">Riwayat voucher aktif dan kedaluwarsa</p>
                </div>
            </div>
            <button type="button" onclick="closeVouchersModal()" class="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>

        <div id="vouchersLoading" class="py-12 text-center text-slate-400">
            <div class="w-6 h-6 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto mb-2"></div>
            Memuat daftar voucher pengguna...
        </div>

        <div id="vouchersContent" class="hidden">
            <div class="max-h-[350px] overflow-y-auto space-y-2.5 pr-1">
                <div id="vouchersList"></div>
            </div>
            <div id="noVouchersMsg" class="hidden py-8 text-center text-slate-400">
                <span class="material-symbols-outlined text-[32px] text-slate-300 block mb-1.5">local_activity</span>
                Pengguna ini belum memiliki voucher aktif maupun riwayat klaim.
            </div>
        </div>

        <div class="pt-4 border-t border-slate-100 flex items-center justify-end mt-4">
            <button type="button" onclick="closeVouchersModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                Tutup
            </button>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: KONFIRMASI BAN / UNBAN USER -->
<!-- ========================================================================= -->
<div id="banModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeBanModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center gap-3 mb-3">
            <div id="banModalIcon" class="w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0">
                <span class="material-symbols-outlined text-[22px]">block</span>
            </div>
            <div>
                <h3 class="text-base font-extrabold text-slate-900" id="banModalTitle">Blokir Akun Pengguna</h3>
                <p class="text-xs text-slate-500" id="banModalSubtitle">Tindakan ini akan mencegah pengguna mengakses layanan</p>
            </div>
        </div>

        <form id="banForm" action="" method="post" class="space-y-4">
            <?= csrf_field() ?>
            <p class="text-xs text-slate-600 leading-relaxed" id="banModalMessage">
                Apakah Anda yakin ingin memblokir akun <strong id="banTargetName">Pengguna</strong>?
            </p>

            <div id="banReasonContainer">
                <label class="block text-xs font-bold text-slate-700 mb-1">Alasan Pemblokiran</label>
                <input type="text" name="reason" id="banReasonInput" placeholder="Contoh: Spam berulang, pelanggaran ToS, kecurangan promo..." 
                       class="w-full px-3 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500">
            </div>

            <div class="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button type="button" onclick="closeBanModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    Batal
                </button>
                <button type="submit" id="banSubmitBtn" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                    Blokir Akun
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: HAPUS USER -->
<!-- ========================================================================= -->
<div id="deleteUserModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeDeleteModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0">
                <span class="material-symbols-outlined text-[22px]">delete_forever</span>
            </div>
            <div>
                <h3 class="text-base font-extrabold text-slate-900">Hapus Profil Pengguna</h3>
                <p class="text-xs text-slate-500">Tindakan ini permanen dan tidak dapat dibatalkan</p>
            </div>
        </div>
        <p class="text-xs text-slate-600 mb-5 leading-relaxed">
            Hapus seluruh data profil pengguna <strong id="deleteTargetName">Pengguna</strong> beserta riwayat voucher terkait?
        </p>
        <div class="flex items-center justify-end gap-2">
            <button type="button" onclick="closeDeleteModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                Batal
            </button>
            <a id="deleteConfirmBtn" href="#" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                Hapus Sekarang
            </a>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- JAVASCRIPT: FILTERING, MODALS & PAGINATION -->
<!-- ========================================================================= -->
<script>
    let currentFilter = 'all';
    let searchQuery = '';
    let currentPage = 1;
    const pageSize = 10;

    const searchInput = document.getElementById('userSearchInput');
    const clearBtn = document.getElementById('clearSearchBtn');

    searchInput.addEventListener('input', function() {
        searchQuery = this.value.trim().toLowerCase();
        clearBtn.classList.toggle('hidden', searchQuery === '');
        currentPage = 1;
        applyFilters();
    });

    clearBtn.addEventListener('click', function() {
        searchInput.value = '';
        searchQuery = '';
        clearBtn.classList.add('hidden');
        currentPage = 1;
        applyFilters();
    });

    function filterStatus(status) {
        currentFilter = status;
        currentPage = 1;

        const btnAll = document.getElementById('filterBtnAll');
        const btnActive = document.getElementById('filterBtnActive');
        const btnBanned = document.getElementById('filterBtnBanned');

        const activeCls = 'text-red-600 bg-red-50 border-red-200';
        const inactiveCls = 'text-slate-600 hover:bg-slate-50 border-slate-200';

        [btnAll, btnActive, btnBanned].forEach(b => {
            b.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + inactiveCls;
        });

        if (status === 'all') btnAll.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'active') btnActive.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'banned') btnBanned.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;

        applyFilters();
    }

    function applyFilters() {
        const rows = document.querySelectorAll('.user-row');
        let visibleRows = [];

        rows.forEach(row => {
            const name = row.getAttribute('data-name') || '';
            const email = row.getAttribute('data-email') || '';
            const phone = row.getAttribute('data-phone') || '';
            const diet = row.getAttribute('data-diet') || '';
            const device = row.getAttribute('data-device') || '';
            const os = row.getAttribute('data-os') || '';
            const app = row.getAttribute('data-app') || '';
            const status = row.getAttribute('data-status') || '';

            const matchesSearch = searchQuery === '' || 
                                  name.includes(searchQuery) || 
                                  email.includes(searchQuery) || 
                                  phone.includes(searchQuery) || 
                                  diet.includes(searchQuery) ||
                                  device.includes(searchQuery) ||
                                  os.includes(searchQuery) ||
                                  app.includes(searchQuery);

            const matchesFilter = currentFilter === 'all' || status === currentFilter;

            if (matchesSearch && matchesFilter) {
                visibleRows.push(row);
            } else {
                row.style.display = 'none';
            }
        });

        const totalVisible = visibleRows.length;
        const totalPages = Math.ceil(totalVisible / pageSize) || 1;
        if (currentPage > totalPages) currentPage = totalPages;

        const startIdx = (currentPage - 1) * pageSize;
        const endIdx = startIdx + pageSize;

        visibleRows.forEach((row, idx) => {
            if (idx >= startIdx && idx < endIdx) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });

        // Update footer info
        document.getElementById('showingStart').innerText = totalVisible === 0 ? '0' : (startIdx + 1);
        document.getElementById('showingEnd').innerText = Math.min(endIdx, totalVisible);
        document.getElementById('showingTotal').innerText = totalVisible;

        // Update buttons
        document.getElementById('prevPageBtn').disabled = currentPage <= 1;
        document.getElementById('nextPageBtn').disabled = currentPage >= totalPages;

        // Render page numbers
        const pageNumbersContainer = document.getElementById('pageNumbers');
        pageNumbersContainer.innerHTML = '';
        for (let p = 1; p <= totalPages; p++) {
            const pageBtn = document.createElement('button');
            pageBtn.type = 'button';
            pageBtn.innerText = p;
            pageBtn.className = 'w-7 h-7 rounded-lg font-bold text-xs flex items-center justify-center transition-colors ' + 
                (p === currentPage ? 'bg-red-600 text-white shadow-2xs' : 'border border-slate-200 bg-white hover:bg-slate-50 text-slate-600');
            pageBtn.onclick = () => { currentPage = p; applyFilters(); };
            pageNumbersContainer.appendChild(pageBtn);
        }
    }

    function changePage(delta) {
        currentPage += delta;
        applyFilters();
    }

    // Modal Injeksi Voucher
    function openInjectModal(userId, userName, userEmail, isBanned) {
        if (isBanned) {
            alert('Tidak dapat menginjeksi voucher ke pengguna yang sedang berstatus BANNED.');
            return;
        }
        document.getElementById('injectUserId').value = userId;
        document.getElementById('injectUserName').innerText = userName;
        document.getElementById('injectUserEmail').innerText = userEmail;
        document.getElementById('injectMerchantSelect').value = '';
        document.getElementById('injectVoucherCode').value = '';
        document.getElementById('injectDiscountDesc').value = '';
        document.getElementById('injectVoucherModal').classList.remove('hidden');
    }

    function closeInjectModal() {
        document.getElementById('injectVoucherModal').classList.add('hidden');
    }

    function onMerchantSelectChanged() {
        const select = document.getElementById('injectMerchantSelect');
        const selectedOption = select.options[select.selectedIndex];
        if (selectedOption && selectedOption.value) {
            document.getElementById('injectVoucherCode').value = selectedOption.getAttribute('data-code') || '';
            document.getElementById('injectDiscountDesc').value = selectedOption.getAttribute('data-desc') || '';
        }
    }

    // Modal Ban / Unban
    function openBanModal(userId, userName, isCurrentlyBanned) {
        const form = document.getElementById('banForm');
        form.action = '/users/toggle-ban/' + userId;
        document.getElementById('banTargetName').innerText = userName;

        const iconContainer = document.getElementById('banModalIcon');
        const title = document.getElementById('banModalTitle');
        const subtitle = document.getElementById('banModalSubtitle');
        const reasonContainer = document.getElementById('banReasonContainer');
        const submitBtn = document.getElementById('banSubmitBtn');

        if (isCurrentlyBanned) {
            // Unban mode
            iconContainer.className = 'w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200 shrink-0';
            iconContainer.innerHTML = '<span class="material-symbols-outlined text-[22px]">lock_open</span>';
            title.innerText = 'Buka Blokir (Unban)';
            subtitle.innerText = 'Pulihkan akses akun pengguna ke aplikasi MoodEats';
            document.getElementById('banModalMessage').innerHTML = 'Apakah Anda yakin ingin mengaktifkan kembali akun <strong>' + userName + '</strong>?';
            reasonContainer.classList.add('hidden');
            submitBtn.className = 'px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm';
            submitBtn.innerText = 'Buka Blokir Sekarang';
        } else {
            // Ban mode
            iconContainer.className = 'w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0';
            iconContainer.innerHTML = '<span class="material-symbols-outlined text-[22px]">block</span>';
            title.innerText = 'Blokir Akun Pengguna';
            subtitle.innerText = 'Tindakan ini akan mencegah pengguna mengakses layanan';
            document.getElementById('banModalMessage').innerHTML = 'Apakah Anda yakin ingin memblokir akun <strong>' + userName + '</strong>?';
            reasonContainer.classList.remove('hidden');
            document.getElementById('banReasonInput').value = '';
            submitBtn.className = 'px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm';
            submitBtn.innerText = 'Blokir Akun';
        }

        document.getElementById('banModal').classList.remove('hidden');
    }

    function closeBanModal() {
        document.getElementById('banModal').classList.add('hidden');
    }

    // Modal Delete User
    function openDeleteModal(userId, userName) {
        document.getElementById('deleteTargetName').innerText = userName;
        document.getElementById('deleteConfirmBtn').href = '/users/delete/' + userId;
        document.getElementById('deleteUserModal').classList.remove('hidden');
    }

    function closeDeleteModal() {
        document.getElementById('deleteUserModal').classList.add('hidden');
    }

    // Modal View User Vouchers
    async function viewUserVouchers(userId, userName) {
        const modal = document.getElementById('userVouchersModal');
        const loading = document.getElementById('vouchersLoading');
        const content = document.getElementById('vouchersContent');
        const list = document.getElementById('vouchersList');
        const emptyMsg = document.getElementById('noVouchersMsg');

        document.getElementById('vouchersModalSubtitle').innerText = 'Koleksi voucher aktif & riwayat milik ' + userName;

        modal.classList.remove('hidden');
        loading.classList.remove('hidden');
        content.classList.add('hidden');
        list.innerHTML = '';
        emptyMsg.classList.add('hidden');

        try {
            const res = await fetch('/users/vouchers/' + userId);
            const data = await res.json();

            loading.classList.add('hidden');
            content.classList.remove('hidden');

            if (data.status === 'success' && data.vouchers && data.vouchers.length > 0) {
                data.vouchers.forEach(v => {
                    const isExpired = v.status === 'expired' || new Date(v.expires_at) < new Date();
                    const statusBadge = v.status === 'redeemed' 
                        ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-600">Redeemed</span>'
                        : (isExpired 
                            ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">Expired</span>'
                            : '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">Active</span>');

                    const revokeBtn = (!isExpired && v.status === 'active')
                        ? `<a href="/users/revoke-voucher/${v.id}" class="px-2 py-1 text-[10px] font-bold text-red-600 hover:bg-red-50 rounded border border-red-200 transition-colors">Cabut</a>`
                        : '';

                    const item = document.createElement('div');
                    item.className = 'p-3 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between gap-3 text-xs';
                    item.innerHTML = `
                        <div class="min-w-0">
                            <div class="flex items-center gap-2">
                                <span class="font-mono font-bold text-sm text-red-600">${v.voucher_code}</span>
                                ${statusBadge}
                                ${v.injected_by ? '<span class="text-[9px] font-mono bg-purple-50 text-purple-700 px-1.5 py-0.5 rounded border border-purple-200">Injected by ' + v.injected_by + '</span>' : ''}
                            </div>
                            <div class="font-semibold text-slate-800 mt-0.5 truncate">${v.discount_description || v.merchant_name || 'Voucher Promo'}</div>
                            <div class="text-[10px] text-slate-400 mt-0.5">
                                Berakhir: <span class="font-mono font-semibold">${new Date(v.expires_at).toLocaleString('id-ID')}</span>
                            </div>
                        </div>
                        <div class="shrink-0 flex items-center gap-1.5">
                            ${revokeBtn}
                        </div>
                    `;
                    list.appendChild(item);
                });
            } else {
                emptyMsg.classList.remove('hidden');
            }
        } catch (e) {
            loading.classList.add('hidden');
            content.classList.remove('hidden');
            list.innerHTML = '<div class="text-xs text-red-500 py-4 text-center">Gagal memuat data voucher: ' + e + '</div>';
        }
    }

    function closeVouchersModal() {
        document.getElementById('userVouchersModal').classList.add('hidden');
    }

    // Initialize pagination on load
    applyFilters();
</script>

<?= $this->endSection() ?>
