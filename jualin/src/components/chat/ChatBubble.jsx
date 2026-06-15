'use client';

export function ChatBubble({ message }) {
  const isMe = message.isMe || message.sender === 'You';
  const isImage =
    message.type === 'image' ||
    (typeof message.content === 'string' &&
      message.content.includes('/chat-images/'));

  if (isImage) {
    return (
      <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} mb-3 md:mb-4 px-3 md:px-6`}>
        <div className={`flex min-w-0 flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[78%] md:max-w-[360px]`}>
          <span className="text-xs text-gray-400 mb-1.5 px-1">
            {message.time}
          </span>

          <div
            className={`overflow-hidden rounded-3xl shadow-md border ${isMe
                ? 'bg-red-500 border-red-500 rounded-br-md'
                : 'bg-white border-red-100 rounded-bl-md'
              }`}
          >
            <div className="bg-gray-100">
              <img
                src={message.content}
                alt="Foto produk di chat"
                className="block h-56 w-56 md:h-72 md:w-72 object-cover"
                loading="lazy"
              />
            </div>
            <div className={`flex items-center gap-2 px-3 py-2 text-xs font-bold ${isMe ? 'text-white' : 'text-red-500'}`}>
              <span className={`inline-flex h-6 w-6 items-center justify-center rounded-full ${isMe ? 'bg-white/15' : 'bg-red-50'}`}>
                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </span>
              Foto Produk
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} mb-3 md:mb-4 px-3 md:px-6 min-w-0`}>
      <div className={`flex min-w-0 flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[78%] md:max-w-[70%]`}>
        {/* Timestamp above bubble */}
        <span className="text-xs text-gray-400 mb-1.5 px-1">
          {message.time}
        </span>

        {/* Message Bubble */}
        <div
          className={`min-w-0 max-w-full px-4 py-2.5 md:px-5 md:py-3 rounded-3xl text-sm leading-relaxed ${isMe
              ? 'bg-red-500 text-white rounded-br-md shadow-md'
              : 'bg-gray-100 text-gray-900 rounded-bl-md shadow-sm'
            }`}
        >
          <p className="whitespace-pre-wrap break-all [overflow-wrap:anywhere]">{message.content}</p>
        </div>
      </div>
    </div>
  );
}
