<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<!-- Header & RBAC Mode Status -->
<div class="flex flex-wrap items-center justify-between gap-4 mb-5">
    <div>
        <div class="flex items-center gap-2 text-xs font-mono text-slate-400 uppercase tracking-wider">
            <span>Admin Console</span>
            <span>/</span>
            <span>Keamanan &amp; Kepatuhan</span>
            <span>/</span>
            <span class="text-red-600 font-bold">Security Audit Trail</span>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 mt-1 tracking-tight flex items-center gap-3">
            Security Audit Logs &amp; Forensik Insiden
            <?php if ($isPrivileged): ?>
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-800 border border-amber-300">
                    <span class="material-symbols-outlined text-[15px] text-amber-600">admin_panel_settings</span>
                    Mode Forensik Privileged (Unmasked)
                </span>
            <?php else: ?>
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-800 border border-blue-300">
                    <span class="material-symbols-outlined text-[15px] text-blue-600">verified_user</span>
                    Mode Kepatuhan UU PDP (Masked PII)
                </span>
            <?php endif; ?>
        </h1>
        <p class="text-xs text-slate-500 mt-1 max-w-2xl">
            Pemisahan log operasional dan audit keamanan kepatuhan UU Pelindungan Data Pribadi (UU PDP No. 27/2022).
            <?php if (!$isPrivileged): ?>
                <span class="text-blue-600 font-semibold">Data identitas pribadi (email, telepon, IP address) disamarkan secara otomatis sesuai hak akses peran <?= esc(ucfirst($currentRole)) ?>.</span>
            <?php else: ?>
                <span class="text-amber-700 font-semibold">Akses tidak terbatas untuk investigasi forensik insiden dan audit keamanan.</span>
            <?php endif; ?>
        </p>
    </div>

    <!-- Actions: TTL Purge Button -->
    <div class="flex items-center gap-2">
        <?php if ($isPrivileged): ?>
            <a href="/audit-logs/purge-ttl" 
               data-confirm="Apakah Anda yakin ingin menjalankan pembersihan retensi log otomatis? Log yang berusia lebih dari <?= $retentionDays ?> hari akan dihapus permanen dari basis data sesuai kebijakan UU PDP Pasal 40."
               data-confirm-title="Jalankan Auto-Purge TTL Retensi"
               data-confirm-btn="Ya, Bersihkan Log Usang"
               data-confirm-type="warning"
               class="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold text-white bg-slate-900 hover:bg-slate-800 transition-all shadow-xs">
                <span class="material-symbols-outlined text-[17px] text-amber-400">auto_delete</span>
                Jalankan Auto-Purge TTL (<?= $retentionDays ?> Hari)
            </a>
        <?php else: ?>
            <button type="button" disabled title="Hanya Superadmin atau Security Lead yang memiliki wewenang menjalankan auto-purge retensi data."
                    class="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold text-slate-400 bg-slate-100 border border-slate-200 cursor-not-allowed">
                <span class="material-symbols-outlined text-[17px]">lock</span>
                Auto-Purge TTL (Terproteksi RBAC)
            </button>
        <?php endif; ?>
    </div>
</div>

<!-- Metrics Cards -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
    <!-- Total Logs -->
    <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Total Log Audit (Recent)</div>
            <div class="text-2xl font-black text-slate-900 mt-0.5"><?= $totalLogs ?></div>
            <div class="text-[10px] text-slate-400 mt-0.5 font-mono">Terekam di Supabase</div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-600">
            <span class="material-symbols-outlined text-[20px]">policy</span>
        </div>
    </div>

    <!-- Critical Incidents -->
    <div class="bg-white p-4 rounded-xl border <?= $criticalCount > 0 ? 'border-red-300 bg-red-50/20' : 'border-slate-200' ?> shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold <?= $criticalCount > 0 ? 'text-red-600' : 'text-slate-400' ?> uppercase tracking-wider">Insiden Kritis</div>
            <div class="text-2xl font-black <?= $criticalCount > 0 ? 'text-red-600' : 'text-slate-900' ?> mt-0.5"><?= $criticalCount ?></div>
            <div class="text-[10px] text-slate-400 mt-0.5 font-mono">Severity: CRITICAL</div>
        </div>
        <div class="w-10 h-10 rounded-xl <?= $criticalCount > 0 ? 'bg-red-50 text-red-600 border border-red-200' : 'bg-slate-50 text-slate-600 border border-slate-200' ?> flex items-center justify-center">
            <span class="material-symbols-outlined text-[20px]">dangerous</span>
        </div>
    </div>

    <!-- Suspicious Alerts -->
    <div class="bg-white p-4 rounded-xl border <?= $suspiciousCount > 0 ? 'border-amber-300 bg-amber-50/20' : 'border-slate-200' ?> shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold <?= $suspiciousCount > 0 ? 'text-amber-600' : 'text-slate-400' ?> uppercase tracking-wider">Anomali / Mencurigakan</div>
            <div class="text-2xl font-black <?= $suspiciousCount > 0 ? 'text-amber-600' : 'text-slate-900' ?> mt-0.5"><?= $suspiciousCount ?></div>
            <div class="text-[10px] text-slate-400 mt-0.5 font-mono">Security Flags</div>
        </div>
        <div class="w-10 h-10 rounded-xl <?= $suspiciousCount > 0 ? 'bg-amber-50 text-amber-600 border border-amber-200' : 'bg-slate-50 text-slate-600 border border-slate-200' ?> flex items-center justify-center">
            <span class="material-symbols-outlined text-[20px]">warning</span>
        </div>
    </div>

    <!-- Retention Policy -->
    <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
        <div>
            <div class="text-[11px] font-bold text-emerald-600 uppercase tracking-wider">Kebijakan Retensi TTL</div>
            <div class="text-2xl font-black text-slate-900 mt-0.5"><?= $retentionDays ?> <span class="text-xs font-semibold text-slate-500">Hari</span></div>
            <div class="text-[10px] text-emerald-600 mt-0.5 font-semibold">UU PDP Pasal 40 Aktif</div>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-200 flex items-center justify-center text-emerald-600">
            <span class="material-symbols-outlined text-[20px]">history_toggle_off</span>
        </div>
    </div>
