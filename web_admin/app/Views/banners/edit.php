<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-3xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Edit Kampanye Banner Iklan</h1>
            <p class="text-xs text-slate-500">Perbarui jadwal, sasaran lokasi, atau status banner.</p>
        </div>
        <a href="/banners" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            Kembali
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="/banners/update/<?= $banner['id'] ?>" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="title">Judul Banner / Nama Kampanye</label>
                <input type="text" id="title" name="title" value="<?= old('title', $banner['title']) ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url">URL Gambar Banner</label>
                    <input type="url" id="image_url" name="image_url" value="<?= old('image_url', $banner['image_url']) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="target_url">Target URL / Deep Link</label>
                    <input type="text" id="target_url" name="target_url" value="<?= old('target_url', $banner['target_url']) ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs" />
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
                            <option value="global" <?= $banner['targeting_type'] === 'global' ? 'selected' : '' ?>>Global (Semua Area)</option>
                            <option value="city" <?= $banner['targeting_type'] === 'city' ? 'selected' : '' ?>>Spesifik Kota</option>
                            <option value="radius" <?= $banner['targeting_type'] === 'radius' ? 'selected' : '' ?>>Radius GPS Sekitar Merchant</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="target_city">Kota Sasaran</label>
                        <input type="text" id="target_city" name="target_city" value="<?= old('target_city', $banner['target_city']) ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="radius_km">Radius Maksimal (KM)</label>
                        <input type="number" step="0.5" id="radius_km" name="radius_km" value="<?= old('radius_km', $banner['radius_km']) ?>"
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
                        <input type="time" id="start_hour" name="start_hour" value="<?= old('start_hour', $banner['start_hour'] ? substr($banner['start_hour'], 0, 5) : '') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="end_hour">Jam Berakhir Tayang</label>
                        <input type="time" id="end_hour" name="end_hour" value="<?= old('end_hour', $banner['end_hour'] ? substr($banner['end_hour'], 0, 5) : '') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                </div>
            </div>

            <!-- Periode & Prioritas -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="start_date">Mulai Tayang</label>
                    <input type="date" id="start_date" name="start_date" value="<?= old('start_date', date('Y-m-d', strtotime($banner['start_date']))) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="end_date">Selesai Tayang</label>
                    <input type="date" id="end_date" name="end_date" value="<?= old('end_date', date('Y-m-d', strtotime($banner['end_date']))) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="priority">Prioritas</label>
                    <input type="number" id="priority" name="priority" value="<?= old('priority', $banner['priority']) ?>" min="1"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
            </div>

            <div class="flex items-center gap-2 pt-2">
                <input type="checkbox" id="is_active" name="is_active" value="1" <?= $banner['is_active'] ? 'checked' : '' ?>
                       class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                <label for="is_active" class="text-xs font-semibold text-slate-700">Aktifkan Kampanye</label>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="/banners" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold">Batal</a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    Simpan Perubahan
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
