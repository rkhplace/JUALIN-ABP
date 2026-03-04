<?php

namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Repositories\UserRepository;
use App\Models\User;

class UserRepositoryTest extends TestCase
{
    use RefreshDatabase;

    public function testCreateFindUpdateDeleteFlow()
    {
        $repo = new UserRepository();

        $user = $repo->create([
            'username' => 'u1',
            'email' => 'u1@example.com',
            'password' => 'secret',
            'role' => 'customer',
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertNotEquals('secret', $user->password);

        $found = $repo->findByEmail('u1@example.com');
        $this->assertSame($user->id, $found->id);

        $updated = $repo->update($user->id, ['city' => 'Bogor']);
        $this->assertSame('Bogor', $updated->city);

        $deleted = $repo->delete($user->id);
        $this->assertSame(1, $deleted);
        $this->assertNull($repo->find($user->id));
    }

    public function testGetAllPaginates()
    {
        $repo = new UserRepository();
        foreach (range(1, 15) as $i) {
            $repo->create([
                'username' => "u$i",
                'email' => "u$i@example.com",
                'password' => 'pw',
                'role' => 'customer',
            ]);
        }

        $page = $repo->getAll(['per_page' => 5]);
        $this->assertCount(5, $page->items());
        $this->assertSame(15, $page->total());
        $this->assertSame(5, $page->perPage());
    }
}