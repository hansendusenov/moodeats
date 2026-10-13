<?php

namespace App\Controllers;

use App\Models\BannerModel;

class Banners extends BaseController
{
    protected BannerModel $bannerModel;

    public function __construct()
    {
        $this->bannerModel = new BannerModel();
    }

    public function index()
    {
        $banners = $this->bannerModel->orderBy('priority', 'ASC')->findAll();

        return view('banners/index', [
            'title'       => 'Banner & Time-Parting Ads Management',
            'active_menu' => 'banners',
            'banners'     => $banners,
        ]);
    }

    public function create()
    {
        return view('banners/create', [
            'title'       => 'Tambah Banner Iklan Baru',
            'active_menu' => 'banners',
        ]);
    }

    public function store()
    {
        $rules = [
            'title'      => 'required|min_length[3]|max_length[150]',
            'image_url'  => 'required|valid_url',
            'start_date' => 'required',
            'end_date'   => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $activeDays = $this->request->getPost('active_days') ?? [1, 2, 3, 4, 5, 6, 7];
        $pgDays = '{' . implode(',', array_map('intval', $activeDays)) . '}';

        $data = [
            'id'             => sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            ),
            'title'          => trim($this->request->getPost('title')),
            'image_url'      => trim($this->request->getPost('image_url')),
            'target_url'     => trim($this->request->getPost('target_url') ?? ''),
            'targeting_type' => $this->request->getPost('targeting_type') ?? 'global',
            'target_city'    => trim($this->request->getPost('target_city') ?? ''),
            'target_lat'     => $this->request->getPost('target_lat') ? (float) $this->request->getPost('target_lat') : null,
            'target_lng'     => $this->request->getPost('target_lng') ? (float) $this->request->getPost('target_lng') : null,
            'radius_km'      => (float) ($this->request->getPost('radius_km') ?? 5.0),
            'active_days'    => $pgDays,
            'start_hour'     => $this->request->getPost('start_hour') ?: null,
            'end_hour'       => $this->request->getPost('end_hour') ?: null,
            'priority'       => (int) ($this->request->getPost('priority') ?? 1),
            'start_date'     => $this->request->getPost('start_date'),
            'end_date'       => $this->request->getPost('end_date'),
            'is_active'      => $this->request->getPost('is_active') ? true : false,
            'created_at'     => date('Y-m-d H:i:s'),
        ];

        $this->bannerModel->insert($data);

        return redirect()->to('/banners')->with('success', 'Banner iklan berhasil disimpan.');
    }

    public function edit($id)
    {
        $banner = $this->bannerModel->find($id);
        if (!$banner) {
            return redirect()->to('/banners')->with('error', 'Banner tidak ditemukan.');
        }

        return view('banners/edit', [
            'title'       => 'Edit Banner Iklan',
            'active_menu' => 'banners',
            'banner'      => $banner,
        ]);
    }

    public function update($id)
    {
        $banner = $this->bannerModel->find($id);
        if (!$banner) {
            return redirect()->to('/banners')->with('error', 'Banner tidak ditemukan.');
        }

        $activeDays = $this->request->getPost('active_days') ?? [1, 2, 3, 4, 5, 6, 7];
        $pgDays = '{' . implode(',', array_map('intval', $activeDays)) . '}';

        $data = [
            'title'          => trim($this->request->getPost('title')),
            'image_url'      => trim($this->request->getPost('image_url')),
            'target_url'     => trim($this->request->getPost('target_url') ?? ''),
            'targeting_type' => $this->request->getPost('targeting_type') ?? 'global',
            'target_city'    => trim($this->request->getPost('target_city') ?? ''),
            'target_lat'     => $this->request->getPost('target_lat') ? (float) $this->request->getPost('target_lat') : null,
            'target_lng'     => $this->request->getPost('target_lng') ? (float) $this->request->getPost('target_lng') : null,
            'radius_km'      => (float) ($this->request->getPost('radius_km') ?? 5.0),
            'active_days'    => $pgDays,
            'start_hour'     => $this->request->getPost('start_hour') ?: null,
            'end_hour'       => $this->request->getPost('end_hour') ?: null,
            'priority'       => (int) ($this->request->getPost('priority') ?? 1),
            'start_date'     => $this->request->getPost('start_date'),
            'end_date'       => $this->request->getPost('end_date'),
            'is_active'      => $this->request->getPost('is_active') ? true : false,
        ];

        $this->bannerModel->update($id, $data);

        return redirect()->to('/banners')->with('success', 'Banner iklan berhasil diperbarui.');
    }

    public function delete($id)
    {
        $this->bannerModel->delete($id);
        return redirect()->to('/banners')->with('success', 'Banner berhasil dihapus.');
    }

    public function toggle($id)
    {
        $banner = $this->bannerModel->find($id);
        if ($banner) {
            $this->bannerModel->update($id, ['is_active' => !$banner['is_active']]);
        }
        return redirect()->to('/banners')->with('success', 'Status banner berhasil diubah.');
    }
}
