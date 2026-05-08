<?php

namespace App\Http\Controllers;

use App\Models\Report;
use App\Models\User;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    public function index()
    {
        // For admin to view all reports, ordered by newest
        $reports = Report::with([
            'reporter:id,username',
            'reportedUser:id,username,is_banned,banned_until',
        ])->orderBy('created_at', 'desc')->paginate(10);

        $reports->getCollection()->transform(function ($report) {
            $reportedUser = $report->reportedUser;

            $report->reporter_username = $report->reporter_username
                ?: $report->reporter?->username
                ?: $report->username;
            $report->reported_username = $report->reported_username
                ?: $reportedUser?->username
                ?: $report->target_username;
            $report->reported_user_is_banned = (bool) ($reportedUser?->is_banned ?? false);
            $report->reported_user_banned_until = $reportedUser?->banned_until?->toDateTimeString();

            return $report;
        });
        
        return ApiResponse::success('Reports retrieved successfully', $reports);
    }

    public function store(Request $request)
    {
        $isUserViolation = in_array($request->input('type'), ['Laporan Pengguna', 'Pelanggaran User'], true);
        $currentUser = $request->user();

        $validator = Validator::make($request->all(), [
            'type' => 'required|string',
            'description' => 'required|string',
            'reported_user_id' => [
                Rule::requiredIf($isUserViolation),
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

        try {
            $reportedUser = $isUserViolation
                ? User::find($request->input('reported_user_id'))
                : null;

            if ($isUserViolation && !$reportedUser) {
                return ApiResponse::error('Reported user not found', null, 422);
            }

            $report = Report::create([
                'reporter_id' => $currentUser->id,
                'reporter_username' => $currentUser->username,
                'reported_user_id' => $reportedUser?->id,
                'reported_username' => $reportedUser?->username,
                'username' => $currentUser->username,
                'type' => $request->type,
                'target_username' => $reportedUser?->username,
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
            'status' => 'required|string|in:accepted,rejected,pending', // Add other statuses if needed
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        try {
            $report = Report::find($id);

            if (!$report) {
                return ApiResponse::error('Report not found', null, 404);
            }

            $report->status = $request->status;
            $report->save();

            return ApiResponse::success('Report status updated successfully', $report);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to update report status', $e->getMessage(), 500);
        }
    }

    public function banReportedUser(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'duration_days' => 'required|integer|in:1,7,30',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        try {
            $report = Report::find($id);

            if (!$report) {
                return ApiResponse::error('Report not found', null, 404);
            }

            $user = $report->reported_user_id
                ? User::find($report->reported_user_id)
                : null;

            if (!$user && ($report->reported_username || $report->target_username)) {
                $user = User::where('username', $report->reported_username ?: $report->target_username)->first();
            }

            if (!$user) {
                return ApiResponse::error('Reported user not available for this report', null, 422);
            }

            if (!in_array($user->role, ['customer', 'seller'], true)) {
                return ApiResponse::error('Only customer or seller accounts can be banned from reports', null, 422);
            }

            $banStartsAt = Carbon::now();
            $banEndsAt = $banStartsAt->copy()->addDays((int) $request->duration_days);

            $user->update([
                'is_banned' => true,
                'banned_until' => $banEndsAt,
            ]);

            return ApiResponse::success('Reported user banned successfully', [
                'report' => $report,
                'user' => $user->fresh(),
                'ban_started_at' => $banStartsAt->toDateTimeString(),
                'banned_until' => $banEndsAt->toDateTimeString(),
            ]);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to ban reported user', $e->getMessage(), 500);
        }
    }
}
