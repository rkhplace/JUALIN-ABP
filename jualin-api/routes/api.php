<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\ReportController;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;

Route::prefix('v1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/password/email', [AuthController::class, 'sendResetLinkEmail']);
    Route::post('/password/reset', [AuthController::class, 'resetPassword']);
    Route::post('/refresh-token', [AuthController::class, 'refreshToken']);
    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/{id}', [ProductController::class, 'show']);
    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::post('/payments/notification', [PaymentController::class, 'handleNotification']);
    Route::post('/reports', [ReportController::class, 'store']);

    Route::middleware('auth:api')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::patch('/profile/update', [\App\Http\Controllers\ProfileController::class, 'update']);
    });
});

Route::prefix('v1')->middleware('auth:api')->group(function () {

    Route::middleware('role:admin')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::get('/reports', [ReportController::class, 'index']);
        Route::patch('/reports/{id}/status', [ReportController::class, 'updateStatus']);
        Route::post('/users', [UserController::class, 'store']);

        Route::delete('/users/{id}/delete', [UserController::class, 'destroy']);
    });

    Route::middleware('role:seller,admin')->group(function () {
        Route::get('/seller/products', [ProductController::class, 'indexMe']);
        Route::post('/products', [ProductController::class, 'store']);
        Route::patch('/products/{product}', [ProductController::class, 'update']);
        Route::delete('/products/{product}/delete', [ProductController::class, 'destroy']);
    });

    Route::middleware('role:customer,admin')->group(function () {
        Route::post('/transactions', [TransactionController::class, 'store']);
        Route::get('/payments/history', [PaymentController::class, 'getPaymentsByUser']);
    });

    Route::patch('/users/{id}/update', [UserController::class, 'update']);
    Route::get('/transactions', [TransactionController::class, 'index']);
    Route::get('/transactions/{id}', [TransactionController::class, 'show']);

    Route::middleware('role:seller')->group(function () {
        Route::get('/transactions/income/statistics', [TransactionController::class, 'incomeStatistics']);
    });

    Route::middleware('role:customer,admin')->group(function () {
        Route::post('/payments/create', [PaymentController::class, 'createPayment']);
    });

    Route::middleware('role:customer,admin,seller')->group(function () {
        Route::get('/payments/status/{orderId}', [PaymentController::class, 'checkStatus']);
    });

});

Route::fallback(function (Request $request) {
    return ApiResponse::error(
        'API endpoint not found',
        [
            'requested_url' => $request->fullUrl(),
            'method' => $request->method(),
        ],
        404
    );
});
