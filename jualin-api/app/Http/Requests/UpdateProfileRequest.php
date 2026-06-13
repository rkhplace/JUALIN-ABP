<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if ($this->has('email')) {
            $this->merge([
                'email' => strtolower(trim((string) $this->input('email'))),
            ]);
        }
    }

    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        $userId = $this->user()?->id;

        return [
            'username' => [
                'sometimes',
                'string',
                'min:3',
                'max:20',
                Rule::unique('users', 'username')->ignore($userId),
            ],
            'email' => [
                'sometimes',
                'email',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'profile_picture' => [
                'sometimes',
                'nullable',
                'image',
                'mimes:jpeg,png,jpg,gif,webp',
                'max:2048',
            ],
            'bio' => 'sometimes|nullable|string',
            'gender' => 'sometimes|nullable|in:male,female,other',
            'birthday' => 'sometimes|nullable|date',
            'region' => 'sometimes|nullable|string',
            'city' => 'sometimes|nullable|string',
            'phone' => 'sometimes|nullable|string|max:20',
        ];
    }
}
