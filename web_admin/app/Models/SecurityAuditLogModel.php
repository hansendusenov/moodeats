<?php

namespace App\Models;

use CodeIgniter\Model;

class SecurityAuditLogModel extends Model
{
    protected $table            = 'security_audit_logs';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'event_type',
        'severity',
        'actor_id',
        'actor_role',
        'target_resource',
        'action',
        'ip_address',
        'user_agent',
        'details',
        'is_suspicious',
        'created_at',
    ];

    protected $useTimestamps = false;

    /**
     * Record an audit log event
     */
    public function recordLog(array $data): string
    {
        $id = $data['id'] ?? sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $session = session();
        $request = service('request');

        $actorId = $data['actor_id'] ?? ($session ? ($session->get('username') ?? $session->get('admin_id')) : 'system');
        $actorRole = $data['actor_role'] ?? ($session ? ($session->get('role') ?? 'system') : 'system');
        $ip = $data['ip_address'] ?? ($request ? $request->getIPAddress() : '127.0.0.1');
        $ua = $data['user_agent'] ?? ($request && $request->getUserAgent() ? (string)$request->getUserAgent() : 'CLI/Agent');

        $details = $data['details'] ?? null;
        if (is_array($details)) {
            $details = json_encode($details, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        }

        $row = [
            'id'              => $id,
            'event_type'      => $data['event_type'] ?? 'security_audit',
            'severity'        => $data['severity'] ?? 'info',
            'actor_id'        => $actorId ?: 'system',
            'actor_role'      => $actorRole ?: 'system',
            'target_resource' => $data['target_resource'] ?? null,
            'action'          => $data['action'] ?? 'action',
            'ip_address'      => $ip,
            'user_agent'      => $ua,
            'details'         => $details,
            'is_suspicious'   => !empty($data['is_suspicious']) ? 't' : 'f',
            'created_at'      => $data['created_at'] ?? date('Y-m-d H:i:s'),
        ];

        $this->insert($row);
        return $id;
    }

    /**
     * Executes TTL automated purge policy for logs older than retention days (default 90)
     */
    public function purgeExpiredLogs(int $retentionDays = 90): int
    {
        try {
            $query = $this->db->query('SELECT purge_expired_audit_logs(?) as deleted_count', [$retentionDays]);
            $row = $query->getRow();
            if ($row && isset($row->deleted_count)) {
                return (int)$row->deleted_count;
            }
        } catch (\Throwable $e) {
            $days = (int)$retentionDays;
            $this->db->query("DELETE FROM security_audit_logs WHERE created_at < NOW() - INTERVAL '{$days} days'");
            return $this->db->affectedRows();
        }

        return 0;
    }
}
