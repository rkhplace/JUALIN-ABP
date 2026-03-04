<?php

namespace App\Http\Responses;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductResponse extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'seller_id' => $this->seller_id,
            'name' => $this->name,
            'description' => $this->description,
            'price' => $this->price,
            'stock_quantity' => $this->stock_quantity,
            'image' => $this->image,
            'category' => $this->category,
            'condition' => $this->condition,
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'seller' => [
                'id' => $this->seller->id ?? null,
                'username' => $this->seller->username ?? null,
                'profile_picture' => $this->seller->profile_picture ?? null,
                'city' => $this->seller->city ?? null,
            ],
        ];
    }
}