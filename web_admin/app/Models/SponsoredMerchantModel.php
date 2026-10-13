<?php

namespace App\Models;

use CodeIgniter\Model;

class SponsoredMerchantModel extends Model
{
    protected $table            = 'sponsored_merchants';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'merchant_name',
        'category',
        'address',
        'lat',
        'lng',
        'image_url',
        'promo_badge',
        'voucher_code',
        'discount_description',
        'voucher_type',
        'countdown_minutes',
        'max_claim_quota',
        'claimed_count',
        'affiliate_url',
        'is_active',
        'priority',
        'created_at',
    ];

    protected $useTimestamps = false;

    protected $afterFind = ['castBooleans'];
    protected $beforeInsert = ['prepareBooleans'];
    protected $beforeUpdate = ['prepareBooleans'];

    protected function castBooleans(array $data)
    {
        if (isset($data['data'])) {
            if ($data['singleton']) {
                if (isset($data['data']['is_active'])) {
                    $val = $data['data']['is_active'];
                    $data['data']['is_active'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                }
            } else {
                foreach ($data['data'] as &$row) {
                    if (isset($row['is_active'])) {
                        $val = $row['is_active'];
                        $row['is_active'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                    }
                }
            }
        }
        return $data;
    }

    protected function prepareBooleans(array $data)
    {
        if (isset($data['data']['is_active'])) {
            $val = $data['data']['is_active'];
            $data['data']['is_active'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true') ? 't' : 'f';
        }
        return $data;
    }
}
