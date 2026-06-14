<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Services\SellerVerificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;

class SellerController extends Controller
{
    protected SellerVerificationService $verificationService;

    public function __construct(SellerVerificationService $verificationService)
    {
        $this->verificationService = $verificationService;
    }

    /**
     * GET /api/v1/seller/verification-status
     * Returns the authenticated seller's verification progress.
     */
    public function verificationStatus(): JsonResponse
    {
        $user = Auth::user();

        if ($user->role !== 'seller') {
            return ApiResponse::error('Only sellers can access this endpoint', null, 403);
        }

        // Re-sync in real time so the response is always fresh.
        $this->verificationService->updateSellerVerification($user->id);
        $user->refresh();
        $profileCompletion = $this->verificationService->getProfileCompletion($user);

        return ApiResponse::success('Verification status retrieved successfully', [
            'total_sales' => (int) $user->total_sales,
            'is_verified' => (bool) $user->is_verified,
            'target'      => SellerVerificationService::VERIFICATION_TARGET,
            'profile_complete' => $profileCompletion['is_complete'],
            'missing_profile_fields' => $profileCompletion['missing_fields'],
            'profile_requirements' => $profileCompletion['required_fields'],
        ]);
    }
}
