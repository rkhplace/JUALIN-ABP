"use client";
import React from "react";
import { useDropdown } from "../../hooks/useDropdown";

const DropdownMenu = ({ trigger, items, position = "right" }) => {
  const { isOpen, setIsOpen, ref } = useDropdown();

  const handleItemClick = (onClick) => {
    onClick();
    setIsOpen(false);
  };

  const positionClasses = {
    right: "right-0 top-8",
    left: "left-0 top-8",
    bottom: "bottom-full left-0 mb-2",
    top: "top-full left-0 mt-2"
  };

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="p-1 hover:bg-gray-100 rounded-full transition-colors"
      >
        {trigger}
      </button>
      
      {isOpen && (
        <div className={`absolute ${positionClasses[position]} w-48 bg-white rounded-lg shadow-lg border z-10`}>
          {items.map((item, index) => (
            <button
              key={index}
              onClick={() => handleItemClick(item.onClick)}
              className={`w-full text-left px-4 py-2 text-sm transition-colors ${
                item.variant === 'danger' 
                  ? 'text-red-600 hover:bg-red-50' 
                  : 'text-gray-700 hover:bg-gray-50'
              } ${
                index === 0 ? 'rounded-t-lg' : ''
              } ${
                index === items.length - 1 ? 'rounded-b-lg' : ''
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

export default DropdownMenu;