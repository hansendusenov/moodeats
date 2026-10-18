<?php

namespace App\Controllers;

use App\Models\UserProfileModel;
use App\Models\UserVoucherModel;
use App\Models\SponsoredMerchantModel;
use App\Models\SecurityAuditLogModel;

class Users extends BaseController
{
    protected UserProfileModel $userModel;
    protected UserVoucherModel $voucherModel;
    protected SponsoredMerchantModel $merchantModel;
    protected SecurityAuditLogModel $auditModel;

    public function __construct()
    {
        helper(['url', 'form', 'pdp']);
        $this->userModel = new UserProfileModel();
        $this->voucherModel = new UserVoucherModel();
        $this->merchantModel = new SponsoredMerchantModel();
        $this->auditModel = new SecurityAuditLogModel();
    }

    public function index()
    {
        $session = session();
        $userRole = $session->get('role') ?? 'analyst';
        $isPrivileged = is_privileged_role($userRole);

        $search = trim($this->request->getGet('q') ?? '');
        $status = trim($this->request->getGet('status') ?? 'all');

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
            $builder->groupStart()
                ->where('status', 'active')
                ->orWhere('status IS NULL AND (is_banned = false OR is_banned IS NULL)')
                ->groupEnd();
        } elseif ($status === 'banned') {
            $builder->groupStart()
                ->where('status', 'banned')
                ->orWhere('is_banned', true)
                ->groupEnd();
        } elseif ($status === 'dormant') {
            $builder->where('status', 'dormant');
        } elseif ($status === 'pending_deletion') {
            $builder->where('status', 'pending_deletion');
        } elseif ($status === 'anonymized') {
            $builder->where('status', 'anonymized');
        }

        $users = $builder->findAll();

        // Calculate all status counts from complete database table
        $allUsers = $this->userModel->findAll();
        $totalUsers = count($allUsers);
        $activeCount = 0;
        $bannedCount = 0;
        $dormantCount = 0;
        $pendingDeletionCount = 0;
        $anonymizedCount = 0;

        foreach ($allUsers as $u) {
            $st = strtolower($u['status'] ?? '');
            if ($st === 'banned' || !empty($u['is_banned'])) {
                $bannedCount++;
            } elseif ($st === 'dormant') {
                $dormantCount++;
            } elseif ($st === 'pending_deletion') {
                $pendingDeletionCount++;
            } elseif ($st === 'anonymized') {
                $anonymizedCount++;
            } else {
                $activeCount++;
            }
        }

        // Process display data & PII masking
        foreach ($users as &$u) {
            // Count vouchers for this user
            $vouchers = $this->voucherModel->where('user_id', $u['id'])->findAll();
            $u['total_vouchers'] = count($vouchers);
            $u['active_vouchers'] = count(array_filter($vouchers, fn($v) => ($v['status'] ?? '') === 'active' && strtotime($v['expires_at'] ?? '') > time()));

            // Determine effective status badge
            $st = strtolower($u['status'] ?? '');
            if ($st === 'banned' || !empty($u['is_banned'])) {
                $u['effective_status'] = 'banned';
            } elseif ($st === 'dormant') {
                $u['effective_status'] = 'dormant';
            } elseif ($st === 'pending_deletion') {
                $u['effective_status'] = 'pending_deletion';
            } elseif ($st === 'anonymized') {
                $u['effective_status'] = 'anonymized';
            } else {
                $u['effective_status'] = 'active';
            }

            // PII Masking under UU PDP
            $u['email_display'] = mask_email($u['email'] ?? '', false);
            $u['phone_display'] = mask_phone($u['phone'] ?? '', false);
        }
        unset($u);

        // Fetch active merchants for the inject voucher modal
        $merchants = $this->merchantModel->where('is_active', true)->orderBy('merchant_name', 'ASC')->findAll();

