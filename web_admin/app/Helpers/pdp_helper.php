<?php

if (!function_exists('is_privileged_role')) {
    /**
     * Check if a given role (or the logged-in session role) has privileged security clearance.
     * Privileged roles (Superadmin, Security Lead) can inspect unmasked PII and forensics.
     * Standard roles (Analyst, Support, Campaign Manager, etc.) see masked PII under UU PDP No. 27/2022.
     */
    function is_privileged_role(?string $role = null): bool
    {
        if ($role === null) {
            $session = session();
            $role = $session ? ($session->get('role') ?? '') : '';
        }
        $normalized = strtolower(trim((string)$role));
        return in_array($normalized, ['superadmin', 'security_lead'], true);
    }
}

if (!function_exists('mask_email')) {
    /**
     * Mask email address for PII compliance (e.g. j***e@example.com).
     */
    function mask_email(?string $email, bool $force = false): string
    {
        if (empty($email)) {
            return '-';
        }
        if (!$force && is_privileged_role()) {
            return $email;
        }

        $parts = explode('@', $email, 2);
        if (count($parts) < 2) {
            return substr($email, 0, 1) . '***';
        }

        $user = $parts[0];
        $domain = $parts[1];
        $len = strlen($user);

        if ($len <= 2) {
            $maskedUser = substr($user, 0, 1) . '***';
        } else {
            $maskedUser = substr($user, 0, 1) . '***' . substr($user, -1);
        }

        return $maskedUser . '@' . $domain;
    }
}

if (!function_exists('mask_name')) {
    /**
     * Mask personal name for PII compliance (e.g. Budi Santoso -> B*** S***).
     */
    function mask_name(?string $name, bool $force = false): string
    {
        if (empty($name)) {
            return '-';
        }
        if (!$force && is_privileged_role()) {
            return $name;
        }

        $words = explode(' ', trim($name));
        $maskedWords = array_map(function ($word) {
            $len = mb_strlen($word);
            if ($len <= 1) {
                return $word . '*';
            }
            return mb_substr($word, 0, 1) . '***';
        }, $words);

        return implode(' ', $maskedWords);
    }
}

if (!function_exists('mask_phone')) {
    /**
     * Mask phone number for PII compliance (e.g. 08123456789 -> 0812****6789).
     */
    function mask_phone(?string $phone, bool $force = false): string
    {
        if (empty($phone)) {
            return '-';
        }
        if (!$force && is_privileged_role()) {
            return $phone;
        }

        $clean = preg_replace('/[^0-9+]/', '', $phone);
        $len = strlen($clean);
        if ($len <= 5) {
            return substr($clean, 0, 2) . '***';
        }

        return substr($clean, 0, 4) . '****' . substr($clean, -3);
    }
}

if (!function_exists('mask_ip')) {
    /**
     * Mask IP address for privacy protection (e.g. 192.168.1.50 -> 192.168.*.*).
     */
    function mask_ip(?string $ip, bool $force = false): string
    {
        if (empty($ip)) {
            return '-';
        }
        if (!$force && is_privileged_role()) {
            return $ip;
        }

        $parts = explode('.', $ip);
        if (count($parts) === 4) {
            return $parts[0] . '.' . $parts[1] . '.*.*';
        }

        $partsCol = explode(':', $ip);
        if (count($partsCol) > 2) {
            return $partsCol[0] . ':' . $partsCol[1] . ':****';
        }

        return substr($ip, 0, 4) . '***';
    }
}

if (!function_exists('mask_details')) {
    /**
     * Recursively mask sensitive payload keys inside audit log details.
     */
    function mask_details(mixed $details, bool $force = false): mixed
    {
        if (empty($details)) {
            return $details;
        }
        if (!$force && is_privileged_role()) {
            return $details;
        }

        $isJsonString = false;
        $data = $details;

        if (is_string($details)) {
            $decoded = json_decode($details, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                $isJsonString = true;
                $data = $decoded;
            } else {
                return $details;
            }
        }

        if (is_array($data)) {
            $maskArray = function (&$arr) use (&$maskArray) {
                foreach ($arr as $k => &$v) {
                    $kLower = strtolower((string)$k);
                    if (is_array($v)) {
                        $maskArray($v);
                    } elseif (is_string($v)) {
                        if (in_array($kLower, ['email', 'user_email', 'target_user'], true)) {
                            $v = mask_email($v, true);
                        } elseif (in_array($kLower, ['phone', 'mobile', 'tel'], true)) {
                            $v = mask_phone($v, true);
                        } elseif (in_array($kLower, ['name', 'display_name', 'full_name'], true)) {
                            $v = mask_name($v, true);
                        } elseif (in_array($kLower, ['ip', 'ip_address', 'client_ip'], true)) {
                            $v = mask_ip($v, true);
                        } elseif (in_array($kLower, ['token', 'password', 'secret', 'auth_token', 'refresh_token'], true)) {
                            $v = '[REDACTED_SECRET]';
                        }
                    }
                }
            };
            $maskArray($data);
        }

        return $isJsonString ? json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) : $data;
    }
}
