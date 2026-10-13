<?php

namespace App\Controllers;

use App\Models\UserProfileModel;
use App\Models\UserVoucherModel;
use App\Models\SponsoredMerchantModel;

class Users extends BaseController
{
    protected UserProfileModel $userModel;
    protected UserVoucherModel $voucherModel;
    protected SponsoredMerchantModel $merchantModel;

    public function __construct()
    {
        $this->userModel = new UserProfileModel();
        $this->voucherModel = new UserVoucherModel();
        $this->merchantModel = new SponsoredMerchantModel();
    }

    public function index()
    {
        $search = trim($this->request->getGet('q') ?? '');
        $status = $this->request->getGet('status');

        $builder = $this->userModel->orderBy('created_at', 'DESC');

        if ($search !== '') {
            $builder->groupStart()
                ->like('display_name', $search)
                ->orLike('email', $search)
                ->orLike('phone', $search)
                ->orLike('dietary_type', $search)
                ->groupEnd();
        }

        if ($status === 'active') {
            $builder->where('is_banned', false);
        } elseif ($status === 'banned') {
            $builder->where('is_banned', true);
        }

        $users = $builder->findAll();

        // Calculate summary stats
        $totalUsers = count($users);
        $activeCount = 0;
        $bannedCount = 0;

        foreach ($users as &$u) {
            if ($u['is_banned']) {
                $bannedCount++;
            } else {
                $activeCount++;
            }

            // Count vouchers for this user
            $vouchers = $this->voucherModel->where('user_id', $u['id'])->findAll();
            $u['total_vouchers'] = count($vouchers);
            $u['active_vouchers'] = count(array_filter($vouchers, fn($v) => ($v['status'] ?? '') === 'active' && strtotime($v['expires_at'] ?? '') > time()));
        }
        unset($u);

        // Fetch active merchants for the inject voucher modal
        $merchants = $this->merchantModel->where('is_active', true)->orderBy('merchant_name', 'ASC')->findAll();

        return view('users/index', [
            'title'        => 'User Management, Ban Status & Voucher Injection',
            'active_menu'  => 'users',
            'users'        => $users,
            'merchants'    => $merchants,
            'totalUsers'   => $totalUsers,
            'activeCount'  => $activeCount,
            'bannedCount'  => $bannedCount,
            'search'       => $search,
            'status'       => $status,
        ]);
    }

    public function toggleBan(string $id)
    {
        $user = $this->userModel->find($id);
        if (!$user) {
            return redirect()->to('/users')->with('error', 'Pengguna tidak ditemukan.');
        }

        $reason = trim($this->request->getPost('reason') ?? $this->request->getGet('reason') ?? '');

        if ($user['is_banned']) {
            // Unban user
            $this->userModel->update($id, [
                'is_banned'     => 'f',
                'banned_reason' => null,
                'banned_at'     => null,
                'updated_at'    => date('Y-m-d H:i:s'),
            ]);
            return redirect()->to('/users')->with('success', 'Akun ' . esc($user['display_name']) . ' berhasil diaktifkan kembali (unbanned).');
        } else {
            // Ban user
            $banReason = $reason !== '' ? $reason : 'Dinonaktifkan / Banned oleh administrator';
            $this->userModel->update($id, [
                'is_banned'     => 't',
                'banned_reason' => $banReason,
                'banned_at'     => date('Y-m-d H:i:s'),
                'updated_at'    => date('Y-m-d H:i:s'),
            ]);
            return redirect()->to('/users')->with('success', 'Akun ' . esc($user['display_name']) . ' berhasil diblokir (banned).');
        }
    }

    public function injectVoucher()
    {
        $userId = trim($this->request->getPost('user_id') ?? '');
        $merchantId = trim($this->request->getPost('merchant_id') ?? '');
        $voucherCode = strtoupper(trim($this->request->getPost('voucher_code') ?? ''));
        $discountDesc = trim($this->request->getPost('discount_description') ?? '');
        $durationHours = (int) ($this->request->getPost('duration_hours') ?? 24);

        if ($durationHours < 1) {
            $durationHours = 24;
        }

        $user = $this->userModel->find($userId);
        if (!$user) {
            return redirect()->to('/users')->with('error', 'Pengguna penerima voucher tidak ditemukan.');
        }

        if ($user['is_banned']) {
            return redirect()->to('/users')->with('error', 'Gagal injeksi voucher: Pengguna sedang dalam status BANNED.');
        }

        // If merchant selected and no code provided, fetch merchant code & discount
        if (!empty($merchantId)) {
            $merchant = $this->merchantModel->find($merchantId);
            if ($merchant) {
                if (empty($voucherCode)) {
                    $voucherCode = $merchant['voucher_code'];
                }
                if (empty($discountDesc)) {
                    $discountDesc = $merchant['discount_description'];
                }
            }
        }

        if (empty($voucherCode)) {
            $voucherCode = 'SPECIAL' . rand(10, 99);
        }
        if (empty($discountDesc)) {
            $discountDesc = 'Diskon Spesial Injeksi Admin';
        }

        $now = date('Y-m-d H:i:s');
        $expiresAt = date('Y-m-d H:i:s', strtotime("+{$durationHours} hours"));

        $voucherId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $this->voucherModel->insert([
            'id'                   => $voucherId,
            'merchant_id'          => !empty($merchantId) ? $merchantId : null,
            'user_id'              => $userId,
            'voucher_code'         => $voucherCode,
            'status'               => 'active',
            'discount_description' => $discountDesc,
            'injected_by'          => session()->get('username') ?? 'Admin',
            'claimed_at'           => $now,
            'expires_at'           => $expiresAt,
        ]);

        return redirect()->to('/users')->with('success', 'Voucher ' . esc($voucherCode) . ' (' . esc($discountDesc) . ') berhasil diinjeksikan ke ' . esc($user['display_name']) . '! Berlaku ' . $durationHours . ' jam.');
    }

    public function userVouchers(string $userId)
    {
        $user = $this->userModel->find($userId);
        if (!$user) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Pengguna tidak ditemukan']);
        }

        $vouchers = $this->voucherModel->getUserVouchers($userId);

        return $this->response->setJSON([
            'status'   => 'success',
            'user'     => $user,
            'vouchers' => $vouchers,
        ]);
    }

    public function revokeVoucher(string $voucherId)
    {
        $voucher = $this->voucherModel->find($voucherId);
        if (!$voucher) {
            return redirect()->to('/users')->with('error', 'Voucher tidak ditemukan.');
        }

        $this->voucherModel->update($voucherId, [
            'status' => 'expired',
        ]);

        return redirect()->to('/users')->with('success', 'Voucher ' . esc($voucher['voucher_code']) . ' berhasil dicabut (expired).');
    }

    public function delete(string $id)
    {
        $user = $this->userModel->find($id);
        if (!$user) {
            return redirect()->to('/users')->with('error', 'Pengguna tidak ditemukan.');
        }

        $this->userModel->delete($id);
        return redirect()->to('/users')->with('success', 'Profil pengguna ' . esc($user['display_name']) . ' berhasil dihapus.');
    }
}
