<?php

namespace App\Controllers;

use App\Models\AdminUserModel;

class Auth extends BaseController
{
    public function login()
    {
        if (session()->get('is_logged_in')) {
            return redirect()->to('/dashboard');
        }

        return view('auth/login');
    }

    public function attemptLogin()
    {
        $rules = [
            'username' => 'required',
            'password' => 'required',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('error', 'Username dan password wajib diisi.');
        }

        $username = trim($this->request->getPost('username'));
        $password = $this->request->getPost('password');

        $userModel = new AdminUserModel();
        $user = $userModel->findByUsername($username);

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return redirect()->back()->withInput()->with('error', 'Username atau password tidak valid.');
        }

        if (!$user['is_active']) {
            return redirect()->back()->with('error', 'Akun admin Anda sedang dinonaktifkan.');
        }

        // Update last login
        $userModel->update($user['id'], ['last_login_at' => date('Y-m-d H:i:s')]);

        // Set session
        session()->set([
            'admin_id'     => $user['id'],
            'username'     => $user['username'],
            'email'        => $user['email'],
            'role'         => $user['role'],
            'is_logged_in' => true,
        ]);

        return redirect()->to('/dashboard')->with('success', 'Selamat datang kembali, ' . esc($user['username']) . '!');
    }

    public function logout()
    {
        session()->destroy();
        return redirect()->to('/login')->with('success', 'Anda telah berhasil logout.');
    }
}
