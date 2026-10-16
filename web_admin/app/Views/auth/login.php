<!DOCTYPE html>
<html class="light" lang="id">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <title>Login - MoodEats Web Admin Console</title>
    <link rel="icon" type="image/png" href="/assets/images/moodeats_mascot.png"/>
    <link rel="shortcut icon" type="image/x-icon" href="/favicon.ico"/>
    <link href="https://fonts.googleapis.com" rel="preconnect"/>
    <link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
    <script src="https://cdn.tailwindcss.com?plugins=forms"></script>
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
    </style>
</head>
<body class="bg-gradient-to-br from-slate-50 via-red-50/20 to-slate-100 min-h-screen flex items-center justify-center p-4">

<div class="w-full max-w-md">
    <!-- Brand Header -->
    <div class="text-center mb-8">
        <img src="/assets/images/moodeats_mascot.png" class="w-20 h-20 mx-auto mb-2 object-contain drop-shadow-md" alt="MoodEats Mascot"/>
        <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">MoodEats Admin</h1>
        <p class="text-xs text-slate-500 mt-1 uppercase tracking-wider font-mono">Autonomous Culinary Engine Console</p>
    </div>

    <!-- Login Card -->
    <div class="bg-white rounded-2xl p-8 border border-red-100 shadow-xl shadow-slate-200/50">
        <h2 class="text-lg font-bold text-slate-900 mb-1">Masuk ke Backoffice</h2>
        <p class="text-xs text-slate-500 mb-6">Gunakan akun admin terdaftar untuk mengelola kampanye dan menu.</p>

        <?php if (session()->getFlashdata('error')): ?>
            <div class="mb-4 flex items-center gap-2 p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-xs">
                <span class="material-symbols-outlined text-[18px]">error</span>
                <span><?= esc(session()->getFlashdata('error')) ?></span>
            </div>
        <?php endif; ?>

        <?php if (session()->getFlashdata('success')): ?>
            <div class="mb-4 flex items-center gap-2 p-3 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs">
                <span class="material-symbols-outlined text-[18px]">check_circle</span>
                <span><?= esc(session()->getFlashdata('success')) ?></span>
            </div>
        <?php endif; ?>

        <form action="/login" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5" for="username">Username</label>
                <div class="relative">
                    <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-[18px]">person</span>
                    <input type="text" id="username" name="username" value="<?= old('username', 'superadmin') ?>" required
                           class="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-slate-200 bg-slate-50/50 focus:bg-white focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors"
                           placeholder="superadmin" />
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5" for="password">Password</label>
                <div class="relative">
                    <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-[18px]">lock</span>
                    <input type="password" id="password" name="password" required
                           class="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-slate-200 bg-slate-50/50 focus:bg-white focus:border-red-500 focus:ring-1 focus:ring-red-500 transition-colors"
                           placeholder="••••••••••••" />
                </div>
                <p class="text-[11px] text-slate-400 mt-1 font-mono">Akun default: superadmin / MoodEats@2026</p>
            </div>

            <button type="submit"
                    class="w-full mt-2 py-2.5 px-4 rounded-lg bg-red-600 hover:bg-red-700 text-white font-bold text-sm tracking-tight shadow-md shadow-red-200 transition-all flex items-center justify-center gap-2">
                <span>Masuk Sekarang</span>
                <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
            </button>
        </form>
    </div>

    <!-- Security notice -->
    <div class="mt-6 text-center text-xs text-slate-400 flex items-center justify-center gap-1.5">
        <span class="material-symbols-outlined text-[16px] text-slate-400">lock_open</span>
        <span>Koneksi aman ke PostgreSQL Supabase via TLS</span>
    </div>
</div>

</body>
</html>
