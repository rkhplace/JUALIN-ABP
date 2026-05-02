<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/password/reset/{token}', function ($token) {
    $email = request('email');
    $frontendUrl = rtrim(config('app.frontend_url') ?: config('app.url'), '/');

    return redirect($frontendUrl . '/auth/reset-password?' . http_build_query([
        'token' => $token,
        'email' => $email,
    ]));
})->name('password.reset');
