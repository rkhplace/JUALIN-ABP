<?php

namespace App\Http\Responses;
use Illuminate\Pagination\LengthAwarePaginator;

class ApiResponse
{
    public static function success(string $message, $data = null, int $status = 200)
    {
        $response = [
            'success' => true,
            'status_code' => $status,
            'message' => $message,
        ];

        if ($data instanceof LengthAwarePaginator) {
            $response['data'] = $data->items();
            $response['pagination'] = [
                'current_page' => $data->currentPage(),
                'last_page' => $data->lastPage(),
                'per_page' => $data->perPage(),
                'total' => $data->total(),
                'from' => $data->firstItem(),
                'to' => $data->lastItem(),
            ];
        } else {
            $response['data'] = $data;
        }

        return response()->json($response, $status);
    }

    public static function error(string $message, $errors = null, int $status = 400)
    {
        return response()->json([
            'success' => false,
            'status_code' => $status,
            'message' => $message,
            'errors' => $errors
        ], $status);
    }
}
