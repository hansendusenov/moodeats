<?php

namespace App\Models;

use CodeIgniter\Model;

class UserProfileModel extends Model
{
    protected $table            = 'user_profiles';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'display_name',
        'email',
        'phone',
        'gender',
        'birth_date',
        'is_halal_only',
        'dietary_type',
        'allergies',
        'budget_preference',
        'is_banned',
        'banned_reason',
        'banned_at',
        'device_model',
        'device_os',
        'app_version',
        'last_active_at',
        'status',
        'deletion_requested_at',
        'grace_period_ends_at',
        'anonymized_at',
        'ban_reason',
        'email_hash',
        'device_telemetry_signature',
        'created_at',
        'updated_at',
    ];

    protected $useTimestamps = false;

    protected $afterFind = ['castBooleans'];
    protected $beforeInsert = ['prepareBooleans'];
    protected $beforeUpdate = ['prepareBooleans'];

    protected function castBooleans(array $data)
    {
        if (isset($data['data'])) {
            if ($data['singleton']) {
                if (isset($data['data']['is_banned'])) {
                    $val = $data['data']['is_banned'];
                    $data['data']['is_banned'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                }
                if (isset($data['data']['is_halal_only'])) {
                    $val = $data['data']['is_halal_only'];
                    $data['data']['is_halal_only'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                }
            } else {
                foreach ($data['data'] as &$row) {
                    if (isset($row['is_banned'])) {
                        $val = $row['is_banned'];
                        $row['is_banned'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                    }
                    if (isset($row['is_halal_only'])) {
                        $val = $row['is_halal_only'];
                        $row['is_halal_only'] = ($val === true || $val === 't' || $val === '1' || $val === 1 || $val === 'true');
                    }
                }
            }
        }
        return $data;
    }

    protected function prepareBooleans(array $data)
    {
        if (isset($data['data']['is_banned'])) {
            $val = $data['data']['is_banned'];
            $data['data']['is_banned'] = ($val === true || $val === 1 || $val === '1' || $val === 't' || $val === 'true') ? 't' : 'f';
        }
        if (isset($data['data']['is_halal_only'])) {
            $val = $data['data']['is_halal_only'];
            $data['data']['is_halal_only'] = ($val === true || $val === 1 || $val === '1' || $val === 't' || $val === 'true') ? 't' : 'f';
        }
        return $data;
    }
}
