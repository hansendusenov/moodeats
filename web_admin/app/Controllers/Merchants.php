<?php

namespace App\Controllers;

use App\Models\SponsoredMerchantModel;

class Merchants extends BaseController
{
    protected SponsoredMerchantModel $merchantModel;

    public function __construct()
    {
        $this->merchantModel = new SponsoredMerchantModel();
    }

    public function index()
    {
        $search = trim($this->request->getGet('q') ?? '');
        $status = $this->request->getGet('status');

        $builder = $this->merchantModel->orderBy('priority', 'ASC');

        if ($search !== '') {
            $builder->groupStart()
                ->like('merchant_name', $search)
                ->orLike('category', $search)
                ->orLike('voucher_code', $search)
                ->orLike('discount_description', $search)
                ->orLike('address', $search)
                ->groupEnd();
        }

        if ($status === 'active') {
            $builder->where('is_active', true);
        } elseif ($status === 'inactive') {
            $builder->where('is_active', false);
        }

        $merchants = $builder->findAll();

        return view('merchants/index', [
            'title'       => 'Sponsored Merchants & Dynamic Vouchers',
            'active_menu' => 'merchants',
            'merchants'   => $merchants,
            'search'      => $search,
            'status'      => $status,
        ]);
    }

    public function bulkAction()
    {
        $action = $this->request->getPost('action');
        $ids = $this->request->getPost('ids');

        if (empty($ids) || !is_array($ids)) {
            return redirect()->to('/merchants')->with('error', 'Pilih minimal satu mitra untuk melakukan aksi massal.');
        }

        if ($action === 'disable') {
            foreach ($ids as $id) {
                $this->merchantModel->update($id, ['is_active' => 'f']);
            }
            return redirect()->to('/merchants')->with('success', count($ids) . ' mitra berhasil dinonaktifkan.');
        } elseif ($action === 'enable') {
            foreach ($ids as $id) {
                $this->merchantModel->update($id, ['is_active' => 't']);
            }
            return redirect()->to('/merchants')->with('success', count($ids) . ' mitra berhasil diaktifkan.');
        } elseif ($action === 'delete') {
            foreach ($ids as $id) {
                $this->merchantModel->delete($id);
            }
            return redirect()->to('/merchants')->with('success', count($ids) . ' mitra berhasil dihapus.');
        }

        return redirect()->to('/merchants')->with('error', 'Aksi tidak valid.');
    }

    public function create()
    {
        return view('merchants/create', [
            'title'       => 'Tambah Restoran Mitra & Voucher Baru',
            'active_menu' => 'merchants',
        ]);
    }

    public function store()
    {
        $rules = [
            'merchant_name'        => 'required|min_length[3]|max_length[150]',
            'category'             => 'required',
            'address'              => 'required',
            'voucher_code'         => 'required|max_length[50]',
            'discount_description' => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $data = [
            'id'                   => sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            ),
            'merchant_name'        => trim($this->request->getPost('merchant_name')),
            'category'             => trim($this->request->getPost('category')),
            'address'              => trim($this->request->getPost('address')),
            'lat'                  => (float) ($this->request->getPost('lat') ?? -6.2088),
            'lng'                  => (float) ($this->request->getPost('lng') ?? 106.8456),
            'image_url'            => trim($this->request->getPost('image_url') ?? ''),
            'promo_badge'          => trim($this->request->getPost('promo_badge') ?? 'PROMO EKSKLUSIF'),
            'voucher_code'         => strtoupper(trim($this->request->getPost('voucher_code'))),
            'discount_description' => trim($this->request->getPost('discount_description')),
            'voucher_type'         => $this->request->getPost('voucher_type') ?? 'timer',
            'countdown_minutes'    => (int) ($this->request->getPost('countdown_minutes') ?? 15),
            'max_claim_quota'      => (int) ($this->request->getPost('max_claim_quota') ?? 100),
            'claimed_count'        => 0,
            'affiliate_url'        => trim($this->request->getPost('affiliate_url') ?? ''),
            'is_active'            => !empty($this->request->getPost('is_active')) ? 't' : 'f',
            'priority'             => (int) ($this->request->getPost('priority') ?? 1),
            'created_at'           => date('Y-m-d H:i:s'),
        ];

        $this->merchantModel->insert($data);

        return redirect()->to('/merchants')->with('success', 'Mitra restoran dan voucher berhasil disimpan.');
    }

    public function edit($id)
    {
        $merchant = $this->merchantModel->find($id);
        if (!$merchant) {
            return redirect()->to('/merchants')->with('error', 'Mitra tidak ditemukan.');
        }

        return view('merchants/edit', [
            'title'       => 'Edit Restoran Mitra & Voucher',
            'active_menu' => 'merchants',
            'merchant'    => $merchant,
        ]);
    }

    public function update($id)
    {
        $merchant = $this->merchantModel->find($id);
        if (!$merchant) {
            return redirect()->to('/merchants')->with('error', 'Mitra tidak ditemukan.');
        }

        $data = [
            'merchant_name'        => trim($this->request->getPost('merchant_name')),
            'category'             => trim($this->request->getPost('category')),
            'address'              => trim($this->request->getPost('address')),
            'lat'                  => (float) ($this->request->getPost('lat') ?? -6.2088),
            'lng'                  => (float) ($this->request->getPost('lng') ?? 106.8456),
            'image_url'            => trim($this->request->getPost('image_url') ?? ''),
            'promo_badge'          => trim($this->request->getPost('promo_badge') ?? 'PROMO EKSKLUSIF'),
            'voucher_code'         => strtoupper(trim($this->request->getPost('voucher_code'))),
            'discount_description' => trim($this->request->getPost('discount_description')),
            'voucher_type'         => $this->request->getPost('voucher_type') ?? 'timer',
            'countdown_minutes'    => (int) ($this->request->getPost('countdown_minutes') ?? 15),
            'max_claim_quota'      => (int) ($this->request->getPost('max_claim_quota') ?? 100),
            'affiliate_url'        => trim($this->request->getPost('affiliate_url') ?? ''),
            'is_active'            => !empty($this->request->getPost('is_active')) ? 't' : 'f',
            'priority'             => (int) ($this->request->getPost('priority') ?? 1),
        ];

        $this->merchantModel->update($id, $data);

        return redirect()->to('/merchants')->with('success', 'Data mitra & voucher berhasil diperbarui.');
    }

    public function delete($id)
    {
        $this->merchantModel->delete($id);
        return redirect()->to('/merchants')->with('success', 'Mitra berhasil dihapus.');
    }

    public function toggle($id)
    {
        $merchant = $this->merchantModel->find($id);
        if ($merchant) {
            $current = (!empty($merchant['is_active']) && $merchant['is_active'] !== 'f' && $merchant['is_active'] !== false);
            $this->merchantModel->update($id, ['is_active' => $current ? 'f' : 't']);
        }
        return redirect()->to('/merchants')->with('success', 'Status mitra berhasil diubah.');
    }
}
