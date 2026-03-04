'use client';
import React from 'react';

export function Badge({ className = '', children }) {
  return <span className={`inline-flex items-center justify-center px-2 py-0.5 text-xs font-medium ${className}`}>{children}</span>;
}

export default Badge;