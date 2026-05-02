@props(['url'])
@php
    $frontendUrl = rtrim(config('app.frontend_url') ?: $url, '/');
    $logoUrl = config('app.mail_logo_url') ?: $frontendUrl . '/Logo.png';
@endphp
<tr>
<td class="header">
<a href="{{ $frontendUrl }}" class="brand-link" style="display: inline-block;">
<img src="{{ $logoUrl }}" class="brand-logo" alt="Jualin">
</a>
</td>
</tr>
