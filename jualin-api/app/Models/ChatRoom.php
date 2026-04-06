<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ChatRoom extends Model
{
    protected $fillable = ['room_type'];

    /** Members of this room (pivot: chat_room_member) */
    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'chat_room_member', 'chat_room_id', 'user_id')
                    ->withTimestamps();
    }

    /** All messages in this room */
    public function messages(): HasMany
    {
        return $this->hasMany(ChatMessage::class, 'chat_room_id');
    }

    /** Latest message (for room list preview) */
    public function latestMessage(): HasOne
    {
        return $this->hasOne(ChatMessage::class, 'chat_room_id')->latestOfMany('sent_at');
    }
}
