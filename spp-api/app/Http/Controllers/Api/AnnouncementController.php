<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AnnouncementController extends Controller
{
    /**
     * Get latest announcements
     */
    public function latest(Request $request)
    {
        try {
            $limit = $request->query('limit', 10);
            
            $announcements = Announcement::where('publish_date', '<=', now())
                ->orderBy('is_important', 'desc')
                ->orderBy('publish_date', 'desc')
                ->take($limit)
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Latest announcements retrieved successfully',
                'data' => $announcements->map(function ($announcement) {
                    return [
                        'id' => $announcement->id,
                        'title' => $announcement->title,
                        'content' => $announcement->content,
                        'image' => $announcement->image,
                        'category' => $announcement->category,
                        'is_important' => $announcement->is_important,
                        'publish_date' => $announcement->publish_date->format('Y-m-d'),
                        'formatted_date' => $announcement->publish_date->format('d M Y'),
                    ];
                }),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve announcements',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get other recent announcements, excluding the current one.
     */
    public function other($id)
    {
        try {
            $otherAnnouncements = Announcement::where('id', '!=', $id)
                ->latest()
                ->limit(4)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $otherAnnouncements->map(function ($announcement) {
                    return [
                        'id' => $announcement->id,
                        'title' => $announcement->title,
                        'content' => $announcement->content,
                        'image' => $announcement->image,
                        'category' => $announcement->category,
                        'is_important' => $announcement->is_important,
                        'publish_date' => $announcement->publish_date->format('Y-m-d'),
                        'formatted_date' => $announcement->publish_date->format('d M Y'),
                    ];
                }),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch other announcements.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all announcements with filters
     */
    public function index(Request $request)
    {
        try {
            $query = Announcement::query();
            
            // For admin/petugas, show all. For others, filter by publish date
            $user = auth()->user();
            if (!$user || ($user->role !== 'admin' && $user->role !== 'petugas')) {
                $query->where('publish_date', '<=', now());
            }

            // Filter by category
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }

            // Only important announcements
            if ($request->has('important') && $request->important == 'true') {
                $query->where('is_important', true);
            }

            $announcements = $query->orderBy('publish_date', 'desc')->get();

            return response()->json([
                'status' => true,
                'message' => 'Announcements retrieved successfully',
                'data' => $announcements,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve announcements',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get announcement detail
     */
    public function show($id)
    {
        try {
            $announcement = Announcement::findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Announcement detail retrieved successfully',
                'data' => $announcement,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Announcement not found',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Create new announcement (Admin/Petugas only)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'image' => 'nullable|string',
            'category' => 'required|in:libur,ekstrakurikuler,pengumuman_umum',
            'is_important' => 'nullable|boolean',
            'publish_date' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $announcement = Announcement::create([
                'title' => $request->title,
                'content' => $request->content,
                'image' => $request->image,
                'category' => $request->category,
                'is_important' => $request->is_important ?? false,
                'publish_date' => $request->publish_date,
                'created_by' => auth()->id(),
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Announcement created successfully',
                'data' => $announcement,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to create announcement',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update announcement (Admin/Petugas only)
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|required|string|max:255',
            'content' => 'sometimes|required|string',
            'image' => 'nullable|string',
            'category' => 'sometimes|required|in:libur,ekstrakurikuler,pengumuman_umum',
            'is_important' => 'nullable|boolean',
            'publish_date' => 'sometimes|required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $announcement = Announcement::findOrFail($id);
            $announcement->update($request->all());

            return response()->json([
                'status' => true,
                'message' => 'Announcement updated successfully',
                'data' => $announcement,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to update announcement',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete announcement (Admin only)
     */
    public function destroy($id)
    {
        try {
            $announcement = Announcement::findOrFail($id);
            $announcement->delete();

            return response()->json([
                'status' => true,
                'message' => 'Announcement deleted successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete announcement',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

