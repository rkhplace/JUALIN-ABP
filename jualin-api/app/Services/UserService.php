<?php

namespace App\Services;

use App\Repositories\UserRepository;
use Illuminate\Support\Facades\Storage;

class UserService
{
    protected $users;

    public function __construct(UserRepository $users)
    {
        $this->users = $users;
    }

    public function getAll($perPage = 10)
    {
        return $this->users->getAll(['per_page' => $perPage]);
    }

    public function getById($id)
    {
        return $this->users->find($id);
    }

    public function create(array $data)
    {
        if (isset($data['profile_picture']) && $data['profile_picture'] instanceof \Illuminate\Http\UploadedFile) {
            $data['profile_picture'] = $data['profile_picture']->store('profile_pictures', 'public');
        }
        $data['password'] = bcrypt($data['password']);
        return $this->users->create($data);
    }

    public function update($id, array $data)
    {
        $user = $this->users->find($id);

        if (isset($data['profile_picture']) && $data['profile_picture'] instanceof \Illuminate\Http\UploadedFile) {
            // Delete old profile picture if exists
            $oldProfilePicture = $user->getRawOriginal('profile_picture');
            if ($oldProfilePicture && Storage::disk('public')->exists($oldProfilePicture)) {
                Storage::disk('public')->delete($oldProfilePicture);
            }
            $data['profile_picture'] = $data['profile_picture']->store('profile_pictures', 'public');
        }

        if (isset($data['password'])) {
            $data['password'] = bcrypt($data['password']);
        }
        return $this->users->update($id, $data);
    }

    public function delete($id)
    {
        $user = $this->users->find($id);

        // Delete profile picture if exists
        $profilePicture = $user?->getRawOriginal('profile_picture');
        if ($profilePicture && Storage::disk('public')->exists($profilePicture)) {
            Storage::disk('public')->delete($profilePicture);
        }

        return $this->users->delete($id);
    }
}
