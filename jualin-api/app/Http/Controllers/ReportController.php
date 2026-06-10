<?php

namespace App\Http\Controllers;

use App\Models\Report;
use App\Models\User;
use App\Models\Product;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'nullable|string|in:pending,processing,accepted,rejected,reviewed,resolved',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        $perPage = (int) $request->input('per_page', 10);

        // For admin to view all reports, ordered by newest
        $reports = Report::with([
            'reporter:id,username',
            'reportedUser:id,username,is_banned,banned_until',
            'product:id,name',
        ])
            ->when(
                $request->filled('status'),
                fn ($query) => $query->where('status', $request->input('status'))
            )
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        $reports->getCollection()->transform(function ($report) {
            $reportedUser = $report->reportedUser;
            $reportedProduct = $report->product;

            $report->reporter_username = $report->reporter_username
                ?: $report->reporter?->username
                ?: $report->username;
            $report->reported_username = $report->reported_username
                ?: $reportedUser?->username
                ?: $report->target_username;
            $report->reported_user_is_banned = (bool) ($reportedUser?->is_banned ?? false);
            $report->reported_user_banned_until = $reportedUser?->banned_until?->toDateTimeString();
            $report->reported_product_name = $reportedProduct?->name;
            $report->reported_product_id = $reportedProduct?->id;

            return $report;
        });

        return ApiResponse::success('Reports retrieved successfully', $reports);
    }

    public function store(Request $request)
    {
        $userViolationTypes = ['Laporan Pengguna', 'Pelanggaran User'];
        $isUserViolation = in_array($request->input('type'), $userViolationTypes, true);
        $currentUser = $request->user();

        $validator = Validator::make($request->all(), [
            'type' => 'required|string',
            'description' => 'required|string',
            'product_id' => 'nullable|integer|exists:products,id',
            'reported_user_id' => [
                'nullable',
                'integer',
                'exists:users,id',
                Rule::notIn([$currentUser?->id]),
            ],
            'reported_username' => 'nullable|string',
            'target_username' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        if ($request->filled('reported_user_id') && $request->input('reported_user_id') === $currentUser?->id) {
            return ApiResponse::error('Anda tidak dapat melaporkan akun sendiri.', null, 422);
        }

        try {
            $product = $request->filled('product_id') ? Product::find($request->input('product_id')) : null;
            $reportedUser = null;

            if ($request->filled('product_id') && !$product) {
                return ApiResponse::error('Product not found', null, 422);
            }

            if ($product && $product->seller_id === $currentUser?->id) {
                return ApiResponse::error('Anda tidak dapat melaporkan produk Anda sendiri.', null, 422);
            }

            if ($product) {
                $reportedUser = $product->seller_id ? User::find($product->seller_id) : null;
            }

            if ($isUserViolation) {
                $reportedUser = User::find($request->input('reported_user_id'));

                if (!$reportedUser) {
                    return ApiResponse::error('Reported user not found', null, 422);
                }
            }

            $report = Report::create([
                'reporter_id' => $currentUser->id,
                'reporter_username' => $currentUser->username,
                'reported_user_id' => $reportedUser?->id,
                'reported_username' => $reportedUser?->username,
                'username' => $currentUser->username,
                'product_id' => $product?->id,
                'type' => $request->type,
                'target_username' => $reportedUser?->username ?? $request->input('target_username'),
                'description' => $request->description,
                'status' => 'pending'
            ]);

            return ApiResponse::success('Report submitted successfully', $report, 201);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to submit report', $e->getMessage(), 500);
        }
    }


    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|string|in:pending,processing,accepted,rejected,reviewed,resolved',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        $newStatus = $request->input('status');

        // Normalize friendly admin states to the persisted report states.
        if ($newStatus === 'accepted') {
            $newStatus = 'reviewed';
        }

        if ($newStatus === 'rejected') {
            $newStatus = 'resolved';
        }

        try {
            $report = Report::find($id);

            if (!$report) {
                return ApiResponse::error('Report not found', null, 404);
            }

            $report->status = $newStatus;
            $report->save();

            return ApiResponse::success('Report status updated successfully', $report);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to update report status', $e->getMessage(), 500);
        }
    }
}
