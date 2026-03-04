<?php

namespace App\Http\Controllers;

use App\Models\Report;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ReportController extends Controller
{
    public function index()
    {
        // For admin to view all reports, ordered by newest
        $reports = Report::orderBy('created_at', 'desc')->paginate(10);
        
        return ApiResponse::success('Reports retrieved successfully', $reports);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string',
            'type' => 'required|string',
            'description' => 'required|string',
            'target_username' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        try {
            $report = Report::create([
                'username' => $request->username,
                'type' => $request->type,
                'target_username' => $request->target_username,
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
}
