'use client';

export function ChatBubble({ message }) {
  const isMe = message.isMe || message.sender === 'You';

  return (
    <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} mb-4 px-6`}>
      <div className={`flex flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[70%]`}>
        {/* Timestamp above bubble */}
        <span className="text-xs text-gray-400 mb-1.5 px-1">
          {message.time}
        </span>

        {/* Message Bubble */}
        <div
          className={`px-5 py-3 rounded-3xl text-sm leading-relaxed ${isMe
              ? 'bg-red-500 text-white rounded-br-md shadow-md'
              : 'bg-gray-100 text-gray-900 rounded-bl-md shadow-sm'
            }`}
        >
          <p className="break-words whitespace-pre-wrap">{message.content}</p>
        </div>
      </div>
    </div>
  );
}
