<?php

namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\UploadedFile;
use App\Services\UserService;
use App\Repositories\UserRepository;
use App\Models\User;

class UserServiceTest extends TestCase
{
    use RefreshDatabase;

    public function testCreateStoresProfilePictureAndHashesPassword()
    {
        Storage::fake('public');
        $service = new UserService(new UserRepository());

        $user = $service->create([
            'username' => 'u1',
            'email' => 'u1@example.com',
            'password' => 'secret',
            'profile_picture' => UploadedFile::fake()->image('pp.jpg'),
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertTrue(Storage::disk('public')->exists($user->profile_picture));
        $this->assertNotEquals('secret', $user->password);
    }

    public function testUpdateReplacesProfilePictureAndDeletesOld()
    {
        Storage::fake('public');
        $service = new UserService(new UserRepository());

        $user = User::create([
            'username' => 'u2',
            'email' => 'u2@example.com',
            'password' => 'secret',
            'profile_picture' => 'profile_pictures/old.jpg',
        ]);
        Storage::disk('public')->put('profile_pictures/old.jpg', 'x');

        $updated = $service->update($user->id, [
            'profile_picture' => UploadedFile::fake()->image('new.jpg'),
        ]);

        $this->assertFalse(Storage::disk('public')->exists('profile_pictures/old.jpg'));
        $this->assertTrue(Storage::disk('public')->exists($updated->profile_picture));
    }
}