<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header -->
<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span><?= esc(lang('Admin.brand_name')) ?></span>
            <span>/</span>
            <span><?= esc(lang('Admin.nav_users')) ?></span>
            <span>/</span>
            <span class="text-red-600 font-bold"><?= esc(lang('Admin.users_badge')) ?></span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-3">
            <?= esc(lang('Admin.users_title')) ?>
            <?php if ($isPrivileged): ?>
                <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-amber-50 text-amber-800 border border-amber-300">
                    <?= esc(lang('Admin.audit_privileged_badge')) ?>
                </span>
            <?php else: ?>
                <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-blue-50 text-blue-800 border border-blue-300">
                    <?= esc(lang('Admin.audit_compliance_badge')) ?>
                </span>
            <?php endif; ?>
        </h1>
        <p class="text-xs text-slate-500 mt-0.5">
            <?= esc(lang('Admin.users_desc')) ?>
        </p>
    </div>
</div>

<!-- Stats Overview Cards (6 Lifecycle Counters) -->
<div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mb-4">
    <!-- Total -->
    <div class="bg-white p-3 rounded-xl border border-red-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider"><?= esc(lang('Admin.users_kpi_total')) ?></div>
            <div class="text-xl font-black text-slate-900 mt-0.5"><?= $totalUsers ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-600">
            <span class="material-symbols-outlined text-[18px]">group</span>
        </div>
    </div>

    <!-- Active -->
    <div class="bg-white p-3 rounded-xl border border-emerald-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-emerald-600 uppercase tracking-wider"><?= esc(lang('Admin.users_kpi_active')) ?></div>
            <div class="text-xl font-black text-emerald-600 mt-0.5"><?= $activeCount ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center justify-center text-emerald-600">
            <span class="material-symbols-outlined text-[18px]">check_circle</span>
        </div>
    </div>

    <!-- Banned -->
    <div class="bg-white p-3 rounded-xl border border-red-200 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-red-600 uppercase tracking-wider"><?= esc(lang('Admin.users_kpi_banned')) ?></div>
            <div class="text-xl font-black text-red-600 mt-0.5"><?= $bannedCount ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-red-50 border border-red-200 flex items-center justify-center text-red-600" title="Protected Anti-Evasion">
            <span class="material-symbols-outlined text-[18px]">block</span>
        </div>
    </div>

    <!-- Dormant (>30d) -->
    <div class="bg-white p-3 rounded-xl border border-amber-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-amber-600 uppercase tracking-wider">Dormant (&gt;30d)</div>
            <div class="text-xl font-black text-amber-600 mt-0.5"><?= $dormantCount ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600">
            <span class="material-symbols-outlined text-[18px]">bedtime</span>
        </div>
    </div>

    <!-- Pending Deletion -->
    <div class="bg-white p-3 rounded-xl border border-purple-100 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-purple-600 uppercase tracking-wider">Grace Period</div>
            <div class="text-xl font-black text-purple-600 mt-0.5"><?= $pendingDeletionCount ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-purple-50 border border-purple-200 flex items-center justify-center text-purple-600">
            <span class="material-symbols-outlined text-[18px]">hourglass_top</span>
        </div>
    </div>

    <!-- Anonymized (Crypto-Shredded) -->
    <div class="bg-white p-3 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[10px] font-bold text-slate-500 uppercase tracking-wider"><?= esc(lang('Admin.users_kpi_anonymized')) ?></div>
            <div class="text-xl font-black text-slate-700 mt-0.5"><?= $anonymizedCount ?></div>
        </div>
        <div class="w-8 h-8 rounded-lg bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-500" title="Crypto-shredded & unlinked">
            <span class="material-symbols-outlined text-[18px]">visibility_off</span>
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
                   placeholder="<?= esc(lang('Admin.users_search_placeholder')) ?>" 
                   class="w-full pl-9 pr-8 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
            <button id="clearSearchBtn" class="hidden absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <span class="material-symbols-outlined text-[16px]">cancel</span>
            </button>
        </div>

        <!-- Filter Status Buttons -->
        <div class="flex items-center flex-wrap gap-1.5 text-xs">
            <button type="button" onclick="filterStatus('all')" id="filterBtnAll" class="px-2.5 py-1.5 rounded-lg font-semibold text-red-600 bg-red-50 border border-red-200 transition-colors">
                <?= esc(lang('Admin.filter_all')) ?> (<span id="countAll"><?= $totalUsers ?></span>)
            </button>
            <button type="button" onclick="filterStatus('active')" id="filterBtnActive" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                <?= esc(lang('Admin.filter_active')) ?> (<span id="countActive"><?= $activeCount ?></span>)
            </button>
            <button type="button" onclick="filterStatus('banned')" id="filterBtnBanned" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                <?= esc(lang('Admin.users_status_banned')) ?> (<span id="countBanned"><?= $bannedCount ?></span>)
            </button>
            <button type="button" onclick="filterStatus('dormant')" id="filterBtnDormant" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Dormant (<span id="countDormant"><?= $dormantCount ?></span>)
            </button>
            <button type="button" onclick="filterStatus('pending_deletion')" id="filterBtnPending" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                Grace Period (<span id="countPending"><?= $pendingDeletionCount ?></span>)
            </button>
            <button type="button" onclick="filterStatus('anonymized')" id="filterBtnAnon" class="px-2.5 py-1.5 rounded-lg font-semibold text-slate-600 hover:bg-slate-50 border border-slate-200 transition-colors">
                <?= esc(lang('Admin.users_status_shredded')) ?> (<span id="countAnon"><?= $anonymizedCount ?></span>)
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
                    <th class="py-3 px-4"><?= esc(lang('Admin.users_col_profile')) ?></th>
                    <th class="py-3 px-3"><?= esc(lang('Admin.users_detail_gender')) ?> &amp; <?= esc(lang('Admin.users_detail_birth')) ?></th>
                    <th class="py-3 px-3"><?= esc(lang('Admin.users_col_preferences')) ?></th>
                    <th class="py-3 px-3"><?= esc(lang('Admin.users_col_device')) ?></th>
                    <th class="py-3 px-3 text-center"><?= esc(lang('Admin.users_col_status')) ?></th>
                    <th class="py-3 px-3 text-center"><?= esc(lang('Admin.users_detail_sec_vouchers')) ?></th>
                    <th class="py-3 px-3"><?= esc(lang('Admin.created_at')) ?></th>
                    <th class="py-3 px-4 text-right"><?= esc(lang('Admin.actions')) ?></th>
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
                        <?php
                            $effectiveStatus = $u['effective_status'] ?? 'active';
                            $isBanned = ($effectiveStatus === 'banned');
                            $isAnonymized = ($effectiveStatus === 'anonymized');
                        ?>
                        <tr class="user-row hover:bg-red-50/30 transition-colors"
                            data-name="<?= strtolower(esc($u['display_name'] ?? '')) ?>"
                            data-email="<?= strtolower(esc($u['email_display'] ?? '')) ?>"
                            data-phone="<?= strtolower(esc($u['phone_display'] ?? '')) ?>"
                            data-diet="<?= strtolower(esc($u['dietary_type'] ?? '')) ?>"
                            data-device="<?= strtolower(esc($u['device_model'] ?? '')) ?>"
                            data-os="<?= strtolower(esc($u['device_os'] ?? '')) ?>"
                            data-app="<?= strtolower(esc($u['app_version'] ?? '')) ?>"
                            data-status="<?= esc($effectiveStatus) ?>">
                            
                            <!-- Pengguna & PII Info -->
                            <td class="py-3 px-4">
                                <div class="flex items-center gap-3 cursor-pointer group" 
                                     onclick="openUserDetailModal('<?= esc($u['id']) ?>')"
                                     title="Klik untuk melihat detail profil pengguna">
                                    <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-xs shrink-0 transition-transform group-hover:scale-105 <?= $isBanned ? 'bg-red-100 text-red-700' : ($isAnonymized ? 'bg-slate-200 text-slate-600' : 'bg-red-50 text-red-600') ?>">
                                        <?= strtoupper(substr($u['display_name'] ?? 'U', 0, 1)) ?>
                                    </div>
                                    <div class="min-w-0">
                                        <div class="font-bold text-slate-900 truncate flex items-center gap-1.5 group-hover:text-red-600 transition-colors">
                                            <?= esc($u['display_name'] ?? 'Pengguna') ?>
                                            <?php if ($isBanned): ?>
                                                <span class="inline-flex items-center px-1.5 py-0.2 rounded text-[9px] font-bold bg-red-100 text-red-700 border border-red-200">
                                                    BANNED
                                                </span>
                                            <?php endif; ?>
                                        </div>
                                        <div class="text-[11px] text-slate-500 font-mono truncate">
                                            <?= esc($u['email_display'] ?? '-') ?>
                                            <?php if (!$isPrivileged && !empty($u['email']) && $u['email_display'] !== '-'): ?>
                                                <span class="text-[9px] text-blue-600 font-sans" title="Masked PII">(PDP)</span>
                                            <?php endif; ?>
                                        </div>
                                        <?php if (!empty($u['phone_display']) && $u['phone_display'] !== '-'): ?>
                                            <div class="text-[10px] text-slate-400 font-mono"><?= esc($u['phone_display']) ?></div>
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
                                    <?php if (!empty($u['is_halal_only'])): ?>
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

                            <!-- Perangkat & Telemetri -->
                            <td class="py-3 px-3">
                                <?php if (!empty($u['device_model']) || !empty($u['device_os'])): ?>
                                    <div class="flex flex-col gap-1">
                                        <div class="font-bold text-slate-800 text-xs flex items-center gap-1.5">
                                            <span class="material-symbols-outlined text-[15px] <?= str_contains(strtolower($u['device_os'] ?? ''), 'android') ? 'text-emerald-600' : 'text-slate-700' ?>">
                                                <?= str_contains(strtolower($u['device_os'] ?? ''), 'ios') ? 'phone_iphone' : 'smartphone' ?>
                                            </span>
                                            <span class="truncate max-w-[130px]" title="<?= esc($u['device_model'] ?? 'Mobile Device') ?>">
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
                                        <?php if (!empty($u['email_hash'])): ?>
                                            <div class="text-[9px] text-red-500 font-mono truncate max-w-[130px]" title="SHA-256 Anti-Evasion Hash: <?= esc($u['email_hash']) ?>">
                                                #hash: <?= substr($u['email_hash'], 0, 8) ?>...
                                            </div>
                                        <?php endif; ?>
                                    </div>
                                <?php else: ?>
                                    <span class="text-slate-400 text-xs italic">Belum terhubung</span>
                                <?php endif; ?>
                            </td>

                            <!-- Status Akun (PDP Lifecycle) -->
                            <td class="py-3 px-3 text-center">
                                <?php if ($effectiveStatus === 'banned'): ?>
                                    <div class="inline-flex flex-col items-center">
                                        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">
                                            <span class="material-symbols-outlined text-[12px]">block</span>
                                            BANNED
                                        </span>
                                        <?php if (!empty($u['banned_reason']) || !empty($u['ban_reason'])): ?>
                                            <span class="text-[9px] text-red-500 max-w-[130px] truncate mt-0.5" title="<?= esc($u['banned_reason'] ?? $u['ban_reason']) ?>">
                                                <?= esc($u['banned_reason'] ?? $u['ban_reason']) ?>
                                            </span>
                                        <?php endif; ?>
                                    </div>
                                <?php elseif ($effectiveStatus === 'dormant'): ?>
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200" title="Tidak aktif lebih dari 30 hari">
                                        <span class="material-symbols-outlined text-[12px]">bedtime</span>
                                        Dormant
                                    </span>
                                <?php elseif ($effectiveStatus === 'pending_deletion'): ?>
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-purple-50 text-purple-700 border border-purple-200" title="Masa tenggang penghapusan aktif (30 hari)">
                                        <span class="material-symbols-outlined text-[12px]">hourglass_top</span>
                                        Grace Period
                                    </span>
                                <?php elseif ($effectiveStatus === 'anonymized'): ?>
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-300" title="Crypto-shredded & Sessions Unlinked">
                                        <span class="material-symbols-outlined text-[12px]">visibility_off</span>
                                        Dianonimkan
                                    </span>
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
                                    <!-- Lihat Detail Pengguna Button -->
                                    <button type="button" 
                                            onclick="openUserDetailModal('<?= esc($u['id']) ?>')"
                                            class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-bold flex items-center gap-1 transition-colors shadow-2xs"
                                            title="Lihat Detail Profil Pengguna">
                                        <span class="material-symbols-outlined text-[15px] text-slate-500">visibility</span>
                                        <span>Lihat</span>
                                    </button>

                                    <!-- Injeksi Voucher Button -->
                                    <button type="button" 
                                            onclick="openInjectModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>', '<?= esc($u['email_display']) ?>', <?= ($isBanned || $isAnonymized) ? 'true' : 'false' ?>)"
                                            class="px-2.5 py-1.5 rounded-lg <?= ($isBanned || $isAnonymized) ? 'bg-slate-200 text-slate-400 cursor-not-allowed' : 'bg-red-600 hover:bg-red-700 text-white' ?> text-xs font-bold flex items-center gap-1 transition-colors shadow-2xs"
                                            title="<?= ($isBanned || $isAnonymized) ? 'Tidak dapat injeksi voucher' : 'Injeksi Voucher ke Pengguna' ?>">
                                        <span class="material-symbols-outlined text-[14px]">add_card</span>
                                        <span>Injeksi</span>
                                    </button>

                                    <!-- Ban / Unban Button -->
                                    <?php if ($isBanned): ?>
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

                                    <!-- Crypto-Shred Button (UU PDP) -->
                                    <?php if (!$isBanned && !$isAnonymized): ?>
                                        <button type="button"
                                                onclick="openDeleteModal('<?= esc($u['id']) ?>', '<?= esc($u['display_name']) ?>')"
                                                class="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-red-50 hover:border-red-200 text-slate-400 hover:text-red-600 transition-colors shadow-2xs"
                                                title="Crypto-Shred &amp; Unlink Sessions (UU PDP)">
                                            <span class="material-symbols-outlined text-[16px]">delete</span>
                                        </button>
                                    <?php elseif ($isBanned): ?>
                                        <button type="button" disabled
                                                class="p-1.5 rounded-lg border border-slate-200 bg-slate-100 text-slate-300 cursor-not-allowed"
                                                title="Akun BANNED dilindungi dari penghapusan demi pencegahan ban evasion (UU PDP)">
                                            <span class="material-symbols-outlined text-[16px]">shield</span>
                                        </button>
                                    <?php endif; ?>
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
            <?= lang('Admin.pagination_showing') ?> <span id="showingStart" class="font-bold text-slate-800">1</span>-<span id="showingEnd" class="font-bold text-slate-800">10</span> <?= lang('Admin.pagination_of') ?> <span id="showingTotal" class="font-bold text-slate-800"><?= $totalUsers ?></span> <?= lang('Admin.pagination_users') ?>
        </div>
        <div class="flex items-center gap-1.5">
            <button type="button" id="prevPageBtn" onclick="changePage(-1)" class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 font-semibold text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed">
                <?= lang('Admin.pagination_previous') ?>
            </button>
            <div id="pageNumbers" class="flex items-center gap-1"></div>
            <button type="button" id="nextPageBtn" onclick="changePage(1)" class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 font-semibold text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed">
                <?= lang('Admin.pagination_next') ?>
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
                    <h3 class="text-base font-extrabold text-slate-900"><?= lang('Admin.users_inject_modal_title') ?></h3>
                    <p class="text-xs text-slate-500"><?= lang('Admin.users_inject_modal_subtitle') ?></p>
                </div>
            </div>
            <button type="button" onclick="closeInjectModal()" class="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>

        <form action="<?= site_url('users/inject-voucher') ?>" method="post" class="space-y-4">
            <?= csrf_field() ?>
            <input type="hidden" name="user_id" id="injectUserId" value="">

            <div class="p-3 bg-red-50/60 rounded-xl border border-red-100 flex items-center justify-between">
                <div>
                    <div class="text-[10px] uppercase font-bold text-red-600"><?= lang('Admin.users_inject_user_target') ?></div>
                    <div class="font-bold text-slate-900 text-xs mt-0.5" id="injectUserName">Pengguna</div>
                    <div class="text-[11px] text-slate-500 font-mono" id="injectUserEmail">email@example.com</div>
                </div>
                <span class="material-symbols-outlined text-[26px] text-red-400">person</span>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 mb-1"><?= lang('Admin.users_inject_merchant_target') ?></label>
                <select name="merchant_id" id="injectMerchantSelect" onchange="onMerchantSelectChanged()"
                        class="w-full text-xs rounded-lg border border-slate-200 py-2 px-3 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                    <option value=""><?= lang('Admin.users_inject_merchant_internal') ?></option>
                    <?php foreach ($merchants as $m): ?>
                        <option value="<?= esc($m['id']) ?>" 
                                data-code="<?= esc($m['voucher_code']) ?>"
                                data-desc="<?= esc($m['discount_description']) ?>">
                            <?= esc($m['merchant_name']) ?> (<?= esc($m['voucher_code']) ?> - <?= esc($m['discount_description']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1"><?= lang('Admin.users_inject_code') ?></label>
                    <input type="text" name="voucher_code" id="injectVoucherCode" placeholder="MISAL: LAPAR20" required
                           class="w-full text-xs font-mono font-bold uppercase rounded-lg border border-slate-200 py-2 px-3 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1"><?= lang('Admin.users_inject_expires_hours') ?></label>
                    <input type="number" name="duration_hours" id="injectDuration" value="24" min="1" max="720" required
                           class="w-full text-xs font-bold rounded-lg border border-slate-200 py-2 px-3 focus:border-red-500 focus:ring-1 focus:ring-red-500">
                </div>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 mb-1"><?= lang('Admin.users_inject_discount_desc') ?></label>
                <input type="text" name="discount_description" id="injectDiscountDesc" placeholder="Diskon 20% Min. Transaksi 50k" required
                       class="w-full text-xs rounded-lg border border-slate-200 py-2 px-3 focus:border-red-500 focus:ring-1 focus:ring-red-500">
            </div>

            <div class="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button type="button" onclick="closeInjectModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    <?= lang('Admin.cancel') ?>
                </button>
                <button type="submit" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                    <span class="material-symbols-outlined text-[16px]">send</span>
                    <?= lang('Admin.users_inject_btn_send') ?>
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
                    <h3 class="text-base font-extrabold text-slate-900"><?= lang('Admin.users_vouchers_modal_title') ?></h3>
                    <p class="text-xs text-slate-500" id="userVouchersSubtitle"><?= lang('Admin.users_vouchers_loading') ?></p>
                </div>
            </div>
            <button type="button" onclick="closeVouchersModal()" class="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>

        <div id="userVouchersLoading" class="py-10 text-center text-slate-400">
            <span class="material-symbols-outlined animate-spin text-[32px] text-red-600">sync</span>
            <div class="text-xs mt-2"><?= lang('Admin.users_vouchers_loading') ?></div>
        </div>

        <div id="userVouchersContent" class="hidden max-h-80 overflow-y-auto space-y-2 pr-1">
            <div id="userVouchersList" class="space-y-2"></div>
            <div id="userVouchersEmpty" class="hidden py-8 text-center text-slate-400 text-xs">
                <?= lang('Admin.users_vouchers_empty') ?>
            </div>
        </div>

        <div class="pt-4 border-t border-slate-100 mt-4 flex items-center justify-end">
            <button type="button" onclick="closeVouchersModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                <?= lang('Admin.close') ?>
            </button>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: BAN / UNBAN USER -->
<!-- ========================================================================= -->
<div id="banModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeBanModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <form id="banForm" action="" method="post" class="space-y-4">
            <?= csrf_field() ?>
            <div class="flex items-center gap-3">
                <div id="banModalIcon" class="w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0">
                    <span class="material-symbols-outlined text-[22px]">block</span>
                </div>
                <div>
                    <h3 id="banModalTitle" class="text-base font-extrabold text-slate-900"><?= lang('Admin.users_ban_modal_title') ?></h3>
                    <p id="banModalSubtitle" class="text-xs text-slate-500"><?= lang('Admin.users_ban_modal_sub') ?></p>
                </div>
            </div>

            <p id="banModalMessage" class="text-xs text-slate-600 leading-relaxed">
                <?= lang('Admin.users_ban_modal_msg') ?> <strong id="banTargetName">Pengguna</strong>?
            </p>

            <div id="banReasonContainer">
                <label class="block text-xs font-bold text-slate-700 mb-1"><?= lang('Admin.users_ban_reason_label') ?></label>
                <textarea name="reason" id="banReasonInput" rows="2" placeholder="<?= esc(lang('Admin.users_ban_reason_placeholder')) ?>"
                          class="w-full text-xs rounded-lg border border-slate-200 p-2.5 focus:border-red-500 focus:ring-1 focus:ring-red-500"></textarea>
                <p class="text-[10px] text-slate-400 mt-1"><?= lang('Admin.users_ban_reason_help') ?></p>
            </div>

            <div class="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button type="button" onclick="closeBanModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    <?= lang('Admin.cancel') ?>
                </button>
                <button type="submit" id="banSubmitBtn" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                    <?= lang('Admin.users_ban_submit_btn') ?>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: CRYPTO-SHRED / HAPUS PDP USER -->
<!-- ========================================================================= -->
<div id="deleteUserModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeDeleteModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0">
                <span class="material-symbols-outlined text-[22px]">delete_forever</span>
            </div>
            <div>
                <h3 class="text-base font-extrabold text-slate-900"><?= lang('Admin.users_shred_modal_title') ?></h3>
                <p class="text-xs text-slate-500"><?= lang('Admin.users_shred_modal_sub') ?></p>
            </div>
        </div>
        <p class="text-xs text-slate-600 mb-3 leading-relaxed">
            <?= lang('Admin.users_shred_modal_msg') ?> <strong id="deleteTargetName">Pengguna</strong>?
        </p>
        <div class="p-3 bg-amber-50 rounded-xl border border-amber-200 text-[11px] text-amber-800 space-y-1 mb-4 leading-relaxed">
            <div class="font-bold flex items-center gap-1 text-amber-900">
                <span class="material-symbols-outlined text-[16px]">info</span> <?= lang('Admin.users_shred_box_title') ?>
            </div>
            <div>&bull; <?= lang('Admin.users_shred_box_p1') ?></div>
            <div>&bull; <?= lang('Admin.users_shred_box_p2') ?></div>
        </div>
        <div class="flex items-center justify-end gap-2">
            <button type="button" onclick="closeDeleteModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                <?= lang('Admin.cancel') ?>
            </button>
            <a id="deleteConfirmBtn" href="#" class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                <span class="material-symbols-outlined text-[15px]">verified</span>
                <?= lang('Admin.users_shred_submit_btn') ?>
            </a>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- MODAL: LIHAT DETAIL USER (PROFIL, DIET, TELEMETRI & PDP) -->
<!-- ========================================================================= -->
<div id="userDetailModal" class="fixed inset-0 z-50 hidden flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity" onclick="closeUserDetailModal()"></div>
    <div class="relative bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-red-100 z-10 animate-in fade-in zoom-in-95 duration-150 max-h-[90vh] flex flex-col">
        <!-- Modal Header -->
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 shrink-0">
            <div class="flex items-center gap-3">
                <div id="detailUserAvatar" class="w-11 h-11 rounded-2xl bg-red-50 text-red-600 flex items-center justify-center font-bold text-base border border-red-100 shadow-2xs">
                    U
                </div>
                <div>
                    <div class="flex items-center gap-2">
                        <h3 class="text-base font-extrabold text-slate-900" id="detailUserName"><?= lang('Admin.loading') ?></h3>
                        <span id="detailUserBadge" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-600">
                            Status
                        </span>
                    </div>
                    <div class="flex items-center gap-2 mt-0.5">
                        <span class="text-xs text-slate-400 font-mono" id="detailUserId">UID: -</span>
                        <button type="button" onclick="copyDetailUserId()" class="text-slate-400 hover:text-red-600 transition-colors" title="UID">
                            <span class="material-symbols-outlined text-[13px]">content_copy</span>
                        </button>
                    </div>
                </div>
            </div>
            <button type="button" onclick="closeUserDetailModal()" class="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>

        <!-- Modal Body (Scrollable) -->
        <div id="userDetailLoading" class="py-12 text-center text-slate-400">
            <span class="material-symbols-outlined animate-spin text-[32px] text-red-600">sync</span>
            <div class="text-xs mt-2 font-medium"><?= lang('Admin.users_detail_loading') ?></div>
        </div>

        <div id="userDetailContent" class="hidden overflow-y-auto space-y-4 py-4 pr-1 flex-1">
            <!-- Section 1: Identitas & Kontak -->
            <div class="bg-slate-50/70 rounded-xl p-3.5 border border-slate-200/80">
                <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                    <span class="material-symbols-outlined text-[15px] text-red-600">badge</span>
                    <?= lang('Admin.users_detail_sec_identity_title') ?>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_email') ?></div>
                        <div class="font-bold text-slate-800 font-mono mt-0.5 truncate" id="detailUserEmail">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_col_contact') ?></div>
                        <div class="font-bold text-slate-800 font-mono mt-0.5" id="detailUserPhone">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_gender') ?></div>
                        <div class="font-bold text-slate-800 mt-0.5" id="detailUserGender">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_birth') ?></div>
                        <div class="font-bold text-slate-800 font-mono mt-0.5" id="detailUserBirth">-</div>
                    </div>
                </div>
            </div>

            <!-- Section 2: Preferensi Makanan & Diet AI -->
            <div class="bg-amber-50/40 rounded-xl p-3.5 border border-amber-200/70">
                <div class="text-[11px] font-bold text-amber-800 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                    <span class="material-symbols-outlined text-[15px] text-amber-600">restaurant</span>
                    <?= lang('Admin.users_detail_sec_diet_title') ?>
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
                    <div>
                        <div class="text-[10px] text-amber-700/80 font-medium"><?= lang('Admin.users_detail_halal') ?></div>
                        <div class="mt-1" id="detailUserHalal">
                            <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">Halal Only</span>
                        </div>
                    </div>
                    <div>
                        <div class="text-[10px] text-amber-700/80 font-medium"><?= lang('Admin.users_detail_diet_type') ?></div>
                        <div class="font-bold text-slate-800 mt-1 capitalize" id="detailUserDiet">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-amber-700/80 font-medium"><?= lang('Admin.users_detail_budget') ?></div>
                        <div class="font-bold text-slate-800 mt-1" id="detailUserBudget">-</div>
                    </div>
                </div>
                <div class="mt-3 pt-2.5 border-t border-amber-200/60">
                    <div class="text-[10px] text-amber-700/80 font-medium mb-1"><?= lang('Admin.users_detail_allergies') ?></div>
                    <div class="flex flex-wrap gap-1.5" id="detailUserAllergies">
                        <span class="text-slate-400 text-xs italic"><?= lang('Admin.users_detail_no_allergies') ?></span>
                    </div>
                </div>
            </div>

            <!-- Section 3: Telemetri Perangkat & Anti-Evasion -->
            <div class="bg-slate-50/70 rounded-xl p-3.5 border border-slate-200/80">
                <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                    <span class="material-symbols-outlined text-[15px] text-blue-600">devices</span>
                    <?= lang('Admin.users_detail_sec_device_title') ?>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_device_model') ?></div>
                        <div class="font-bold text-slate-800 mt-0.5 truncate" id="detailUserDevice">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_os') ?></div>
                        <div class="font-bold text-slate-800 mt-0.5" id="detailUserOs">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_app_ver') ?></div>
                        <div class="font-mono font-bold text-blue-700 mt-0.5" id="detailUserAppVersion">-</div>
                    </div>
                    <div>
                        <div class="text-[10px] text-slate-400 font-medium"><?= lang('Admin.users_detail_last_active') ?></div>
                        <div class="font-mono text-slate-700 mt-0.5 text-[11px]" id="detailUserLastActive">-</div>
                    </div>
                </div>
                <div class="mt-2.5 pt-2 border-t border-slate-200 text-[10px] text-slate-400 font-mono truncate" id="detailUserHash">
                    SHA-256 Hash: -
                </div>
            </div>

            <!-- Section 4: Koleksi Voucher -->
            <div class="bg-red-50/30 rounded-xl p-3.5 border border-red-100">
                <div class="flex items-center justify-between mb-2">
                    <div class="text-[11px] font-bold text-red-600 uppercase tracking-wider flex items-center gap-1.5">
                        <span class="material-symbols-outlined text-[15px]">confirmation_number</span>
                        <?= lang('Admin.users_detail_sec_vouchers_title') ?>
                    </div>
                    <span class="text-[11px] font-bold text-slate-500" id="detailUserVoucherCount">0</span>
                </div>
                <div id="detailUserVoucherList" class="space-y-2 mt-2"></div>
                <div id="detailUserVoucherEmpty" class="text-xs text-slate-400 italic py-2 text-center">
                    <?= lang('Admin.users_detail_no_vouchers') ?>
                </div>
            </div>
        </div>

        <!-- Modal Footer -->
        <div class="pt-3 border-t border-slate-100 shrink-0 flex items-center justify-between gap-2">
            <button type="button" onclick="closeUserDetailModal()" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                <?= lang('Admin.close') ?>
            </button>
            <div class="flex items-center gap-2">
                <button type="button" id="detailModalInjectBtn" class="px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm">
                    <span class="material-symbols-outlined text-[15px]">add_card</span>
                    <span><?= lang('Admin.users_btn_inject') ?></span>
                </button>
            </div>
        </div>
    </div>
</div>

<!-- ========================================================================= -->
<!-- JAVASCRIPT: FILTERING, MODALS & PAGINATION -->
<!-- ========================================================================= -->
<script>
    let currentFilter = '<?= esc($status ?? 'all') ?>';
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
        const btnDormant = document.getElementById('filterBtnDormant');
        const btnPending = document.getElementById('filterBtnPending');
        const btnAnon = document.getElementById('filterBtnAnon');

        const activeCls = 'text-red-600 bg-red-50 border-red-200';
        const inactiveCls = 'text-slate-600 hover:bg-slate-50 border-slate-200';

        [btnAll, btnActive, btnBanned, btnDormant, btnPending, btnAnon].forEach(b => {
            if (b) b.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + inactiveCls;
        });

        if (status === 'all' && btnAll) btnAll.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'active' && btnActive) btnActive.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'banned' && btnBanned) btnBanned.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'dormant' && btnDormant) btnDormant.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'pending_deletion' && btnPending) btnPending.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;
        if (status === 'anonymized' && btnAnon) btnAnon.className = 'px-2.5 py-1.5 rounded-lg font-semibold transition-colors border ' + activeCls;

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
    function openInjectModal(userId, userName, userEmail, isDisabled) {
        if (isDisabled) {
            alert('<?= addslashes(lang('Admin.users_inject_alert_blocked')) ?>');
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
        form.action = '<?= site_url('users/toggle-ban') ?>/' + userId;
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
            title.innerText = '<?= addslashes(lang('Admin.users_unban_modal_title')) ?>';
            subtitle.innerText = '<?= addslashes(lang('Admin.users_unban_modal_sub')) ?>';
            document.getElementById('banModalMessage').innerHTML = '<?= addslashes(lang('Admin.users_unban_modal_msg')) ?> <strong>' + userName + '</strong>?';
            reasonContainer.classList.add('hidden');
            submitBtn.className = 'px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm';
            submitBtn.innerText = '<?= addslashes(lang('Admin.users_unban_submit_btn')) ?>';
        } else {
            // Ban mode
            iconContainer.className = 'w-10 h-10 rounded-xl bg-red-50 text-red-600 flex items-center justify-center border border-red-100 shrink-0';
            iconContainer.innerHTML = '<span class="material-symbols-outlined text-[22px]">block</span>';
            title.innerText = '<?= addslashes(lang('Admin.users_ban_modal_title')) ?>';
            subtitle.innerText = '<?= addslashes(lang('Admin.users_ban_modal_sub')) ?>';
            document.getElementById('banModalMessage').innerHTML = '<?= addslashes(lang('Admin.users_ban_modal_msg')) ?> <strong>' + userName + '</strong>?';
            reasonContainer.classList.remove('hidden');
            document.getElementById('banReasonInput').value = '';
            submitBtn.className = 'px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm';
            submitBtn.innerText = '<?= addslashes(lang('Admin.users_ban_submit_btn')) ?>';
        }

        document.getElementById('banModal').classList.remove('hidden');
    }

    function closeBanModal() {
        document.getElementById('banModal').classList.add('hidden');
    }

    // Modal Delete User
    function openDeleteModal(userId, userName) {
        document.getElementById('deleteTargetName').innerText = userName;
        document.getElementById('deleteConfirmBtn').href = '<?= site_url('users/delete') ?>/' + userId;
        document.getElementById('deleteUserModal').classList.remove('hidden');
    }

    function closeDeleteModal() {
        document.getElementById('deleteUserModal').classList.add('hidden');
    }

    // Modal View User Vouchers
    async function viewUserVouchers(userId, userName) {
        const modal = document.getElementById('userVouchersModal');
        const loading = document.getElementById('userVouchersLoading');
        const content = document.getElementById('userVouchersContent');
        const list = document.getElementById('userVouchersList');
        const emptyMsg = document.getElementById('userVouchersEmpty');
        const subtitle = document.getElementById('userVouchersSubtitle');

        subtitle.innerText = '<?= addslashes(lang('Admin.users_vouchers_modal_title')) ?> - ' + userName;
        modal.classList.remove('hidden');
        loading.classList.remove('hidden');
        content.classList.add('hidden');
        list.innerHTML = '';
        emptyMsg.classList.add('hidden');

        try {
            const resp = await fetch('<?= site_url('users/vouchers') ?>/' + userId);
            const data = await resp.json();

            loading.classList.add('hidden');
            content.classList.remove('hidden');

            if (data.status === 'success' && data.vouchers && data.vouchers.length > 0) {
                data.vouchers.forEach(v => {
                    const isExpired = v.status !== 'active' || (new Date(v.expires_at) < new Date());
                    const statusBadge = !isExpired
                        ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200"><?= lang('Admin.active') ?></span>'
                        : '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-500 border border-slate-200">Expired</span>';

                    const revokeBtn = !isExpired
                        ? `<a href="<?= site_url('users/revoke-voucher') ?>/${v.id}" 
                              data-confirm="<?= addslashes(lang('Admin.users_revoke_confirm_msg')) ?>" 
                              data-confirm-title="<?= addslashes(lang('Admin.users_revoke_confirm_title')) ?>" 
                              class="px-2 py-1 rounded bg-red-50 hover:bg-red-100 text-red-600 font-bold text-[10px] border border-red-200 transition-colors">
                              <?= lang('Admin.users_vouchers_btn_revoke') ?>
                           </a>`
                        : '';

                    const item = document.createElement('div');
                    item.className = 'p-3 rounded-xl border border-slate-100 hover:border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3 text-xs';
                    item.innerHTML = `
                        <div class="min-w-0 flex-1">
                            <div class="flex items-center gap-2">
                                <span class="font-mono font-bold text-red-600">${v.voucher_code}</span>
                                ${statusBadge}
                                ${v.merchant_name ? `<span class="text-[11px] text-slate-600 font-medium">(${v.merchant_name})</span>` : ''}
                            </div>
                            <div class="text-[11px] text-slate-600 mt-0.5">${v.discount_description || '-'}</div>
                            <div class="text-[10px] text-slate-400 font-mono mt-0.5">
                                <?= lang('Admin.users_vouchers_expires') ?>: <span class="font-mono font-semibold">${new Date(v.expires_at).toLocaleString('<?= service('language')->getLocale() === 'id' ? 'id-ID' : 'en-US' ?>')}</span>
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

    // Modal Lihat Detail User
    let activeDetailUserId = null;

    async function openUserDetailModal(userId) {
        activeDetailUserId = userId;
        const modal = document.getElementById('userDetailModal');
        const loading = document.getElementById('userDetailLoading');
        const content = document.getElementById('userDetailContent');

        modal.classList.remove('hidden');
        loading.classList.remove('hidden');
        content.classList.add('hidden');

        try {
            const resp = await fetch('<?= site_url('users/detail') ?>/' + userId);
            const data = await resp.json();

            loading.classList.add('hidden');
            content.classList.remove('hidden');

            if (data.status === 'success' && data.user) {
                const u = data.user;
                const isBanned = u.effective_status === 'banned';
                const isAnonymized = u.effective_status === 'anonymized';

                // Avatar & Name
                document.getElementById('detailUserName').innerText = u.display_name || 'Pengguna';
                document.getElementById('detailUserAvatar').innerText = (u.display_name || 'U').charAt(0).toUpperCase();
                document.getElementById('detailUserId').innerText = 'UID: ' + u.id;

                // Status badge
                const badge = document.getElementById('detailUserBadge');
                if (isBanned) {
                    badge.className = 'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-700 border border-red-200';
                    badge.innerText = '<?= addslashes(lang('Admin.users_status_banned')) ?>';
                } else if (u.effective_status === 'dormant') {
                    badge.className = 'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200';
                    badge.innerText = 'Dormant';
                } else if (u.effective_status === 'pending_deletion') {
                    badge.className = 'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-purple-50 text-purple-700 border border-purple-200';
                    badge.innerText = 'Grace Period';
                } else if (isAnonymized) {
                    badge.className = 'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-200 text-slate-700 border border-slate-300';
                    badge.innerText = '<?= addslashes(lang('Admin.users_status_shredded')) ?>';
                } else {
                    badge.className = 'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200';
                    badge.innerText = '<?= addslashes(lang('Admin.users_status_active')) ?>';
                }

                // Identitas & Kontak
                document.getElementById('detailUserEmail').innerText = u.email_display || '-';
                document.getElementById('detailUserPhone').innerText = u.phone_display || '-';
                document.getElementById('detailUserGender').innerText = u.gender || '-';
                document.getElementById('detailUserBirth').innerText = u.birth_date || '-';

                // Halal & Diet
                const halalContainer = document.getElementById('detailUserHalal');
                if (u.is_halal_only) {
                    halalContainer.innerHTML = '<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">Halal Only</span>';
                } else {
                    halalContainer.innerHTML = '<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold bg-slate-100 text-slate-600 border border-slate-200"><?= service('language')->getLocale() === 'id' ? 'Fleksibel' : 'Flexible' ?></span>';
                }

                document.getElementById('detailUserDiet').innerText = (!u.dietary_type || u.dietary_type === 'none') ? '<?= service('language')->getLocale() === 'id' ? 'Bebas / Standar' : 'Standard / None' ?>' : u.dietary_type;

                const budgetMap = <?= service('language')->getLocale() === 'id' 
                    ? "{ 0: 'Fleksibel', 1: 'Hemat (< 25rb)', 2: 'Sedang (25-50rb)', 3: 'Mewah (> 50rb)' }"
                    : "{ 0: 'Flexible', 1: 'Budget (< 25k)', 2: 'Medium (25-50k)', 3: 'Premium (> 50k)' }" ?>;
                document.getElementById('detailUserBudget').innerText = budgetMap[u.budget_preference] || (u.budget_preference ? 'Tier ' + u.budget_preference : '<?= service('language')->getLocale() === 'id' ? 'Standar' : 'Standard' ?>');

                // Allergies
                const allergiesContainer = document.getElementById('detailUserAllergies');
                let allergiesList = [];
                try {
                    if (Array.isArray(u.allergies)) {
                        allergiesList = u.allergies;
                    } else if (typeof u.allergies === 'string' && u.allergies.trim()) {
                        allergiesList = JSON.parse(u.allergies);
                    }
                } catch(e) {
                    allergiesList = [];
                }

                if (allergiesList && allergiesList.length > 0) {
                    allergiesContainer.innerHTML = allergiesList.map(a => 
                        `<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">${a}</span>`
                    ).join('');
                } else {
                    allergiesContainer.innerHTML = '<span class="text-slate-400 text-xs italic"><?= addslashes(lang('Admin.users_detail_no_allergies')) ?></span>';
                }

                // Telemetri Perangkat
                document.getElementById('detailUserDevice').innerText = u.device_model || '-';
                document.getElementById('detailUserOs').innerText = u.device_os || '-';
                document.getElementById('detailUserAppVersion').innerText = u.app_version || '-';
                const userLocale = '<?= service('language')->getLocale() === 'id' ? 'id-ID' : 'en-US' ?>';
                document.getElementById('detailUserLastActive').innerText = u.last_active_at ? new Date(u.last_active_at).toLocaleString(userLocale) : (u.created_at ? new Date(u.created_at).toLocaleString(userLocale) : '-');
                document.getElementById('detailUserHash').innerText = u.email_hash ? ('Anti-Evasion SHA-256: ' + u.email_hash) : ('ID: ' + u.id);

                // Vouchers list
                const voucherList = document.getElementById('detailUserVoucherList');
                const voucherEmpty = document.getElementById('detailUserVoucherEmpty');
                const voucherCount = document.getElementById('detailUserVoucherCount');
                voucherList.innerHTML = '';

                const vouchers = data.vouchers || [];
                voucherCount.innerText = vouchers.length;

                if (vouchers.length > 0) {
                    voucherEmpty.classList.add('hidden');
                    vouchers.forEach(v => {
                        const isExp = v.status !== 'active' || (new Date(v.expires_at) < new Date());
                        const statusBadge = !isExp
                            ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200"><?= lang('Admin.active') ?></span>'
                            : '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-500 border border-slate-200">Expired</span>';

                        const revokeBtn = !isExp
                            ? `<a href="<?= site_url('users/revoke-voucher') ?>/${v.id}" 
                                  data-confirm="<?= addslashes(lang('Admin.users_revoke_confirm_msg')) ?>" 
                                  data-confirm-title="<?= addslashes(lang('Admin.users_revoke_confirm_title')) ?>" 
                                  class="px-2 py-1 rounded bg-red-50 hover:bg-red-100 text-red-600 font-bold text-[10px] border border-red-200 transition-colors">
                                  <?= lang('Admin.users_vouchers_btn_revoke') ?>
                               </a>`
                            : '';

                        const item = document.createElement('div');
                        item.className = 'p-2.5 rounded-xl border border-slate-200 bg-white flex items-center justify-between gap-3 text-xs shadow-2xs';
                        item.innerHTML = `
                            <div class="min-w-0 flex-1">
                                <div class="flex items-center gap-2">
                                    <span class="font-mono font-bold text-red-600">${v.voucher_code}</span>
                                    ${statusBadge}
                                    ${v.merchant_name ? `<span class="text-[11px] text-slate-600 font-medium">(${v.merchant_name})</span>` : ''}
                                </div>
                                <div class="text-[11px] text-slate-600 mt-0.5">${v.discount_description || '-'}</div>
                                <div class="text-[10px] text-slate-400 font-mono mt-0.5">
                                    <?= lang('Admin.users_vouchers_expires') ?>: <span class="font-mono font-semibold">${new Date(v.expires_at).toLocaleString(userLocale)}</span>
                                </div>
                            </div>
                            <div class="shrink-0">
                                ${revokeBtn}
                            </div>
                        `;
                        voucherList.appendChild(item);
                    });
                } else {
                    voucherEmpty.classList.remove('hidden');
                }

                // Modal Footer button config
                const injectBtn = document.getElementById('detailModalInjectBtn');
                injectBtn.onclick = () => {
                    closeUserDetailModal();
                    openInjectModal(u.id, u.display_name, u.email_display, isBanned || isAnonymized);
                };
                if (isBanned || isAnonymized) {
                    injectBtn.disabled = true;
                    injectBtn.className = 'px-3.5 py-2 rounded-lg bg-slate-200 text-slate-400 cursor-not-allowed text-xs font-bold flex items-center gap-1 transition-colors';
                } else {
                    injectBtn.disabled = false;
                    injectBtn.className = 'px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-sm';
                }
            } else {
                loading.classList.add('hidden');
                content.classList.remove('hidden');
                content.innerHTML = '<div class="py-8 text-center text-xs text-red-500">Failed to load user details: ' + (data.message || 'Not found') + '</div>';
            }
        } catch (e) {
            loading.classList.add('hidden');
            content.classList.remove('hidden');
            content.innerHTML = '<div class="py-8 text-center text-xs text-red-500">Error: ' + e + '</div>';
        }
    }

    function closeUserDetailModal() {
        document.getElementById('userDetailModal').classList.add('hidden');
    }

    function copyDetailUserId() {
        if (activeDetailUserId) {
            navigator.clipboard.writeText(activeDetailUserId);
            alert('<?= addslashes(lang('Admin.users_detail_copied')) ?>' + activeDetailUserId);
        }
    }

    applyFilters();
</script>

<?= $this->endSection() ?>
