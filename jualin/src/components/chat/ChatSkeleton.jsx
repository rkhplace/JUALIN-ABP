import React from "react";

export function ChatSkeleton() {
    return (
        <div className="relative flex h-[calc(100vh-4rem)] md:h-[800px] bg-white overflow-hidden shadow-lg border border-gray-100">
            {/* Sidebar Skeleton - 30% width */}
            <div className="hidden md:block w-[30%] border-r border-gray-100 p-4">
                <div className="flex items-center space-x-2 mb-6">
                    <div className="h-6 w-32 bg-gray-200 rounded animate-pulse" />
                </div>

                {/* Chat List Skeletons */}
                <div className="space-y-4">
                    {[...Array(5)].map((_, i) => (
                        <div key={i} className="flex items-center space-x-3">
                            <div className="h-10 w-10 bg-gray-200 rounded-full animate-pulse flex-shrink-0" />
                            <div className="flex-1 space-y-2">
                                <div className="h-4 w-3/4 bg-gray-200 rounded animate-pulse" />
                                <div className="h-3 w-1/2 bg-gray-200 rounded animate-pulse" />
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Chat Window Skeleton - 70% width */}
            <div className="flex-1 flex flex-col min-w-0">
                {/* Header */}
                <div className="h-16 border-b border-gray-100 flex items-center px-4 space-x-3">
                    <div className="h-10 w-10 bg-gray-200 rounded-full animate-pulse" />
                    <div className="h-4 w-40 bg-gray-200 rounded animate-pulse" />
                </div>

                {/* Messages Area */}
                <div className="flex-1 p-4 space-y-4 overflow-y-auto">
                    {[...Array(4)].map((_, i) => (
                        <React.Fragment key={i}>
                            <div className={`flex ${i % 2 === 0 ? 'justify-start' : 'justify-end'}`}>
                                <div className={`h-16 w-64 bg-gray-200 rounded-lg animate-pulse`} />
                            </div>
                        </React.Fragment>
                    ))}
                </div>

                {/* Input Area */}
                <div className="p-4 border-t border-gray-100">
                    <div className="h-12 w-full bg-gray-200 rounded-lg animate-pulse" />
                </div>
            </div>
        </div>
    );
}
