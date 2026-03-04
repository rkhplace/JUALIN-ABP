<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Http\Responses\ApiResponse;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return ApiResponse::error(
                'Unauthorized',
                null,
                401
            );
        }

        $allowedRoles = [];
        foreach ($roles as $roleString) {
            $allowedRoles = array_merge($allowedRoles, explode(',', $roleString));
        }
        $allowedRoles = array_map('trim', $allowedRoles);

        if (!in_array($user->role, $allowedRoles)) {
            return ApiResponse::error(
                'Forbidden: you do not have permission to access this resource.',
                null,
                403
            );
        }

        return $next($request);
    }
}
