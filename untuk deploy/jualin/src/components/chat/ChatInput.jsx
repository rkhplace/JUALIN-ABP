'use client';
import { useState } from 'react';
import { Send } from 'lucide-react';

export function ChatInput({ onSend, disabled }) {
  const [input, setInput] = useState('');

  const submit = () => {
    const text = input.trim();
    if (!text || disabled) return;
    onSend?.(text);
    setInput('');
  };

  const onKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  };

  return (
    <div className="px-6 py-5 bg-white m-4 rounded-2xl shadow-md">
      <div className="relative flex items-center bg-gray-50 rounded-full border border-gray-100 focus-within:ring-2 focus-within:ring-red-100 focus-within:bg-white focus-within:border-red-200 transition-all shadow-sm hover:shadow-md">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={onKeyDown}
          placeholder="Ketik pesan..."
          disabled={disabled}
          className="w-full pl-6 pr-14 py-3.5 bg-transparent border-none text-sm text-gray-900 placeholder-gray-400 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed"
        />
        <button
          onClick={submit}
          disabled={disabled || !input.trim()}
          className={`absolute right-2 p-2 rounded-full transition-all duration-300 ${!disabled && input.trim()
            ? 'bg-gradient-to-r from-red-500 to-red-600 text-white shadow-lg shadow-red-200 transform hover:scale-110 active:scale-95'
            : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            }`}
          type="button"
          aria-label="Kirim pesan"
        >
          <Send className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
