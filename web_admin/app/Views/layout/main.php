<!DOCTYPE html>
<html class="light" lang="id">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <title><?= esc($title ?? 'MoodEats Admin Console') ?> - MoodEats Console</title>
    <link href="https://fonts.googleapis.com" rel="preconnect"/>
    <link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
    <script src="https://cdn.tailwindcss.com?plugins=forms"></script>
    <script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        primary: "#DC2626",
                        'primary-dark': "#991B1B",
                        'brand-bg': "#F8FAFC",
                    },
                    fontFamily: {
                        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
                        mono: ['"JetBrains Mono"', 'monospace'],
                    }
                }
            }
        }
    </script>
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
        .font-mono { font-family: 'JetBrains Mono', monospace; }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
            vertical-align: middle;
        }
    </style>
</head>
<body class="bg-[#F8FAFC] text-slate-900 antialiased overflow-x-hidden min-h-screen">

<!-- SideNavBar -->
<aside class="fixed top-0 left-0 h-screen w-64 z-40 bg-white border-r border-red-100 flex flex-col justify-between p-4 shadow-sm">
    <div class="flex flex-col gap-y-4">
        <!-- Brand & Node Status -->
        <div class="px-2 pt-1 pb-3 border-b border-red-50">
            <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-lg bg-red-600 flex items-center justify-center text-white shadow-sm shadow-red-200">
                    <span class="material-symbols-outlined text-[20px]">restaurant_menu</span>
                </div>
                <div>
                    <span class="text-lg font-extrabold tracking-tight text-red-600 leading-tight block">MoodEats</span>
                    <span class="text-[10px] font-mono text-slate-400 block tracking-wider uppercase">Hyperlocal AI Console</span>
                </div>
            </div>
            <div class="mt-3 flex items-center justify-between bg-red-50/60 px-2.5 py-1.5 rounded border border-red-100">
                <div class="flex items-center gap-2">
                    <span class="relative flex h-2 w-2">
                        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75"></span>
                        <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                    </span>
                    <span class="text-[11px] text-emerald-700 tracking-wide uppercase font-bold"><?= esc(session()->get('role') ?? 'Superadmin') ?></span>
                </div>
                <span class="text-[10px] text-slate-400 font-mono">SUPABASE DB</span>
            </div>
        </div>

        <!-- Navigation Links -->
        <nav class="flex flex-col gap-1">
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'dashboard' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/dashboard">
                <span class="material-symbols-outlined text-[18px]">insights</span>
                <span class="text-sm">Overview & Analytics</span>
            </a>
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'banners' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/banners">
                <span class="material-symbols-outlined text-[18px]">ad_units</span>
                <span class="text-sm">Banners & Ads</span>
            </a>
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'merchants' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/merchants">
                <span class="material-symbols-outlined text-[18px]">confirmation_number</span>
                <span class="text-sm">Mitra & Vouchers</span>
            </a>
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'users' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/users">
                <span class="material-symbols-outlined text-[18px]">group</span>
                <span class="text-sm">User &amp; Injeksi Voucher</span>
            </a>
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'menus' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/menus">
                <span class="material-symbols-outlined text-[18px]">restaurant_menu</span>
                <span class="text-sm">Default Menus</span>
            </a>
            <a class="px-3 py-2 flex items-center gap-3 transition-colors rounded <?= ($active_menu ?? '') === 'analytics' ? 'border-l-4 border-red-600 text-red-600 font-bold bg-red-50/80 shadow-xs' : 'text-slate-600 hover:text-red-600 hover:bg-red-50/40 font-medium' ?>" href="/analytics">
                <span class="material-symbols-outlined text-[18px]">psychology</span>
                <span class="text-sm">Logs &amp; AI Sessions</span>
            </a>
        </nav>
    </div>

    <!-- Bottom Sidebar Section -->
    <div class="flex flex-col gap-2 pt-3 border-t border-red-100">
        <div class="p-2.5 rounded bg-slate-50 border border-slate-200">
            <div class="flex items-center justify-between text-xs mb-1.5">
                <span class="text-slate-600 flex items-center gap-1.5">
                    <span class="material-symbols-outlined text-[14px] text-emerald-600">vital_signs</span>
                    PostgreSQL Pooler
                </span>
                <span class="text-emerald-600 font-bold font-mono">100% OK</span>
            </div>
            <div class="w-full bg-slate-200 rounded-full h-1">
                <div class="bg-emerald-500 h-1 rounded-full w-full"></div>
            </div>
            <div class="mt-2 flex items-center justify-between text-[10px] text-slate-500 font-mono">
                <span>Region</span>
                <span class="text-red-600 font-bold">ap-southeast-1</span>
            </div>
        </div>
        <div class="flex items-center justify-between px-1 py-1 text-slate-600">
            <a class="flex items-center gap-1 text-xs text-red-600 hover:text-red-700 font-medium transition-colors" href="/logout">
                <span class="material-symbols-outlined text-[16px]">logout</span>
                Logout
            </a>
            <span class="text-[10px] text-slate-400 font-mono">v1.0-prod</span>
        </div>
    </div>
