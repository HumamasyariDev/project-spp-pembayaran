<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BannerController extends Controller
{
    /**
     * Get active banners
     */
    public function active(Request $request)
    {
        try {
            $banners = Banner::active()->get();

            return response()->json([
                'status' => true,
                'message' => 'Active banners retrieved successfully',
                'data' => $banners->map(function ($banner) {
                    return [
                        'id' => $banner->id,
                        'title' => $banner->title,
                        'description' => $banner->description,
                        'image' => $banner->image,
                        'link_url' => $banner->link_url,
                        'order' => $banner->order,
                    ];
                }),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve banners',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all banners (Admin/Petugas)
     */
    public function index(Request $request)
    {
        try {
            $query = Banner::query();

            // Filter by active status
            if ($request->has('is_active')) {
                $query->where('is_active', $request->is_active === 'true');
            }

            $banners = $query->orderBy('order', 'asc')->get();

            return response()->json([
                'status' => true,
                'message' => 'Banners retrieved successfully',
                'data' => $banners,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve banners',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get banner detail
     */
    public function show($id)
    {
        try {
            $banner = Banner::findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Banner detail retrieved successfully',
                'data' => $banner,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Banner not found',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Create new banner (Admin/Petugas only)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'required|string',
            'link_url' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'order' => 'nullable|integer',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $banner = Banner::create([
                'title' => $request->title,
                'description' => $request->description,
                'image' => $request->image,
                'link_url' => $request->link_url,
                'is_active' => $request->is_active ?? true,
                'order' => $request->order ?? 0,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'created_by' => auth()->id(),
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Banner created successfully',
                'data' => $banner,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to create banner',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update banner (Admin/Petugas only)
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'sometimes|required|string',
            'link_url' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'order' => 'nullable|integer',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $banner = Banner::findOrFail($id);
            $banner->update($request->all());

            return response()->json([
                'status' => true,
                'message' => 'Banner updated successfully',
                'data' => $banner,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to update banner',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete banner (Admin only)
     */
    public function destroy($id)
    {
        try {
            $banner = Banner::findOrFail($id);
            $banner->delete();

            return response()->json([
                'status' => true,
                'message' => 'Banner deleted successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete banner',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

