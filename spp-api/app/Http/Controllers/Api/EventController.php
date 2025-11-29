<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EventController extends Controller
{
    /**
     * Get upcoming events
     */
    public function upcoming(Request $request)
    {
        try {
            $limit = $request->query('limit', 10);
            
            $events = Event::where('event_date', '>=', now())
                ->orderBy('event_date', 'asc')
                ->orderBy('event_time', 'asc')
                ->take($limit)
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Upcoming events retrieved successfully',
                'data' => $events->map(function ($event) {
                    return [
                        'id' => $event->id,
                        'title' => $event->title,
                        'description' => $event->description,
                        'event_date' => $event->event_date->format('Y-m-d'),
                        'event_time' => $event->event_time,
                        'location' => $event->location,
                        'image' => $event->image,
                        'category' => $event->category,
                        'participants_count' => $event->participants_count,
                        'is_featured' => $event->is_featured,
                        'formatted_date' => [
                            'date' => $event->event_date->format('d'),
                            'month' => $event->event_date->format('M'),
                            'year' => $event->event_date->format('Y'),
                        ],
                    ];
                }),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve upcoming events',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all events with filters
     */
    public function index(Request $request)
    {
        try {
            $query = Event::query();

            // Filter by category
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }

            // Filter by date range
            if ($request->has('from_date')) {
                $query->where('event_date', '>=', $request->from_date);
            }
            if ($request->has('to_date')) {
                $query->where('event_date', '<=', $request->to_date);
            }

            // Only featured events
            if ($request->has('featured') && $request->featured == 'true') {
                $query->where('is_featured', true);
            }

            $events = $query->orderBy('event_date', 'desc')->get();

            return response()->json([
                'status' => true,
                'message' => 'Events retrieved successfully',
                'data' => $events,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve events',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get event detail
     */
    public function show($id)
    {
        try {
            $event = Event::findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Event detail retrieved successfully',
                'data' => $event,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Event not found',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Get similar events
     */
    public function similar($id)
    {
        try {
            $currentEvent = Event::findOrFail($id);

            $similarEvents = Event::where('category', $currentEvent->category)
                ->where('id', '!=', $id) // Exclude the current event
                ->where('event_date', '>=', now()->toDateString()) // Only upcoming or current events
                ->orderBy('event_date', 'asc')
                ->limit(4)
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Similar events retrieved successfully',
                'data' => $similarEvents,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve similar events',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Set a reminder for an event
     */
    public function remind(Request $request, $id)
    {
        try {
            $user = $request->user();
            $event = Event::findOrFail($id);

            // Check if reminder already exists
            $existingReminder = \App\Models\EventReminder::where('user_id', $user->id)
                ->where('event_id', $event->id)
                ->first();

            if ($existingReminder) {
                return response()->json([
                    'status' => true,
                    'message' => 'Reminder already set for this event.',
                ]);
            }

            // Create a new reminder
            \App\Models\EventReminder::create([
                'user_id' => $user->id,
                'event_id' => $event->id,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Reminder set successfully for ' . $event->title,
            ], 201);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['status' => false, 'message' => 'Event not found.'], 404);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to set reminder.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create new event (Admin/Petugas only)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'required|date',
            'event_time' => 'nullable|string',
            'location' => 'required|string|max:255',
            'image' => 'nullable|string',
            'category' => 'required|in:ujian,olahraga,ekskul,lainnya',
            'participants_count' => 'nullable|integer|min:0',
            'is_featured' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $event = Event::create([
                'title' => $request->title,
                'description' => $request->description,
                'event_date' => $request->event_date,
                'event_time' => $request->event_time,
                'location' => $request->location,
                'image' => $request->image,
                'category' => $request->category,
                'participants_count' => $request->participants_count ?? 0,
                'is_featured' => $request->is_featured ?? false,
                'created_by' => auth()->id(),
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Event created successfully',
                'data' => $event,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to create event',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update event (Admin/Petugas only)
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'sometimes|required|date',
            'event_time' => 'nullable|string',
            'location' => 'sometimes|required|string|max:255',
            'image' => 'nullable|string',
            'category' => 'sometimes|required|in:ujian,olahraga,ekskul,lainnya',
            'participants_count' => 'nullable|integer|min:0',
            'is_featured' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $event = Event::findOrFail($id);
            $event->update($request->all());

            return response()->json([
                'status' => true,
                'message' => 'Event updated successfully',
                'data' => $event,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to update event',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete event (Admin only)
     */
    public function destroy($id)
    {
        try {
            $event = Event::findOrFail($id);
            $event->delete();

            return response()->json([
                'status' => true,
                'message' => 'Event deleted successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete event',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

