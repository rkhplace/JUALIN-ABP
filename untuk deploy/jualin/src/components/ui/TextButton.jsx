import React from "react";

const TextButton = ({ children, href, className = "", ...props }) => (
  <a
    href={href}
    className={`text-black hover:text-gray-700 font-semibold px-2 py-1 rounded transition duration-150 ${className}`}
    {...props}
  >
    {children}
  </a>
);

export default TextButton;