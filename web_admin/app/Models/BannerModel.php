<?php

namespace App\Models;

use CodeIgniter\Model;

class BannerModel extends Model
{
    protected $table            = 'banners';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'title',
        'image_url',
        'target_url',
        'targeting_type',
        'target_city',
        'target_lat',
        'target_lng',
        'radius_km',
        'active_days',
        'start_hour',
        'end_hour',
        'priority',
        'start_date',
        'end_date',
        'is_active',
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
