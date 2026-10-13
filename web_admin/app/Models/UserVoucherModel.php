<?php

namespace App\Models;

use CodeIgniter\Model;

class UserVoucherModel extends Model
{
    protected $table            = 'user_vouchers';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'merchant_id',
        'user_id',
        'voucher_code',
        'status',
        'discount_description',
        'injected_by',
        'claimed_at',
        'expires_at',
    ];

    protected $useTimestamps = false;

    public function getUserVouchers(string $userId)
    {
        return $this->select('user_vouchers.*, sponsored_merchants.merchant_name, sponsored_merchants.image_url as merchant_image')
                    ->join('sponsored_merchants', 'sponsored_merchants.id = user_vouchers.merchant_id', 'left')
                    ->where('user_vouchers.user_id', $userId)
                    ->orderBy('user_vouchers.claimed_at', 'DESC')
                    ->findAll();
    }
}
