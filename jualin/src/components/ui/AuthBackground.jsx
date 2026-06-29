"use client";

import React from "react";

export default function AuthBackground() {
  return (
    <div className="auth-background" aria-hidden="true">
      <span className="auth-bg-red auth-bg-red-top" />
      <span className="auth-bg-red auth-bg-red-bottom" />

      <span className="auth-bg-wave auth-bg-wave-top-a" />
      <span className="auth-bg-wave auth-bg-wave-top-b" />
      <span className="auth-bg-wave auth-bg-wave-left" />
      <span className="auth-bg-wave auth-bg-wave-mid" />
      <span className="auth-bg-wave auth-bg-wave-bottom-a" />
      <span className="auth-bg-wave auth-bg-wave-bottom-b" />

      <span className="auth-bg-curve auth-bg-curve-top" />
      <span className="auth-bg-curve auth-bg-curve-bottom" />
      <span className="auth-bg-dots auth-bg-dots-left" />
      <span className="auth-bg-dots auth-bg-dots-right" />
      <span className="auth-bg-hatch auth-bg-hatch-left" />
      <span className="auth-bg-hatch auth-bg-hatch-right" />
    </div>
  );
}
