<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-2xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight"><?= esc(lang('Admin.menus_create_title')) ?></h1>
            <p class="text-xs text-slate-500"><?= esc(lang('Admin.menus_create_desc')) ?></p>
        </div>
        <a href="<?= site_url('menus') ?>" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            <?= esc(lang('Admin.back')) ?>
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="<?= site_url('menus/store') ?>" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="food_name"><?= esc(lang('Admin.menus_form_name')) ?></label>
                <input type="text" id="food_name" name="food_name" value="<?= old('food_name') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                       placeholder="e.g. Soto Kudus Daging Sapi" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="category"><?= esc(lang('Admin.menus_form_category')) ?></label>
                    <input type="text" id="category" name="category" value="<?= old('category') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="e.g. Warm Comfort, Savory Spicy" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="price_est"><?= esc(lang('Admin.menus_form_price')) ?></label>
                    <input type="text" id="price_est" name="price_est" value="<?= old('price_est') ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="e.g. Rp 25.000" />
                </div>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url"><?= esc(lang('Admin.menus_form_image_url')) ?></label>
                <input type="url" id="image_url" name="image_url" value="<?= old('image_url') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                       placeholder="https://images.unsplash.com/..." />
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="description"><?= esc(lang('Admin.menus_form_desc')) ?></label>
                <textarea id="description" name="description" rows="3"
                          class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                          placeholder="Why this food is recommended for this emotional mood..."><?= old('description') ?></textarea>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-center pt-2">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="display_order">Display Priority</label>
                    <input type="number" id="display_order" name="display_order" value="<?= old('display_order', 1) ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500" />
                </div>
                <div class="flex items-center gap-2 pt-5">
                    <input type="checkbox" id="is_active" name="is_active" value="1" checked
                           class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                    <label for="is_active" class="text-xs font-semibold text-slate-700"><?= esc(lang('Admin.menus_form_active')) ?></label>
                </div>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="<?= site_url('menus') ?>" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold"><?= esc(lang('Admin.cancel')) ?></a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    <?= esc(lang('Admin.save')) ?>
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
