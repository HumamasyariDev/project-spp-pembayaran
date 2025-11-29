<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Event;
use App\Models\EventReminder;
use App\Services\FCMService;
use Carbon\Carbon;

class SendEventReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:send-event-reminders';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send reminders for events happening tomorrow';

    /**
     * Execute the console command.
     */
    public function handle(FCMService $fcmService)
    {
        $this->info('Starting to send event reminders...');

        $tomorrow = Carbon::tomorrow()->toDateString();
        
        // Find events happening tomorrow
        $events = Event::where('event_date', $tomorrow)->get();

        if ($events->isEmpty()) {
            $this->info('No events scheduled for tomorrow. No reminders to send.');
            return;
        }

        $this->info("Found {$events->count()} events for tomorrow. Processing reminders...");

        foreach ($events as $event) {
            $this->info("Processing event: {$event->title}");

            // Find users who want a reminder for this event
            $reminders = EventReminder::with('user')->where('event_id', $event->id)->get();

            if ($reminders->isEmpty()) {
                $this->line("-> No reminders set for this event.");
                continue;
            }

            $this->line("-> Found {$reminders->count()} users to remind.");

            foreach ($reminders as $reminder) {
                $user = $reminder->user;
                if ($user && $user->fcm_token) {
                    $title = "Jangan Lupa! {$event->title}";
                    $body = "Event akan dimulai besok, {$event->event_date->format('d M Y')} pukul {$event->event_time}. Lokasi: {$event->location}.";
                    
                    $fcmService->sendToDevice($user->fcm_token, $title, $body, [
                        'type' => 'event_reminder',
                        'event_id' => (string)$event->id,
                    ]);

                    $this->line("  - Sent reminder to {$user->name}");
                }
            }
        }

        $this->info('All event reminders have been processed.');
    }
}
