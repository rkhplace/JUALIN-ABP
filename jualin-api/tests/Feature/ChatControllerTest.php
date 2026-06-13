<?php

namespace Tests\Feature;

use App\Models\ChatRoom;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ChatControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function testMemberCanSendImageMessage(): void
    {
        Storage::fake('public');

        $seller = User::create([
            'username' => 'seller_chat',
            'email' => 'seller-chat@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);
        $buyer = User::create([
            'username' => 'buyer_chat',
            'email' => 'buyer-chat@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);

        $room = ChatRoom::create(['room_type' => 'private']);
        $room->members()->attach([$seller->id, $buyer->id]);

        $this->actingAs($seller, 'api');
        $imagePath = tempnam(sys_get_temp_dir(), 'chat-image') . '.png';
        file_put_contents(
            $imagePath,
            base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=')
        );

        $res = $this->post("/api/v1/chat/rooms/{$room->id}/messages", [
            'image' => new UploadedFile(
                $imagePath,
                'condition.png',
                'image/png',
                null,
                true
            ),
        ]);

        $res->assertStatus(201)
            ->assertJsonPath('data.type', 'image');

        $messageUrl = $res->json('data.message');
        $this->assertIsString($messageUrl);
        $this->assertStringContainsString('/api/v1/files/chat-images/', $messageUrl);

        $storedPath = 'chat-images/' . basename(parse_url($messageUrl, PHP_URL_PATH));
        Storage::disk('public')->assertExists($storedPath);

        $rooms = $this->getJson('/api/v1/chat/rooms');
        $rooms->assertStatus(200)
            ->assertJsonPath('data.0.latest_message.type', 'image');
    }
}