</aside>

<!-- TopNavBar -->
<header class="fixed top-0 left-0 pl-64 z-30 w-full bg-white border-b border-red-100 h-14 flex items-center px-6 shadow-xs">
    <div class="flex justify-between items-center w-full">
        <!-- Geofence & Cluster Info -->
        <div class="flex items-center gap-3">
            <div class="flex items-center gap-2 px-2.5 py-1 rounded bg-red-50/70 border border-red-200 text-xs font-semibold text-red-700">
                <span class="material-symbols-outlined text-red-600 text-[16px]">location_on</span>
                <span>Jabodetabek & Kota Besar</span>
            </div>
            <div class="hidden md:flex items-center gap-2 px-2.5 py-1 rounded bg-slate-50 border border-slate-200 text-xs text-slate-600">
                <span class="relative flex h-2 w-2">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                </span>
                <span>ADK Agent: <strong class="text-slate-800 font-mono">Online (:8080)</strong></span>
            </div>
        </div>

        <!-- Trailing Profile & Actions -->
        <div class="flex items-center gap-3">
            <div class="flex items-center gap-2.5 pl-2 border-l border-slate-200">
                <div class="w-8 h-8 rounded-full bg-red-100 border border-red-300 flex items-center justify-center text-red-700 font-bold text-sm">
                    <?= esc(strtoupper(substr(session()->get('username') ?? 'A', 0, 1))) ?>
                </div>
                <div class="flex flex-col text-left">
                    <span class="text-xs font-bold text-slate-900 leading-tight"><?= esc(session()->get('username') ?? 'Admin') ?></span>
                    <span class="text-[10px] text-red-600 font-medium"><?= esc(session()->get('email') ?? 'admin@moodeats.id') ?></span>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- Main Canvas -->
<main class="pl-64 pt-14 pb-12 min-h-screen bg-[#F8FAFC]">
    <div class="p-6 max-w-7xl mx-auto space-y-6">

        <!-- Flash Messages -->
        <?php if (session()->getFlashdata('success')): ?>
            <div class="flex items-center gap-3 p-3.5 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm shadow-xs">
                <span class="material-symbols-outlined text-emerald-600 text-[20px]">check_circle</span>
                <span><?= esc(session()->getFlashdata('success')) ?></span>
            </div>
        <?php endif; ?>

        <?php if (session()->getFlashdata('error')): ?>
            <div class="flex items-center gap-3 p-3.5 rounded-lg bg-red-50 border border-red-200 text-red-800 text-sm shadow-xs">
                <span class="material-symbols-outlined text-red-600 text-[20px]">error</span>
                <span><?= esc(session()->getFlashdata('error')) ?></span>
            </div>
        <?php endif; ?>

        <?php if (session()->getFlashdata('errors')): ?>
            <div class="p-3.5 rounded-lg bg-red-50 border border-red-200 text-red-800 text-sm shadow-xs space-y-1">
                <div class="font-bold flex items-center gap-2 text-red-900">
                    <span class="material-symbols-outlined text-red-600 text-[20px]">warning</span>
                    Periksa kesalahan berikut:
                </div>
                <ul class="list-disc list-inside pl-2 text-xs">
                    <?php foreach (session()->getFlashdata('errors') as $err): ?>
                        <li><?= esc($err) ?></li>
                    <?php endforeach; ?>
                </ul>
            </div>
        <?php endif; ?>

        <!-- View Content Insertion Point -->
        <?= $this->renderSection('content') ?>

    </div>
</main>

<!-- Global Beautiful Confirmation Modal -->
<div id="globalConfirmModal" class="fixed inset-0 z-50 hidden bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 transition-opacity duration-200 opacity-0 pointer-events-none">
    <div id="globalConfirmCard" class="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-100 transform scale-95 transition-all duration-200">
        <div class="flex items-start gap-4">
            <div id="modalIconContainer" class="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-red-50 text-red-600 border border-red-100">
                <span id="modalIcon" class="material-symbols-outlined text-[26px]">warning</span>
            </div>
            <div class="flex-1">
                <h3 id="modalTitle" class="text-base font-extrabold text-slate-900 leading-tight">Konfirmasi Tindakan</h3>
                <p id="modalMessage" class="text-xs text-slate-600 mt-1.5 leading-relaxed">Apakah Anda yakin ingin melanjutkan tindakan ini?</p>
            </div>
        </div>

        <div class="mt-6 pt-4 border-t border-slate-100 flex items-center justify-end gap-2.5">
            <button type="button" id="modalCancelBtn" class="px-4 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs transition-colors shadow-2xs">
                Batal
            </button>
            <button type="button" id="modalConfirmBtn" class="px-4 py-2 rounded-xl font-bold text-xs text-white bg-red-600 hover:bg-red-700 transition-all shadow-sm flex items-center gap-1.5">
                <span id="modalConfirmIcon" class="material-symbols-outlined text-[16px]">check</span>
                <span id="modalConfirmText">Lanjutkan</span>
            </button>
        </div>
    </div>
