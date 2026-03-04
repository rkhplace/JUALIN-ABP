<?php

use App\Http\Responses\ApiResponse;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->use([\Illuminate\Http\Middleware\HandleCors::class]);

        $middleware->group('api', [
            \App\Http\Middleware\ForceJsonResponse::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {

        $exceptions->render(function (AuthenticationException $e, $request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return ApiResponse::error(
                    'Unauthenticated.',
                    null,
                    401
                );
            }
        });

        // Handle Validation Exception (422)
        $exceptions->render(function (\Illuminate\Validation\ValidationException $e, $request) {
            return ApiResponse::error(
                'Validation error',
                $e->errors(),
                422
            );
        });

        $exceptions->render(function (\Illuminate\Auth\Access\AuthorizationException $e, $request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return ApiResponse::error(
                    $e->getMessage() ?: 'This action is unauthorized.',
                    null,
                    403
                );
            }
        });

        $exceptions->render(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, $request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return ApiResponse::error(
                    'Resource not found',
                    null,
                    404
                );
            }
        });

        // Handle All Other Exceptions (fallback JSON handler)
        $exceptions->render(function (\Throwable $e, $request) {

            if ($request->expectsJson()) {
                $status = $e instanceof \Symfony\Component\HttpKernel\Exception\HttpException
                    ? $e->getStatusCode()
                    : 500;

                return ApiResponse::error(
                    $e->getMessage() ?: 'Server Error',
                    config('app.debug') ? ['trace' => $e->getTrace()] : null,
                    $status
                );
            }
        });
    })
    ->create();