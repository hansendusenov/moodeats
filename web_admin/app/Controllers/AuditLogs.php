<?php

namespace App\Controllers;

use App\Models\SecurityAuditLogModel;

class AuditLogs extends BaseController
{
    protected SecurityAuditLogModel $auditModel;

    public function __construct()
    {
        $this->auditModel = new SecurityAuditLogModel();
    }

    public function index()
    {
        $session = session();
        $userRole = $session->get('role') ?? 'analyst';
        $isPrivileged = is_privileged_role($userRole);

        $severity = trim($this->request->getGet('severity') ?? '');
        $eventType = trim($this->request->getGet('event_type') ?? '');
        $search = trim($this->request->getGet('q') ?? '');
        $suspicious = $this->request->getGet('suspicious');

        $builder = $this->auditModel->orderBy('created_at', 'DESC');

        if ($severity !== '' && $severity !== 'all') {
            $builder->where('severity', strtolower($severity));
        }

        if ($eventType !== '' && $eventType !== 'all') {
            $builder->where('event_type', $eventType);
        }

        if ($suspicious === '1' || $suspicious === 'true') {
            $builder->where('is_suspicious', true);
        }

        if ($search !== '') {
            $builder->groupStart()
                ->like('action', $search)
                ->orLike('target_resource', $search)
                ->orLike('actor_id', $search)
                ->orLike('ip_address', $search)
                ->groupEnd();
        }

        $rawLogs = $builder->findAll(200);

        // Calculate summary counters
        $totalLogs = count($rawLogs);
        $criticalCount = 0;
        $suspiciousCount = 0;
        $retentionDays = 90;

        foreach ($rawLogs as $log) {
            if (($log['severity'] ?? '') === 'critical') {
                $criticalCount++;
            }
            if (!empty($log['is_suspicious']) && ($log['is_suspicious'] === true || $log['is_suspicious'] === 't' || $log['is_suspicious'] === '1')) {
                $suspiciousCount++;
            }
        }

        // Apply RBAC Masking if not privileged
        $processedLogs = [];
        foreach ($rawLogs as $log) {
            $row = $log;
            if (!$isPrivileged) {
                // Mask IP
                $row['ip_address'] = mask_ip($log['ip_address'] ?? '');
                // Mask actor
                $row['actor_id'] = mask_name($log['actor_id'] ?? '');
                // Mask sensitive keys in details
                if (!empty($row['details'])) {
                    $row['details'] = mask_details($row['details'], true);
                }
            }
            $processedLogs[] = $row;
        }

        return view('audit_logs/index', [
            'title'           => 'Security Audit Logs & UU PDP Compliance',
            'active_menu'     => 'audit_logs',
            'logs'            => $processedLogs,
            'isPrivileged'    => $isPrivileged,
            'currentRole'     => $userRole,
            'totalLogs'       => $totalLogs,
            'criticalCount'   => $criticalCount,
            'suspiciousCount' => $suspiciousCount,
            'retentionDays'   => $retentionDays,
            'severity'        => $severity,
            'eventType'       => $eventType,
            'search'          => $search,
            'suspicious'      => $suspicious,
        ]);
    }

    /**
     * Trigger manual/automated TTL purge for logs older than 90 days.
     * Restricted to privileged roles (Superadmin, Security Lead).
     */
    public function purgeTtl()
    {
        $session = session();
        $userRole = $session->get('role') ?? 'analyst';

        if (!is_privileged_role($userRole)) {
            return redirect()->to('/audit-logs')->with('error', 'Akses Ditolak: Hanya Superadmin atau Security Lead yang berhak mengeksekusi retensi log audit.');
        }

        $retentionDays = 90;
        $deletedCount = $this->auditModel->purgeExpiredLogs($retentionDays);

        // Record audit trail of the purge action
        $this->auditModel->recordLog([
            'event_type'      => 'pdp_maintenance',
            'severity'        => 'warning',
            'actor_id'        => $session->get('username') ?? $session->get('admin_id'),
            'actor_role'      => $userRole,
            'target_resource' => 'security_audit_logs',
            'action'          => 'manual_ttl_purge',
            'details'         => [
                'retention_days'  => $retentionDays,
                'deleted_records' => $deletedCount,
                'executed_by'     => $session->get('username'),
            ],
            'is_suspicious'   => false,
        ]);

        return redirect()->to('/audit-logs')->with('success', "Kebijakan retensi TTL berhasil dijalankan! {$deletedCount} log usang (> {$retentionDays} hari) telah dibersihkan.");
    }
}
