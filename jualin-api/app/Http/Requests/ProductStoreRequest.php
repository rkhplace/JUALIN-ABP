<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProductStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required','string','max:255'],
            'description' => ['nullable','string'],
            'price' => ['required','numeric','min:0'],
            'stock_quantity' => ['required','integer','min:0'],
            'image' => ['nullable','image','mimes:jpeg,png,jpg,gif,webp','max:2048'],
            'category' => ['nullable','string','max:100'],
            'condition' => ['nullable','in:new,used,refurbished'],
            'status' => ['nullable','in:active,inactive,archived'],
        ];
    }

    public function messages(): array
    {
        return [
            'image.max' => 'Ukuran gambar terlalu besar. Maksimal 2MB. Silakan gunakan gambar dengan ukuran lebih kecil atau kompres terlebih dahulu.',
        ];
    }
}