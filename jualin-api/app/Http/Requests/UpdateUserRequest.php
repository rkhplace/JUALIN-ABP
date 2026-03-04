<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $id = request()->route('id');

        return [
            'username' => "sometimes|string|min:3|max:20|unique:users,username,$id",
            'email'    => "sometimes|email|unique:users,email,$id",
            'profile_picture' => 'sometimes|nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'password' => 'sometimes|string|min:8',
            'role'     => 'sometimes|in:admin,seller,customer',
            'bio'      => 'sometimes|nullable|string',
            'gender'   => 'sometimes|nullable|in:male,female,other',
            'birthday' => 'sometimes|nullable|date',
            'region'   => 'sometimes|nullable|string',
            'city'     => 'sometimes|nullable|string',
            'followers' => 'sometimes|nullable|integer|min:0',
            'following' => 'sometimes|nullable|integer|min:0',
        ];
    }
}
