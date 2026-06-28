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
            'images' => ['nullable','array'],
            'images.*' => ['image','mimes:jpeg,png,jpg,gif,webp','max:2048'],
            'category' => ['nullable','string','max:100'],
            'condition' => ['nullable','in:new,used,refurbished'],
            'status' => ['nullable','in:active,inactive,archived'],
            'location_label' => ['required','string','max:255'],
            'location_radius_km' => ['required','integer','in:1,3,5,10,15,25'],
            'latitude' => ['nullable','numeric','between:-90,90'],
            'longitude' => ['nullable','numeric','between:-180,180'],
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
