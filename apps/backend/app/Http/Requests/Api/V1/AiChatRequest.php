<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class AiChatRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'messages' => ['required', 'array', 'min:1', 'max:20'],
            'messages.*' => ['required', 'array'],
            'messages.*.role' => ['required', 'string', 'in:user,assistant'],
            'messages.*.content' => ['required', 'string', 'min:1', 'max:2500'],
            'financial_context' => ['nullable', 'array', 'max:8'],
            'financial_context.income' => ['nullable', 'numeric'],
            'financial_context.expense' => ['nullable', 'numeric'],
            'financial_context.net_cashflow' => ['nullable', 'numeric'],
            'financial_context.savings_rate' => ['nullable', 'numeric', 'between:-10,10'],
            'financial_context.top_expense_category' => ['nullable', 'string', 'max:100'],
            'financial_context.top_expense_value' => ['nullable', 'numeric'],
            'financial_context.period_start' => ['nullable', 'date_format:Y-m-d'],
            'financial_context.period_end' => ['nullable', 'date_format:Y-m-d'],
        ];
    }
}
