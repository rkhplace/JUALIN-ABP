import React, { useState, useRef, useEffect } from 'react';

interface SelectOption {
  value: string;
  label: string;
}

interface SelectProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  options: SelectOption[];
  placeholder?: string;
  required?: boolean;
  error?: string;
  disabled?: boolean;
}

const Select: React.FC<SelectProps> = ({
  label,
  value,
  onChange,
  options,
  placeholder = 'Select an option',
  required = false,
  error,
  disabled = false,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const selectRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (selectRef.current && !selectRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    setIsOpen(false);
  };

  const selectedOption = options.find(option => option.value === value);

  return (
    <div className="relative" ref={selectRef}>
      <label className="block text-sm font-medium text-gray-700 mb-2">
        {label} {required && <span className="text-red-500">*</span>}
      </label>
      
      <button
        type="button"
        onClick={() => !disabled && setIsOpen(!isOpen)}
        disabled={disabled}
        className={`
            w-full px-4 py-3 text-left bg-white border rounded-2xl shadow-sm 
            focus:outline-none focus:ring-2 focus:ring-[#E83030] focus:border-[#E83030]
            transition-all duration-200 flex items-center justify-between
            ${disabled ? 'bg-gray-50 cursor-not-allowed opacity-50' : 'hover:border-gray-300 cursor-pointer'}
            ${error ? 'border-red-500' : 'border-gray-200'}
            ${!disabled && isOpen ? 'ring-2 ring-[#E83030] border-[#E83030]' : ''}
          `}
      >
        <span className={value ? 'text-gray-900' : 'text-gray-400'}>
          {selectedOption?.label || placeholder}
        </span>
        <svg
          className={`w-5 h-5 text-gray-400 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-2 bg-white border border-gray-200 rounded-2xl shadow-xl overflow-hidden">
          <ul className="py-2 max-h-60 overflow-auto">
            {options.map((option) => (
              <li
                key={option.value}
                onClick={() => option.value && handleSelect(option.value)}
                className={`
                  px-4 py-3 text-sm cursor-pointer transition-all duration-200
                  ${!option.value ? 'text-gray-400 cursor-not-allowed' : ''}
                  ${value === option.value 
                    ? 'bg-[#E83030] text-white font-medium' 
                    : option.value ? 'text-gray-900 hover:bg-gray-50' : ''
                  }
                  first:rounded-t-2xl last:rounded-b-2xl
                `}
              >
                {option.label}
              </li>
            ))}
          </ul>
        </div>
      )}

      {error && (
        <p className="mt-2 text-sm text-red-600">{error}</p>
      )}
    </div>
  );
};

export default Select;