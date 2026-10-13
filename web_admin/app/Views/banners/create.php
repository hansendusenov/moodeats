<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-3xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Buat Kampanye Banner Iklan</h1>
            <p class="text-xs text-slate-500">Pasang banner sponsor dengan filter geofencing dan penjadwalan waktu tayang.</p>
        </div>
        <a href="/banners" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            Kembali
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="/banners/store" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="title">Judul Banner / Nama Kampanye</label>
                <input type="text" id="title" name="title" value="<?= old('title') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                       placeholder="Contoh: Promo Spesial Weekend Soto Lamongan 20%" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url">URL Gambar Banner</label>
                    <input type="url" id="image_url" name="image_url" value="<?= old('image_url') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                           placeholder="https://..." />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="target_url">Target URL / Deep Link</label>
                    <input type="text" id="target_url" name="target_url" value="<?= old('target_url') ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                           placeholder="https://gofood.link/... atau moodeats://merchant/..." />
                </div>
            </div>

            <!-- Geofencing Block -->
            <div class="p-4 rounded-lg bg-red-50/40 border border-red-100 space-y-3">
                <div class="flex items-center gap-1.5 text-xs font-bold text-red-900 uppercase font-mono">
                    <span class="material-symbols-outlined text-[16px] text-red-600">location_on</span>
                    Targeting Geospasial
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="targeting_type">Tipe Targeting</label>
                        <select id="targeting_type" name="targeting_type" class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 bg-white">
                            <option value="global">Global (Semua Area)</option>
                            <option value="city">Spesifik Kota</option>
                            <option value="radius">Radius GPS Sekitar Merchant</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="target_city">Kota Sasaran</label>
                        <input type="text" id="target_city" name="target_city" value="<?= old('target_city', 'Jakarta') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200" placeholder="Jakarta, Surabaya..." />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="radius_km">Radius Maksimal (KM)</label>
                        <input type="number" step="0.5" id="radius_km" name="radius_km" value="<?= old('radius_km', 5.0) ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200" />
                    </div>
                </div>
            </div>

            <!-- Time Parting Block -->
            <div class="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-3">
                <div class="flex items-center gap-1.5 text-xs font-bold text-slate-800 uppercase font-mono">
                    <span class="material-symbols-outlined text-[16px] text-amber-600">schedule</span>
                    Time-Parting (Jam Tayang Harian)
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="start_hour">Jam Mulai Tayang</label>
                        <input type="time" id="start_hour" name="start_hour" value="<?= old('start_hour', '10:00') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="end_hour">Jam Berakhir Tayang</label>
                        <input type="time" id="end_hour" name="end_hour" value="<?= old('end_hour', '21:00') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                </div>
            </div>

            <!-- Periode & Prioritas -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="start_date">Mulai Tayang</label>
                    <input type="date" id="start_date" name="start_date" value="<?= old('start_date', date('Y-m-d')) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="end_date">Selesai Tayang</label>
                    <input type="date" id="end_date" name="end_date" value="<?= old('end_date', date('Y-m-d', strtotime('+30 days'))) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="priority">Prioritas (1=Tertinggi)</label>
                    <input type="number" id="priority" name="priority" value="<?= old('priority', 1) ?>" min="1"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
            </div>

            <div class="flex items-center gap-2 pt-2">
                <input type="checkbox" id="is_active" name="is_active" value="1" checked
                       class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                <label for="is_active" class="text-xs font-semibold text-slate-700">Aktifkan Kampanye Segera</label>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="/banners" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold">Batal</a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    Simpan Kampanye
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