</div>

<!-- Toolbar: Search & Filter -->
<div class="bg-white rounded-xl border border-slate-200 p-4 shadow-xs mb-4">
    <form method="GET" action="/audit-logs" class="flex flex-wrap items-center justify-between gap-3">
        <!-- Search -->
        <div class="relative flex-1 min-w-[260px] max-w-md">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-slate-400">search</span>
            <input type="text" name="q" value="<?= esc($search ?? '') ?>" 
                   placeholder="Cari aksi, resource, aktor, atau IP address..." 
                   class="w-full pl-9 pr-4 py-2 text-xs rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors">
        </div>

        <div class="flex items-center flex-wrap gap-2 text-xs">
            <!-- Severity Filter -->
            <select name="severity" onchange="this.form.submit()" class="px-2.5 py-1.5 rounded-lg border border-slate-200 bg-white text-slate-700 font-medium text-xs focus:ring-1 focus:ring-red-500">
                <option value="all" <?= ($severity ?? '') === 'all' || empty($severity) ? 'selected' : '' ?>>Semua Tingkat</option>
                <option value="critical" <?= ($severity ?? '') === 'critical' ? 'selected' : '' ?>>Kritis (Critical)</option>
                <option value="warning" <?= ($severity ?? '') === 'warning' ? 'selected' : '' ?>>Peringatan (Warning)</option>
                <option value="info" <?= ($severity ?? '') === 'info' ? 'selected' : '' ?>>Informasi (Info)</option>
            </select>

            <!-- Suspicious Only -->
            <label class="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-slate-200 bg-slate-50 text-slate-700 font-semibold cursor-pointer text-xs">
                <input type="checkbox" name="suspicious" value="1" <?= ($suspicious === '1' || $suspicious === 'true') ? 'checked' : '' ?> onchange="this.form.submit()" class="rounded border-slate-300 text-red-600 focus:ring-red-500">
                <span>Hanya Mencurigakan</span>
            </label>

            <!-- Reset -->
            <?php if (!empty($search) || !empty($severity) || !empty($suspicious)): ?>
                <a href="/audit-logs" class="px-2.5 py-1.5 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors font-medium">
                    Reset Filter
                </a>
            <?php endif; ?>
        </div>
    </form>
</div>

