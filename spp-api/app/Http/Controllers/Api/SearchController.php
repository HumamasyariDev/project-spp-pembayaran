<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $query = $request->input('query');

        if (empty($query)) {
            return response()->json(['data' => []]);
        }

        $user = $request->user();

        // Search Events
        $events = \App\Models\Event::where('title', 'like', "%{$query}%")
            ->orWhere('description', 'like', "%{$query}%")
            ->select('id', 'title as text', \Illuminate\Support\Facades\DB::raw('"event" as type'))
            ->get();

        // Search Announcements
        $announcements = \App\Models\Announcement::where('title', 'like', "%{$query}%")
            ->orWhere('content', 'like', "%{$query}%")
            ->select('id', 'title as text', \Illuminate\Support\Facades\DB::raw('"announcement" as type'))
            ->get();

        // Search Bills (SPP)
        $bills = \App\Models\SppBill::where('user_id', $user->id)
            ->where(function ($q) use ($query) {
                $q->where('bulan', 'like', "%{$query}%")
                  ->orWhere('status', 'like', "%{$query}%");
            })
            ->select('id', 'bulan as text', \Illuminate\Support\Facades\DB::raw('"bill" as type'))
            ->get();

        $results = $events->concat($announcements)->concat($bills);

        return response()->json(['data' => $results]);
    }

    public function recent(Request $request)
    {
        $user = $request->user();

        // Get recent events (3 upcoming events)
        $events = \App\Models\Event::where('event_date', '>=', now())
            ->orderBy('event_date', 'asc')
            ->limit(3)
            ->select('id', 'title as text', \Illuminate\Support\Facades\DB::raw('"event" as type'))
            ->get();

        // Get recent announcements (3 latest)
        $announcements = \App\Models\Announcement::orderBy('created_at', 'desc')
            ->limit(3)
            ->select('id', 'title as text', \Illuminate\Support\Facades\DB::raw('"announcement" as type'))
            ->get();

        // Get unpaid bills for user
        $bills = \App\Models\SppBill::where('user_id', $user->id)
            ->where('status', 'belum_dibayar')
            ->orderBy('tanggal_jatuh_tempo', 'asc')
            ->limit(3)
            ->select('id', 'bulan as text', \Illuminate\Support\Facades\DB::raw('"bill" as type'))
            ->get();

        $results = $events->concat($announcements)->concat($bills);

        return response()->json(['data' => $results]);
    }
}
