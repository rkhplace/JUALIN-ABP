<?php

return [
    'paths' => ['api/*', 'v1/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'http://localhost:3000',
        'https://www.jualin-tel.biz.id',
        'https://jualin-tel.biz.id',
        'https://jualin-abp-production.up.railway.app',
    ],
    'allowed_origins_patterns' => [
        '#^https://.*\.vercel\.app$#',
    ],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
