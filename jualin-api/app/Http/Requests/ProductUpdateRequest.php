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
            'images' => ['sometimes','nullable','array'],
            'images.*' => ['image','mimes:jpeg,png,jpg,gif,webp','max:2048'],
            'category' => ['sometimes','nullable','string','max:100'],
            'condition' => ['sometimes','nullable','in:new,used,refurbished'],
            'status' => ['sometimes','nullable','in:active,inactive,archived'],
            'location_label' => ['sometimes','required','string','max:255'],
            'location_radius_km' => ['sometimes','required','integer','in:1,3,5,10,15,25'],
            'latitude' => ['sometimes','nullable','numeric','between:-90,90'],
            'longitude' => ['sometimes','nullable','numeric','between:-180,180'],
        ];
    }

    public function messages(): array
    {
        return [
            'image.max' => 'Ukuran gambar terlalu besar. Maksimal 2MB. Silakan gunakan gambar dengan ukuran lebih kecil atau kompres terlebih dahulu.',
            'location_label.required' => 'Lokasi tawaran wajib diisi.',
            'location_radius_km.required' => 'Radius lokasi wajib dipilih.',
        ];
    }
}
