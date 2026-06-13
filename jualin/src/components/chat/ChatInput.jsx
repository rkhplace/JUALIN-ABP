'use client';
import { useRef, useState } from 'react';
import { ImagePlus, Loader2, Send } from 'lucide-react';

export function ChatInput({ onSend, onSendImages, disabled }) {
  const [input, setInput] = useState('');
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef(null);

  const submit = () => {
    const text = input.trim();
    if (!text || disabled || uploading) return;
    onSend?.(text);
    setInput('');
  };

  const pickImages = () => {
    if (disabled || uploading) return;
    fileInputRef.current?.click();
  };

  const handleImagesChange = async (event) => {
    const files = Array.from(event.target.files || []);
    event.target.value = '';
    if (!files.length || disabled) return;

    try {
      setUploading(true);
      await onSendImages?.(files);
    } finally {
      setUploading(false);
    }
  };

  const onKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  };

  return (
    <div className="px-4 py-3 md:px-6 md:py-5 bg-white m-4 rounded-2xl shadow-md">
      <div className="relative flex items-center bg-gray-50 rounded-full border border-gray-100 focus-within:ring-2 focus-within:ring-red-100 focus-within:bg-white focus-within:border-red-200 transition-all shadow-sm hover:shadow-md">
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          multiple
          className="hidden"
          onChange={handleImagesChange}
          disabled={disabled || uploading}
        />
        <button
          onClick={pickImages}
          disabled={disabled || uploading}
          className={`ml-2 flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition-all ${!disabled && !uploading
            ? 'bg-red-50 text-red-500 hover:bg-red-100 active:scale-95'
            : 'bg-gray-100 text-gray-300 cursor-not-allowed'
            }`}
          type="button"
          aria-label="Pilih gambar dari galeri"
          title="Pilih gambar"
        >
          {uploading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <ImagePlus className="h-4 w-4" />
          )}
        </button>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={onKeyDown}
          placeholder="Ketik pesan..."
          disabled={disabled || uploading}
          className="w-full pl-3 md:pl-4 pr-12 md:pr-14 py-3 md:py-3.5 bg-transparent border-none text-sm text-gray-900 placeholder-gray-400 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed"
        />
        <button
          onClick={submit}
          disabled={disabled || uploading || !input.trim()}
          className={`absolute right-2 p-2 rounded-full transition-all duration-300 ${!disabled && !uploading && input.trim()
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
