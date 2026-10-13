<?= $this->extend('layout/main') ?>

<?= $this->section('content') ?>

<div class="max-w-3xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Tambah Restoran Mitra &amp; Voucher</h1>
            <p class="text-xs text-slate-500">Daftarkan restoran sponsor untuk disuntikkan secara dinamis ke hasil rekomendasi AI.</p>
        </div>
        <a href="/merchants" class="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1">
            <span class="material-symbols-outlined text-[16px]">arrow_back</span>
            Kembali
        </a>
    </div>

    <div class="bg-white rounded-xl border border-red-100 p-6 shadow-xs">
        <form action="/merchants/store" method="post" class="space-y-4">
            <?= csrf_field() ?>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="merchant_name">Nama Restoran / Merchant</label>
                    <input type="text" id="merchant_name" name="merchant_name" value="<?= old('merchant_name') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="Contoh: Soto Kudus Blok M Wijaya" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="category">Kategori Makanan</label>
                    <input type="text" id="category" name="category" value="<?= old('category') ?>" required
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                           placeholder="Contoh: Soto, Kuah Hangat, Kopi" />
                </div>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="address">Alamat Lengkap</label>
                <input type="text" id="address" name="address" value="<?= old('address') ?>" required
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                       placeholder="Jl. Wijaya I No. 44, Kebayoran Baru, Jakarta Selatan" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="lat">Latitude GPS</label>
                    <input type="number" step="any" id="lat" name="lat" value="<?= old('lat', -6.2418) ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="lng">Longitude GPS</label>
                    <input type="number" step="any" id="lng" name="lng" value="<?= old('lng', 106.8012) ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
            </div>

            <!-- Voucher Details Block -->
            <div class="p-4 rounded-lg bg-amber-50/50 border border-amber-200 space-y-3">
                <div class="flex items-center gap-1.5 text-xs font-bold text-amber-900 uppercase font-mono">
                    <span class="material-symbols-outlined text-[16px] text-amber-600">confirmation_number</span>
                    Pengaturan Voucher Promo Dinamis (15m Timer)
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="voucher_code">Kode Promo Voucher</label>
                        <input type="text" id="voucher_code" name="voucher_code" value="<?= old('voucher_code', 'MOOD15') ?>" required
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono font-bold uppercase" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="countdown_minutes">Durasi Timer (Menit)</label>
                        <input type="number" id="countdown_minutes" name="countdown_minutes" value="<?= old('countdown_minutes', 15) ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                    <div>
                        <label class="block text-xs text-slate-600 mb-1" for="max_claim_quota">Batas Kuota Klaim</label>
                        <input type="number" id="max_claim_quota" name="max_claim_quota" value="<?= old('max_claim_quota', 100) ?>"
                               class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200 font-mono" />
                    </div>
                </div>
                <div>
                    <label class="block text-xs text-slate-600 mb-1" for="discount_description">Deskripsi Diskon Promo</label>
                    <input type="text" id="discount_description" name="discount_description" value="<?= old('discount_description') ?>" required
                           class="w-full px-2.5 py-1.5 text-xs rounded border border-slate-200"
                           placeholder="Contoh: Diskon 25% Min. Belanja Rp 40.000 berlaku 15 menit" />
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="promo_badge">Teks Badge Promo</label>
                    <input type="text" id="promo_badge" name="promo_badge" value="<?= old('promo_badge', 'REKOMENDASI SPONSOR') ?>"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200" />
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="priority">Prioritas Display</label>
                    <input type="number" id="priority" name="priority" value="<?= old('priority', 1) ?>" min="1"
                           class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs" />
                </div>
            </div>

            <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1" for="image_url">URL Foto Restoran (Opsional)</label>
                <input type="url" id="image_url" name="image_url" value="<?= old('image_url') ?>"
                       class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 font-mono text-xs"
                       placeholder="https://..." />
            </div>

            <div class="flex items-center gap-2 pt-2">
                <input type="checkbox" id="is_active" name="is_active" value="1" checked
                       class="rounded text-red-600 focus:ring-red-500 h-4 w-4 border-slate-300" />
                <label for="is_active" class="text-xs font-semibold text-slate-700">Aktifkan Mitra Restoran Sekarang</label>
            </div>

            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <a href="/merchants" class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold">Batal</a>
                <button type="submit" class="px-5 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-xs font-bold shadow-sm">
                    Simpan Mitra &amp; Voucher
                </button>
            </div>
        </form>
    </div>
</div>

<?= $this->endSection() ?>
