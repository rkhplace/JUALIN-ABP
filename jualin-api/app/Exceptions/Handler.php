<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use App\Http\Responses\ApiResponse;
use Illuminate\Validation\ValidationException;

class Handler extends ExceptionHandler
{
    protected $dontReport = [];

    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    public function render($request, Throwable $e)
    {
        // Force JSON response for API clients
        if ($request->expectsJson()) {
            // Handle validation exceptions separately to return structured errors
            if ($e instanceof ValidationException) {
                $errors = $e->errors();
                $message = $e->getMessage() ?: 'The given data was invalid.';
                return ApiResponse::error($message, $errors, 422);
            }

            $status = $e instanceof HttpExceptionInterface
                ? $e->getStatusCode()
                : 500;

            $message = $e->getMessage() ?: ($status === 500 ? 'Server Error' : 'Error');

            // Include trace only in debug mode inside the errors payload
            $errorsPayload = null;
            if (config('app.debug')) {
                $errorsPayload = ['trace' => $e->getTrace()];
            }

            return ApiResponse::error($message, $errorsPayload, $status);
        }

        return parent::render($request, $e);
    }
}
