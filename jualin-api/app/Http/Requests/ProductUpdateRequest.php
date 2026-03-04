<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProductUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes','string','max:255'],
            'description' => ['sometimes','nullable','string'],
            'price' => ['sometimes','numeric','min:0'],
            'stock_quantity' => ['sometimes','integer','min:0'],
            'image' => ['sometimes','nullable','image','mimes:jpeg,png,jpg,gif,webp','max:2048'],
            'category' => ['sometimes','nullable','string','max:100'],
            'condition' => ['sometimes','nullable','in:new,used,refurbished'],
            'status' => ['sometimes','nullable','in:active,inactive,archived'],
        ];
    }

    public function messages(): array
    {
        return [
            'image.max' => 'Ukuran gambar terlalu besar. Maksimal 2MB. Silakan gunakan gambar dengan ukuran lebih kecil atau kompres terlebih dahulu.',
        ];
    }
}