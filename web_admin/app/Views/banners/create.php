<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-3xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight"><?= esc(lang('Admin.banners_create_title')) ?></h1>
            <p class="text-xs text-slate-500"><?= esc(lang('Admin.banners_create_desc')) ?></p>
        </div>
        <a href="<?= site_url('banners') ?>" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            <?= esc(lang('Admin.back')) ?>
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="<?= site_url('banners/store') ?>" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="title"><?= esc(lang('Admin.banners_form_title')) ?></label>
                <input type="text" id="title" name="title" value="<?= old('title') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                       placeholder="e.g. Weekend Special Bento Box 20% Off" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url"><?= esc(lang('Admin.banners_form_image_url')) ?></label>
                    <input type="url" id="image_url" name="image_url" value="<?= old('image_url') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                           placeholder="https://..." />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="target_url"><?= esc(lang('Admin.banners_form_target_url')) ?></label>
                    <input type="text" id="target_url" name="target_url" value="<?= old('target_url') ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                           placeholder="https://... or moodeats://merchant/..." />
                </div>
            </div>

            <!-- Geofencing Block -->
            <div class="p-4 rounded-lg bg-red-50/40 border border-red-100 space-y-3">
                <div class="flex items-center gap-1.5 text-xs font-bold text-red-900 uppercase font-mono">
                    <span class="material-symbols-outlined text-[16px] text-red-600">location_on</span>
                    <?= esc(lang('Admin.banners_form_geofence')) ?>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="targeting_type"><?= esc(lang('Admin.banners_form_target_type')) ?></label>
                        <select id="targeting_type" name="targeting_type" class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 bg-white">
                            <option value="global">Global</option>
                            <option value="city">City</option>
                            <option value="radius">GPS Radius</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="target_city"><?= esc(lang('Admin.banners_form_target_city')) ?></label>
                        <input type="text" id="target_city" name="target_city" value="<?= old('target_city', 'Jakarta') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200" placeholder="Jakarta, Surabaya..." />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="radius_km"><?= esc(lang('Admin.banners_form_radius')) ?></label>
                        <input type="number" step="0.5" id="radius_km" name="radius_km" value="<?= old('radius_km', 5.0) ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200" />
                    </div>
                </div>
            </div>

            <!-- Time Parting Block -->
            <div class="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-3">
                <div class="flex items-center gap-1.5 text-xs font-bold text-slate-800 uppercase font-mono">
                    <span class="material-symbols-outlined text-[16px] text-amber-600">schedule</span>
                    <?= esc(lang('Admin.banners_form_time_parting')) ?>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="start_hour"><?= esc(lang('Admin.banners_form_start_hour')) ?></label>
                        <input type="time" id="start_hour" name="start_hour" value="<?= old('start_hour', '10:00') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="end_hour"><?= esc(lang('Admin.banners_form_end_hour')) ?></label>
                        <input type="time" id="end_hour" name="end_hour" value="<?= old('end_hour', '22:00') ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                </div>
            </div>

            <!-- Periode & Prioritas -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="start_date"><?= esc(lang('Admin.banners_form_start_date')) ?></label>
                    <input type="date" id="start_date" name="start_date" value="<?= old('start_date', date('Y-m-d')) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="end_date"><?= esc(lang('Admin.banners_form_end_date')) ?></label>
                    <input type="date" id="end_date" name="end_date" value="<?= old('end_date', date('Y-m-d', strtotime('+30 days'))) ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="priority"><?= esc(lang('Admin.banners_form_priority')) ?></label>
                    <input type="number" id="priority" name="priority" value="<?= old('priority', 10) ?>" min="1"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
            </div>

            <div class="flex items-center gap-2 pt-2">
                <input type="checkbox" id="is_active" name="is_active" value="1" checked
                       class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                <label for="is_active" class="text-xs font-semibold text-slate-700"><?= esc(lang('Admin.banners_form_is_active')) ?></label>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="<?= site_url('banners') ?>" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold"><?= esc(lang('Admin.cancel')) ?></a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    <?= esc(lang('Admin.save')) ?>
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
