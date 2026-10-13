<?php

namespace App\Controllers;

use App\Models\DefaultMenuModel;
use Ramsey\Uuid\Uuid;

class Menus extends BaseController
{
    protected DefaultMenuModel $menuModel;

    public function __construct()
    {
        $this->menuModel = new DefaultMenuModel();
    }

    public function index()
    {
        $menus = $this->menuModel->orderBy('display_order', 'ASC')->findAll();

        return view('menus/index', [
            'title'       => 'Default Curated Menus',
            'active_menu' => 'menus',
            'menus'       => $menus,
        ]);
    }

    public function create()
    {
        return view('menus/create', [
            'title'       => 'Tambah Menu Kurasi Baru',
            'active_menu' => 'menus',
        ]);
    }

    public function store()
    {
        $rules = [
            'food_name' => 'required|min_length[3]|max_length[150]',
            'category'  => 'required|max_length[100]',
            'image_url' => 'required|valid_url',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        // Generate UUID v4 for PostgreSQL PRIMARY KEY
        $data = [
            'id'            => sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            ),
            'food_name'     => trim($this->request->getPost('food_name')),
            'category'      => trim($this->request->getPost('category')),
            'image_url'     => trim($this->request->getPost('image_url')),
            'price_est'     => trim($this->request->getPost('price_est') ?? ''),
            'description'   => trim($this->request->getPost('description') ?? ''),
            'is_active'     => $this->request->getPost('is_active') ? true : false,
            'display_order' => (int) ($this->request->getPost('display_order') ?? 0),
            'created_at'    => date('Y-m-d H:i:s'),
        ];

        $this->menuModel->insert($data);

        return redirect()->to('/menus')->with('success', 'Menu kurasi berhasil ditambahkan.');
    }

    public function edit($id)
    {
        $menu = $this->menuModel->find($id);
        if (!$menu) {
            return redirect()->to('/menus')->with('error', 'Menu tidak ditemukan.');
        }

        return view('menus/edit', [
            'title'       => 'Edit Menu Kurasi',
            'active_menu' => 'menus',
            'menu'        => $menu,
        ]);
    }

    public function update($id)
    {
        $menu = $this->menuModel->find($id);
        if (!$menu) {
            return redirect()->to('/menus')->with('error', 'Menu tidak ditemukan.');
        }

        $rules = [
            'food_name' => 'required|min_length[3]|max_length[150]',
            'category'  => 'required|max_length[100]',
            'image_url' => 'required|valid_url',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $data = [
            'food_name'     => trim($this->request->getPost('food_name')),
            'category'      => trim($this->request->getPost('category')),
            'image_url'     => trim($this->request->getPost('image_url')),
            'price_est'     => trim($this->request->getPost('price_est') ?? ''),
            'description'   => trim($this->request->getPost('description') ?? ''),
            'is_active'     => $this->request->getPost('is_active') ? true : false,
            'display_order' => (int) ($this->request->getPost('display_order') ?? 0),
        ];

        $this->menuModel->update($id, $data);

        return redirect()->to('/menus')->with('success', 'Menu berhasil diperbarui.');
    }

    public function delete($id)
    {
        $this->menuModel->delete($id);
        return redirect()->to('/menus')->with('success', 'Menu berhasil dihapus.');
    }

    public function toggle($id)
    {
        $menu = $this->menuModel->find($id);
        if ($menu) {
            $this->menuModel->update($id, ['is_active' => !$menu['is_active']]);
        }
        return redirect()->to('/menus')->with('success', 'Status menu berhasil diubah.');
    }
}