<!-- Table: Audit Trail Logs -->
<div class="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse text-xs">
            <thead>
                <tr class="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                    <th class="py-3 px-4">Waktu</th>
                    <th class="py-3 px-3 text-center">Tingkat</th>
                    <th class="py-3 px-3">Tipe &amp; Aksi</th>
                    <th class="py-3 px-3">Aktor</th>
                    <th class="py-3 px-3">Target Resource</th>
                    <th class="py-3 px-3">IP &amp; Klien</th>
                    <th class="py-3 px-4">Detail Payload (PDP)</th>
                    <th class="py-3 px-3 text-center">Anomali</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                <?php if (empty($logs)): ?>
                    <tr>
                        <td colspan="8" class="py-12 text-center text-slate-400">
                            <span class="material-symbols-outlined text-[36px] text-slate-300 block mb-2">policy</span>
                            Tidak ada log audit keamanan yang cocok dengan kriteria pencarian.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($logs as $i => $log): ?>
                        <?php
                            $sev = strtolower($log['severity'] ?? 'info');
                            $sevClass = match($sev) {
                                'critical' => 'bg-red-50 text-red-700 border-red-200 font-bold',
                                'warning'  => 'bg-amber-50 text-amber-700 border-amber-200 font-semibold',
                                default    => 'bg-blue-50 text-blue-700 border-blue-200 font-medium'
                            };
                            $isSusp = !empty($log['is_suspicious']) && ($log['is_suspicious'] === true || $log['is_suspicious'] === 't' || $log['is_suspicious'] === '1');
                        ?>
                        <tr class="hover:bg-slate-50/70 transition-colors <?= $isSusp ? 'bg-amber-50/20' : '' ?>">
                            <!-- Timestamp -->
                            <td class="py-3 px-4 whitespace-nowrap">
                                <div class="font-bold text-slate-900 font-mono text-[11px]">
                                    <?= date('d/m/Y H:i:s', strtotime($log['created_at'])) ?>
                                </div>
                                <div class="text-[10px] text-slate-400 font-mono">
                                    UUID: <?= substr($log['id'], 0, 8) ?>...
                                </div>
                            </td>

                            <!-- Severity -->
                            <td class="py-3 px-3 text-center whitespace-nowrap">
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] uppercase border <?= $sevClass ?>">
                                    <?= esc($log['severity'] ?? 'INFO') ?>
                                </span>
                            </td>

                            <!-- Event & Action -->
                            <td class="py-3 px-3">
                                <div class="font-bold text-slate-900 font-mono text-[11px]">
                                    <?= esc($log['action'] ?? '-') ?>
                                </div>
                                <div class="text-[10px] text-slate-400 uppercase tracking-wider">
                                    <?= esc($log['event_type'] ?? 'general') ?>
                                </div>
                            </td>

                            <!-- Actor -->
                            <td class="py-3 px-3 whitespace-nowrap">
                                <div class="font-bold text-slate-800 flex items-center gap-1">
                                    <span class="material-symbols-outlined text-[14px] text-slate-400">person</span>
                                    <span><?= esc($log['actor_id'] ?? 'system') ?></span>
                                </div>
                                <div class="text-[10px] text-slate-400 font-mono">
                                    Peran: <span class="font-semibold text-slate-600"><?= esc($log['actor_role'] ?? 'system') ?></span>
                                </div>
                            </td>

                            <!-- Target Resource -->
                            <td class="py-3 px-3">
                                <span class="font-mono text-[11px] text-slate-700 bg-slate-100 px-1.5 py-0.5 rounded border border-slate-200">
                                    <?= esc($log['target_resource'] ?? '-') ?>
                                </span>
                            </td>

                            <!-- IP & User Agent -->
                            <td class="py-3 px-3">
                                <div class="font-mono text-[11px] text-slate-800 flex items-center gap-1">
                                    <span class="material-symbols-outlined text-[13px] text-slate-400">lan</span>
                                    <span><?= esc($log['ip_address'] ?? '-') ?></span>
                                    <?php if (!$isPrivileged): ?>
                                        <span class="text-[9px] text-blue-600 font-sans font-bold" title="IP Address disamarkan">(Masked)</span>
                                    <?php endif; ?>
                                </div>
                                <div class="text-[10px] text-slate-400 truncate max-w-[150px]" title="<?= esc($log['user_agent'] ?? '') ?>">
                                    <?= esc($log['user_agent'] ?? '-') ?>
                                </div>
                            </td>

                            <!-- Details Payload -->
                            <td class="py-3 px-4 max-w-xs">
                                <?php if (!empty($log['details'])): ?>
                                    <div class="relative group">
                                        <pre class="text-[10px] font-mono bg-slate-900 text-emerald-400 p-2 rounded-lg overflow-x-auto max-h-20 whitespace-pre-wrap leading-tight border border-slate-800"><?= esc(is_string($log['details']) ? $log['details'] : json_encode($log['details'], JSON_PRETTY_PRINT)) ?></pre>
                                    </div>
                                <?php else: ?>
                                    <span class="text-slate-400 text-[11px] italic">Tidak ada payload</span>
                                <?php endif; ?>
                            </td>

                            <!-- Suspicious Flag -->
                            <td class="py-3 px-3 text-center whitespace-nowrap">
                                <?php if ($isSusp): ?>
                                    <span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-red-100 text-red-600 border border-red-200" title="Terdeteksi Mencurigakan / Anomali">
                                        <span class="material-symbols-outlined text-[15px]">flag</span>
                                    </span>
                                <?php else: ?>
                                    <span class="material-symbols-outlined text-[16px] text-slate-300">check</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Table Footer with Compliance Note -->
    <div class="p-3.5 bg-slate-50 border-t border-slate-200 flex flex-wrap items-center justify-between text-xs text-slate-500">
        <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[16px] text-emerald-600">verified</span>
            <span>Mematuhi UU Pelindungan Data Pribadi (UU PDP No. 27/2022) &amp; ISO/IEC 27001 Log Retention Standard.</span>
        </div>
        <div class="font-mono text-[11px] text-slate-400">
            Menampilkan <?= count($logs) ?> rekaman terbaru
        </div>
    </div>
</div>

<?= $this->endSection() ?>
