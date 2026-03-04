<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PaymentCreateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'transaction_id' => ['required', 'integer', 'exists:transactions,id'],
            'customer_details' => ['nullable', 'array'],
            'customer_details.first_name' => ['nullable', 'string', 'max:255'],
            'customer_details.last_name' => ['nullable', 'string', 'max:255'],
            'customer_details.email' => ['nullable', 'email', 'max:255'],
            'customer_details.phone' => ['nullable', 'string', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'transaction_id.required' => 'Transaction ID is required',
            'transaction_id.exists' => 'Selected transaction does not exist',
            'customer_details.array' => 'Customer details must be an array',
            'customer_details.email.email' => 'Email must be a valid email address',
        ];
    }

    protected function prepareForValidation(): void
    {
        if (!$this->has('customer_details')) {
            $this->merge([
                'customer_details' => [],
            ]);
        }
    }
}
