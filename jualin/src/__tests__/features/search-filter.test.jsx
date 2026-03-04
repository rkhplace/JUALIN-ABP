import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import SearchBar from '@/components/ui/SearchBar';

// Mock values to be adjustable in tests
let mockPush = jest.fn();
let mockSearchParams = new URLSearchParams();
let mockPathname = '/';

jest.mock('next/navigation', () => ({
    useRouter: () => ({
        push: mockPush,
    }),
    useSearchParams: () => mockSearchParams,
    usePathname: () => mockPathname,
}));

describe('Search/Filter Feature (SearchBar)', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockPush = jest.fn();
        mockSearchParams = new URLSearchParams();
        mockPathname = '/';
    });

    test('should render search input', () => {
        render(<SearchBar />);
        expect(screen.getByPlaceholderText(/cari produk/i)).toBeInTheDocument();
    });

    test('should populate input from URL query', () => {
        mockSearchParams.set('q', 'Laptop');
        render(<SearchBar />);
        const input = screen.getByPlaceholderText(/cari produk/i);
        expect(input.value).toBe('Laptop');
    });

    test('should navigate to /products with query when not on products page', () => {
        mockPathname = '/dashboard';
        render(<SearchBar />);
        const input = screen.getByPlaceholderText(/cari produk/i);
        fireEvent.change(input, { target: { value: 'Phone' } });
        fireEvent.keyDown(input, { key: 'Enter', code: 'Enter' });

        expect(mockPush).toHaveBeenCalledWith('/products?q=Phone');
    });

    test('should update query params when already on /products', () => {
        mockPathname = '/products';
        mockSearchParams.set('category', 'electronics');
        mockSearchParams.set('page', '2');

        render(<SearchBar />);
        const input = screen.getByPlaceholderText(/cari produk/i);
        fireEvent.change(input, { target: { value: 'Shoes' } });
        fireEvent.keyDown(input, { key: 'Enter', code: 'Enter' });

        // Logic: q=Shoes, delete category, set page=1
        expect(mockPush).toHaveBeenCalledWith(expect.stringContaining('q=Shoes'));
        expect(mockPush).toHaveBeenCalledWith(expect.stringContaining('page=1'));
        expect(mockPush).not.toHaveBeenCalledWith(expect.stringContaining('category=electronics'));
    });

    test('should remove q param if empty search submitted on /products', () => {
        mockPathname = '/products';
        mockSearchParams.set('q', 'Old');

        render(<SearchBar />);
        const input = screen.getByPlaceholderText(/cari produk/i);
        fireEvent.change(input, { target: { value: '' } });
        fireEvent.keyDown(input, { key: 'Enter', code: 'Enter' });

        // Logic: delete q, set page=1
        const calledUrl = mockPush.mock.calls[0][0]; // Check first arg
        expect(calledUrl).not.toContain('q=');
        expect(calledUrl).toContain('page=1');
    });
});
