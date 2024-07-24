<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class HttpsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
    }

    public function boot(): void
    {
        if (env('GENERATE_HTTPS', false)===true) {
            URL::forceScheme('https');
        }
    }
}
