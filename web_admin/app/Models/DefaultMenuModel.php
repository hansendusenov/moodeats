<?php

namespace App\Models;

use CodeIgniter\Model;

class DefaultMenuModel extends Model
{
    protected $table            = 'default_menus';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'food_name',
        'category',
        'image_url',
        'price_est',
        'description',
        'is_active',
        'display_order',
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

    public function getActiveMenus()
    {
        return $this->where('is_active', 't')
                    ->orderBy('display_order', 'ASC')
                    ->findAll();
    }
}
