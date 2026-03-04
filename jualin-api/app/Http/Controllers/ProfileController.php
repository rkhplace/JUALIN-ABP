<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        try {
            $fullName = $request->input('fullName', '');
            $email = $request->input('email', '');
            $phone = $request->input('phone', '');
            $location = $request->input('location', '');
            $bio = $request->input('bio', '');
            $profilePicturePath = $request->input('profilePicture', '');

            if ($request->hasFile('profilePicture')) {
                $file = $request->file('profilePicture');
                $dir = public_path('uploads/profile');
                if (!File::exists($dir)) {
                    File::makeDirectory($dir, 0755, true);
                }
                $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $file->move($dir, $filename);
                $profilePicturePath = '/uploads/profile/' . $filename;
            }

            $data = [
                'fullName' => $fullName,
                'email' => $email,
                'phone' => $phone,
                'location' => $location,
                'bio' => $bio,
                'profilePicture' => $profilePicturePath,
            ];

            return ApiResponse::success('Profile updated', $data);
        } catch (\Throwable $e) {
            return ApiResponse::error('Update failed', 500);
        }
    }
}