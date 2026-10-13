<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-2xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Tambah Menu Kurasi Baru</h1>
            <p class="text-xs text-slate-500">Menu ini akan ditampilkan sebagai opsi cepat pada aplikasi mobile.</p>
        </div>
        <a href="/menus" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            Kembali
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="/menus/store" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="food_name">Nama Makanan / Minuman</label>
                <input type="text" id="food_name" name="food_name" value="<?= old('food_name') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                       placeholder="Contoh: Soto Kudus Daging Sapi" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="category">Kategori Emosional</label>
                    <input type="text" id="category" name="category" value="<?= old('category') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="Contoh: Kuah Hangat, Pedas Gurih" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="price_est">Estimasi Harga</label>
                    <input type="text" id="price_est" name="price_est" value="<?= old('price_est') ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="Contoh: Rp 25.000" />
                </div>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url">URL Gambar Menu</label>
                <input type="url" id="image_url" name="image_url" value="<?= old('image_url') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500 font-mono text-xs"
                       placeholder="https://images.unsplash.com/..." />
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="description">Deskripsi Singkat / Efek Mood</label>
                <textarea id="description" name="description" rows="3"
                          class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                          placeholder="Penjelasan mengapa makanan ini cocok untuk menghangatkan atau menyegarkan suasana hati..."><?= old('description') ?></textarea>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-center pt-2">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="display_order">Urutan Tampilan</label>
                    <input type="number" id="display_order" name="display_order" value="<?= old('display_order', 1) ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500" />
                </div>
                <div class="flex items-center gap-2 pt-5">
                    <input type="checkbox" id="is_active" name="is_active" value="1" checked
                           class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                    <label for="is_active" class="text-xs font-semibold text-slate-700">Langsung Aktifkan di Mobile App</label>
                </div>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="/menus" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold">Batal</a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    Simpan Menu
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