</div>

<script>
window.showConfirmDialog = function({
    title = 'Konfirmasi Tindakan',
    message = 'Apakah Anda yakin ingin melanjutkan tindakan ini?',
    confirmText = 'Lanjutkan',
    cancelText = 'Batal',
    type = 'danger', // 'danger' | 'warning' | 'primary' | 'success'
    onConfirm = null,
    targetUrl = null,
    form = null
}) {
    const modal = document.getElementById('globalConfirmModal');
    const card = document.getElementById('globalConfirmCard');
    const titleEl = document.getElementById('modalTitle');
    const messageEl = document.getElementById('modalMessage');
    const confirmBtn = document.getElementById('modalConfirmBtn');
    const cancelBtn = document.getElementById('modalCancelBtn');
    const confirmTextEl = document.getElementById('modalConfirmText');
    const confirmIconEl = document.getElementById('modalConfirmIcon');
    const iconContainer = document.getElementById('modalIconContainer');
    const iconEl = document.getElementById('modalIcon');

    if (!modal) {
        if (confirm(message)) {
            if (typeof onConfirm === 'function') onConfirm();
            else if (targetUrl) window.location.href = targetUrl;
            else if (form) form.submit();
        }
        return;
    }

    titleEl.textContent = title;
    messageEl.textContent = message;
    confirmTextEl.textContent = confirmText;
    cancelBtn.textContent = cancelText;

    // Styling based on type
    if (type === 'danger') {
        iconContainer.className = 'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-red-50 text-red-600 border border-red-100';
        iconEl.textContent = 'delete_forever';
        confirmBtn.className = 'px-4 py-2 rounded-xl font-bold text-xs text-white bg-red-600 hover:bg-red-700 transition-all shadow-sm flex items-center gap-1.5';
        confirmIconEl.textContent = 'delete';
    } else if (type === 'warning') {
        iconContainer.className = 'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-amber-50 text-amber-600 border border-amber-100';
        iconEl.textContent = 'warning';
        confirmBtn.className = 'px-4 py-2 rounded-xl font-bold text-xs text-white bg-amber-600 hover:bg-amber-700 transition-all shadow-sm flex items-center gap-1.5';
        confirmIconEl.textContent = 'check';
    } else if (type === 'success') {
        iconContainer.className = 'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-emerald-50 text-emerald-600 border border-emerald-100';
        iconEl.textContent = 'check_circle';
        confirmBtn.className = 'px-4 py-2 rounded-xl font-bold text-xs text-white bg-emerald-600 hover:bg-emerald-700 transition-all shadow-sm flex items-center gap-1.5';
        confirmIconEl.textContent = 'done_all';
    } else {
        iconContainer.className = 'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-blue-50 text-blue-600 border border-blue-100';
        iconEl.textContent = 'info';
        confirmBtn.className = 'px-4 py-2 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 transition-all shadow-sm flex items-center gap-1.5';
        confirmIconEl.textContent = 'check';
    }

    // Open Modal
    modal.classList.remove('hidden');
    requestAnimationFrame(() => {
        modal.classList.remove('opacity-0', 'pointer-events-none');
        modal.classList.add('opacity-100');
        card.classList.remove('scale-95');
        card.classList.add('scale-100');
    });

    function closeModal() {
        modal.classList.remove('opacity-100');
        modal.classList.add('opacity-0', 'pointer-events-none');
        card.classList.remove('scale-100');
        card.classList.add('scale-95');
        setTimeout(() => {
            modal.classList.add('hidden');
        }, 200);
        document.removeEventListener('keydown', handleKey);
    }

    function handleKey(e) {
        if (e.key === 'Escape') closeModal();
    }
    document.addEventListener('keydown', handleKey);

    cancelBtn.onclick = closeModal;
    modal.onclick = (e) => {
        if (e.target === modal) closeModal();
    };

    confirmBtn.onclick = () => {
        closeModal();
        if (typeof onConfirm === 'function') {
            onConfirm();
        } else if (targetUrl) {
            window.location.href = targetUrl;
        } else if (form) {
            form.submit();
        }
    };
};

// Global interceptor for standard confirm triggers
document.addEventListener('click', function(e) {
    const trigger = e.target.closest('[data-confirm]');
    if (trigger) {
        e.preventDefault();
        const msg = trigger.getAttribute('data-confirm') || 'Apakah Anda yakin?';
        const title = trigger.getAttribute('data-confirm-title') || 'Konfirmasi Tindakan';
        const btnText = trigger.getAttribute('data-confirm-btn') || 'Ya, Lanjutkan';
        const type = trigger.getAttribute('data-confirm-type') || 'danger';
        const url = trigger.getAttribute('href');

        window.showConfirmDialog({
            title: title,
            message: msg,
            confirmText: btnText,
            type: type,
            targetUrl: url
        });
    }
});
</script>

</body>
</html>
