<?php

namespace App\Services;

use App\Models\ChatMessage;
use App\Models\ChatRoom;
use App\Models\Notification;
use App\Models\Transaction;

class TransactionChatService
{
    public function publishPaymentVerified(Transaction $transaction, ?string $orderId = null): ?ChatMessage
    {
        $transaction->loadMissing(['items.product', 'customer', 'seller']);
        $productIds = $transaction->items->pluck('product_id')->map(fn ($id) => (int) $id);

        $rooms = ChatRoom::query()
            ->where('room_type', 'private')
            ->whereHas('members', fn ($query) => $query->where('users.id', $transaction->customer_id))
            ->whereHas('members', fn ($query) => $query->where('users.id', $transaction->seller_id))
            ->get();

        $room = $rooms->first(fn (ChatRoom $candidate) => $candidate->product_id && $productIds->contains((int) $candidate->product_id))
            ?? $rooms->first();

        if (!$room) {
            $room = ChatRoom::create([
                'room_type' => 'private',
                'product_id' => $productIds->first(),
            ]);
            $room->members()->attach([$transaction->customer_id, $transaction->seller_id]);
        }

        $item = $transaction->items->first();
        $product = $item?->product;
        $eventKey = 'payment_verified:' . $transaction->id;
        $productData = [
            'event' => 'payment_verified',
            'transaction_id' => $transaction->id,
            'order_id' => $orderId,
            'amount' => (float) $transaction->total_amount,
            'customer_id' => $transaction->customer_id,
            'seller_id' => $transaction->seller_id,
            'id' => $product?->id ?? 0,
            'name' => $product?->name ?? 'Pesanan Jualin',
            'image' => $product?->image,
            'price' => (float) ($item?->price_at_purchase ?? $transaction->total_amount),
            'quantity' => (int) ($item?->quantity ?? 1),
            'other_items_count' => max(0, $transaction->items->count() - 1),
            'customer_message' => 'Dana Anda sudah diamankan oleh Jualin. Periksa barang terlebih dahulu dan berikan kode klaim hanya setelah barang sesuai dan diterima.',
            'seller_message' => 'Dana customer sudah diamankan oleh Jualin. Silakan lakukan pertukaran barang, lalu minta kode klaim setelah customer memeriksa dan menerima barang.',
            'warning' => 'Jangan berikan atau meminta kode klaim sebelum pertukaran barang selesai.',
        ];

        $message = ChatMessage::firstOrCreate(
            ['system_event_key' => $eventKey],
            [
                'chat_room_id' => $room->id,
                'sender_id' => $transaction->customer_id,
                'message' => 'Pembayaran berhasil diverifikasi oleh Jualin.',
                'type' => 'payment_system',
                'product_data' => $productData,
                'sent_at' => now(),
                'is_read' => false,
            ]
        );

        if ($message->wasRecentlyCreated) {
            $room->touch();
            $this->notifyParticipants($transaction, $room, $productData['name']);
        }

        return $message;
    }

    private function notifyParticipants(Transaction $transaction, ChatRoom $room, string $productName): void
    {
        foreach ([$transaction->customer_id, $transaction->seller_id] as $userId) {
            Notification::create([
                'user_id' => $userId,
                'title' => 'Pembayaran Terverifikasi',
                'body' => "Pembayaran untuk {$productName} telah diverifikasi. Buka chat untuk melihat panduan pertukaran barang.",
                'type' => 'payment',
                'target_type' => 'chat_room',
                'target_id' => $room->id,
            ]);
        }
    }
}