        return view('users/index', [
            'title'                => 'User Management, Ban Status & UU PDP Lifecycle',
            'active_menu'          => 'users',
            'users'                => $users,
            'merchants'            => $merchants,
            'isPrivileged'         => $isPrivileged,
            'currentRole'          => $userRole,
            'totalUsers'           => $totalUsers,
            'activeCount'          => $activeCount,
            'bannedCount'          => $bannedCount,
            'dormantCount'         => $dormantCount,
            'pendingDeletionCount' => $pendingDeletionCount,
            'anonymizedCount'      => $anonymizedCount,
            'search'               => $search,
            'status'               => $status,
        ]);
    }

    public function toggleBan(string $id)
    {
        $user = $this->userModel->find($id);
        if (!$user) {
            return redirect()->to(site_url('users'))->with('error', 'Pengguna tidak ditemukan.');
        }

        $reason = trim($this->request->getPost('reason') ?? $this->request->getGet('reason') ?? '');
        $isCurrentlyBanned = !empty($user['is_banned']) || ($user['status'] ?? '') === 'banned';

        if ($isCurrentlyBanned) {
            // Unban user
            $this->userModel->update($id, [
                'is_banned'     => 'f',
                'status'        => 'active',
                'banned_reason' => null,
                'ban_reason'    => null,
                'banned_at'     => null,
                'updated_at'    => date('Y-m-d H:i:s'),
            ]);

            $this->auditModel->recordLog([
                'event_type'      => 'security_incident',
                'severity'        => 'info',
                'target_resource' => 'user_profiles:' . $id,
                'action'          => 'unban_user',
                'details'         => [
                    'unbanned_by'   => session()->get('username') ?? 'admin',
                    'target_user'   => $user['email'] ?? $id,
                ],
                'is_suspicious'   => false,
            ]);

            return redirect()->to(site_url('users'))->with('success', 'Akun ' . esc($user['display_name']) . ' berhasil diaktifkan kembali (unbanned).');
        } else {
            // Ban user: compute SHA-256 hash & telemetry signature to prevent ban evasion
            $banReason = $reason !== '' ? $reason : 'Dinonaktifkan / Banned oleh administrator';
            $emailHash = hash('sha256', strtolower(trim($user['email'] ?? '')));
            $deviceModel = $user['device_model'] ?? 'mobile';
            $deviceOs = $user['device_os'] ?? 'os';
            $deviceSig = hash('sha256', "{$deviceModel}|{$deviceOs}|{$id}");

            $this->userModel->update($id, [
                'is_banned'                  => 't',
                'status'                     => 'banned',
                'banned_reason'              => $banReason,
                'ban_reason'                 => $banReason,
                'banned_at'                  => date('Y-m-d H:i:s'),
                'email_hash'                 => $emailHash,
                'device_telemetry_signature' => $deviceSig,
                'updated_at'                 => date('Y-m-d H:i:s'),
            ]);

            $this->auditModel->recordLog([
                'event_type'      => 'security_incident',
                'severity'        => 'critical',
                'target_resource' => 'user_profiles:' . $id,
                'action'          => 'ban_user',
                'details'         => [
                    'ban_reason'     => $banReason,
                    'email_hash'     => $emailHash,
                    'telemetry_sig'  => $deviceSig,
                    'banned_by'      => session()->get('username') ?? 'admin',
                ],
                'is_suspicious'   => true,
            ]);

            return redirect()->to(site_url('users'))->with('success', 'Akun ' . esc($user['display_name']) . ' berhasil diblokir (banned). Hash identitas diamankan untuk anti-evasion.');
        }
    }

    /**
     * Crypto-shred user data according to UU PDP No. 27/2022 (Right to Erasure)
     * Preserves merchant analytics aggregates by unlinking mood sessions (user_id = NULL)
     */
    public function cryptoShred(string $id)
    {
        $user = $this->userModel->find($id);
        if (!$user) {
            return redirect()->to(site_url('users'))->with('error', 'Pengguna tidak ditemukan.');
        }

        // BANNED accounts are strictly non-anonymizable to prevent evasion
        if (!empty($user['is_banned']) || ($user['status'] ?? '') === 'banned') {
            return redirect()->to(site_url('users'))->with('error', 'Akun berstatus BANNED tidak dapat dihapus/dianonimkan demi audit anti-fraud & pencegahan ban evasion (UU PDP No. 27/2022).');
        }

        // 1. Unlink sessions to preserve merchant aggregates
        $db = \Config\Database::connect();
        $db->table('mood_sessions')
            ->where('user_id', $id)
            ->set(['user_id' => null, 'is_unlinked' => 't'])
            ->update();

        // 2. Anonymize user profile
        $anonymizedEmail = 'shredded_' . substr(md5($id), 0, 8) . '@anonymized.local';
        $this->userModel->update($id, [
            'display_name'               => 'Anonim (PDP-Shredded)',
            'email'                      => $anonymizedEmail,
            'phone'                      => null,
            'birth_date'                 => null,
            'gender'                     => null,
            'device_model'               => null,
            'device_os'                  => null,
            'app_version'                => null,
            'dietary_type'               => null,
            'allergies'                  => null,
            'budget_preference'          => null,
            'status'                     => 'anonymized',
            'anonymized_at'              => date('Y-m-d H:i:s'),
            'updated_at'                 => date('Y-m-d H:i:s'),
        ]);

        // 3. Log audit trail
        $this->auditModel->recordLog([
            'event_type'      => 'subject_rights',
            'severity'        => 'warning',
            'target_resource' => 'user_profiles:' . $id,
            'action'          => 'crypto_shred_user',
            'details'         => [
                'action'             => 'right_to_erasure',
                'unlinked_sessions'  => true,
                'executed_by'        => session()->get('username') ?? 'admin',
            ],
            'is_suspicious'   => false,
        ]);

        return redirect()->to(site_url('users'))->with('success', 'Akun ' . esc($user['display_name']) . ' berhasil dianonimkan (crypto-shredded) sesuai UU PDP No. 27/2022. Sesi analitik merchant telah di-unlink tanpa merusak metrik agregat mitra.');
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
            return redirect()->to(site_url('users'))->with('error', 'Pengguna penerima voucher tidak ditemukan.');
        }

        if (!empty($user['is_banned']) || ($user['status'] ?? '') === 'banned') {
            return redirect()->to(site_url('users'))->with('error', 'Gagal injeksi voucher: Pengguna sedang dalam status BANNED.');
        }

        if (($user['status'] ?? '') === 'anonymized') {
            return redirect()->to(site_url('users'))->with('error', 'Gagal injeksi voucher: Profil pengguna telah dianonimkan.');
        }

        if ($merchantId !== '') {
            $merchant = $this->merchantModel->find($merchantId);
            if ($merchant) {
                if (empty($voucherCode)) {
                    $voucherCode = $merchant['voucher_code'];
                }
                if (empty($discountDesc)) {
                    $discountDesc = $merchant['discount_description'];
                }
            } else {
                $merchantId = null;
            }
        } else {
            $merchantId = null;
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

        try {
            $this->voucherModel->insert([
                'id'                   => $voucherId,
                'merchant_id'          => $merchantId,
                'user_id'              => $userId,
                'voucher_code'         => $voucherCode,
                'status'               => 'active',
                'discount_description' => $discountDesc,
                'injected_by'          => session()->get('username') ?? 'Admin',
                'claimed_at'           => $now,
                'expires_at'           => $expiresAt,
            ]);

            // Audit log
            $this->auditModel->recordLog([
                'event_type'      => 'voucher_injection',
                'severity'        => 'info',
                'target_resource' => 'user_vouchers:' . $voucherId,
                'action'          => 'inject_voucher',
                'details'         => [
                    'voucher_code' => $voucherCode,
                    'target_user'  => $user['email'] ?? $userId,
                    'injected_by'  => session()->get('username') ?? 'Admin',
                    'expires_at'   => $expiresAt,
                ],
                'is_suspicious'   => false,
            ]);

            return redirect()->to(site_url('users'))->with('success', 'Voucher ' . esc($voucherCode) . ' (' . esc($discountDesc) . ') berhasil diinjeksikan ke ' . esc($user['display_name']) . '! Berlaku ' . $durationHours . ' jam.');
        } catch (\Throwable $e) {
            log_message('error', 'Gagal injeksi voucher: ' . $e->getMessage());
            return redirect()->to(site_url('users'))->with('error', 'Gagal injeksi voucher: ' . $e->getMessage());
        }
    }

    public function userVouchers(string $userId)
    {
        $user = $this->userModel->find($userId);
        if (!$user) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Pengguna tidak ditemukan']);
        }

        $session = session();
        $userRole = $session->get('role') ?? 'analyst';
        $isPrivileged = is_privileged_role($userRole);

        $user['email_display'] = mask_email($user['email'] ?? '', false);
        $user['phone_display'] = mask_phone($user['phone'] ?? '', false);

        $vouchers = $this->voucherModel->getUserVouchers($userId);

        return $this->response->setJSON([
            'status'       => 'success',
            'user'         => $user,
            'isPrivileged' => $isPrivileged,
            'vouchers'     => $vouchers,
        ]);
    }

    public function detail(string $userId)
    {
        $user = $this->userModel->find($userId);
        if (!$user) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Pengguna tidak ditemukan']);
        }

        $session = session();
        $userRole = $session->get('role') ?? 'analyst';
        $isPrivileged = is_privileged_role($userRole);

        $user['email_display'] = mask_email($user['email'] ?? '', false);
        $user['phone_display'] = mask_phone($user['phone'] ?? '', false);

        // Effective status
        $st = strtolower($user['status'] ?? '');
        if ($st === 'banned' || !empty($user['is_banned'])) {
            $user['effective_status'] = 'banned';
        } elseif ($st === 'dormant') {
            $user['effective_status'] = 'dormant';
        } elseif ($st === 'pending_deletion') {
            $user['effective_status'] = 'pending_deletion';
        } elseif ($st === 'anonymized') {
            $user['effective_status'] = 'anonymized';
        } else {
            $user['effective_status'] = 'active';
        }

        $vouchers = $this->voucherModel->getUserVouchers($userId);

        return $this->response->setJSON([
            'status'       => 'success',
            'user'         => $user,
            'isPrivileged' => $isPrivileged,
            'vouchers'     => $vouchers,
        ]);
    }

    public function revokeVoucher(string $voucherId)
    {
        $voucher = $this->voucherModel->find($voucherId);
        if (!$voucher) {
            return redirect()->to(site_url('users'))->with('error', 'Voucher tidak ditemukan.');
        }

        $this->voucherModel->update($voucherId, [
            'status' => 'expired',
        ]);

        return redirect()->to(site_url('users'))->with('success', 'Voucher ' . esc($voucher['voucher_code']) . ' berhasil dicabut (expired).');
    }

    public function delete(string $id)
    {
        return $this->cryptoShred($id);
    }
}
