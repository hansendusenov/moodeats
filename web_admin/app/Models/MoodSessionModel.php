<?php

namespace App\Models;

use CodeIgniter\Model;

class MoodSessionModel extends Model
{
    protected $table            = 'mood_sessions';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'id',
        'session_id',
        'user_id',
        'role',
        'message_text',
        'detected_mood',
        'food_categories',
        'location_lat',
        'location_lng',
        'city_detected',
        'ai_response_payload',
        'extracted_intent',
        'is_unlinked',
        'created_at',
    ];

    protected $useTimestamps = false;

    public function getRecentSessions(int $limit = 10)
    {
        return $this->orderBy('created_at', 'DESC')
                    ->limit($limit)
                    ->findAll();
    }
}
