<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Upload image (untuk Events, Announcements, Banners)
     * 
     * Endpoint: POST /api/upload/image
     * Body: multipart/form-data dengan field 'image' dan 'type' (event/announcement/banner)
     */
    public function uploadImage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:5120', // Max 5MB
            'type' => 'required|in:event,announcement,banner',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $image = $request->file('image');
            $type = $request->type;
            
            // Generate unique filename
            $filename = $type . '_' . time() . '_' . Str::random(10) . '.' . $image->getClientOriginalExtension();
            
            // Store in public/uploads/{type}/
            $path = $image->storeAs("uploads/{$type}", $filename, 'public');
            
            // Generate full URL
            $url = url("/storage/{$path}");
            
            return response()->json([
                'status' => true,
                'message' => 'Image uploaded successfully',
                'data' => [
                    'filename' => $filename,
                    'path' => $path,
                    'url' => $url,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to upload image',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete uploaded image
     * 
     * Endpoint: DELETE /api/upload/image
     * Body: { "path": "uploads/event/event_123.jpg" }
     */
    public function deleteImage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'path' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $path = $request->path;
            
            // Check if file exists
            if (!Storage::disk('public')->exists($path)) {
                return response()->json([
                    'status' => false,
                    'message' => 'File not found',
                ], 404);
            }
            
            // Delete file
            Storage::disk('public')->delete($path);
            
            return response()->json([
                'status' => true,
                'message' => 'Image deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete image',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

