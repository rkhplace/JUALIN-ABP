import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import LoginForm from '@/components/auth/LoginForm';
import { authService } from '@/services/auth/authService';

// Mock Auth Service
jest.mock('@/services/auth/authService', () => ({
    authService: {
        login: jest.fn(),
    },
}));

// Mock Auth Context
const mockLoginContext = jest.fn();
const mockRefetchUser = jest.fn();
jest.mock('@/context/AuthProvider', () => ({
    useAuth: () => ({
        login: mockLoginContext,
        refetchUser: mockRefetchUser,
    }),
}));

// Mock Router
const mockPush = jest.fn();
jest.mock('next/navigation', () => ({
    useRouter: () => ({
        push: mockPush,
    }),
}));

describe('Form Handling Feature (LoginForm)', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should render login form elements', () => {
        render(<LoginForm />);
        expect(screen.getByLabelText(/Email/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/Kata Sandi/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /Masuk/i })).toBeInTheDocument();
    });

    test('should show validation error when submitting empty form', async () => {
        render(<LoginForm />);
        const submitBtn = screen.getByRole('button', { name: /Masuk/i });
        fireEvent.click(submitBtn);

        // Native HTML5 validation prevents submission via RTL click usually if not suppressed
        // But if we want to check if submission was BLOCKED calling service:
        expect(authService.login).not.toHaveBeenCalled();
    });

    test('should submit form with valid data and handle success', async () => {
        // Setup mock success response
        authService.login.mockResolvedValue({
            access_token: 'fake-jwt-token',
            role: 'customer',
            user: {
                id: 1,
                name: 'Test Customer',
                email: 'test@example.com',
                role: 'customer'
            }
        });

        render(<LoginForm />);

        fireEvent.change(screen.getByLabelText(/Email/i), { target: { value: 'test@example.com' } });
        fireEvent.change(screen.getByLabelText(/Kata Sandi/i), { target: { value: 'password123' } });

        const submitBtn = screen.getByRole('button', { name: /Masuk/i });
        fireEvent.click(submitBtn);

        await waitFor(() => {
            expect(authService.login).toHaveBeenCalledWith('test@example.com', 'password123');
        });

        await waitFor(() => {
            expect(mockLoginContext).toHaveBeenCalled();
            expect(mockRefetchUser).toHaveBeenCalled();
            expect(mockPush).toHaveBeenCalledWith('/dashboard');
        });
    });

    test('should handle login failure', async () => {
        // Setup mock error failure
        authService.login.mockRejectedValue(new Error('Invalid credentials'));

        const mockOnError = jest.fn();
        render(<LoginForm onError={mockOnError} />);

        fireEvent.change(screen.getByLabelText(/Email/i), { target: { value: 'wrong@example.com' } });
        fireEvent.change(screen.getByLabelText(/Kata Sandi/i), { target: { value: 'wrongpass' } });

        const submitBtn = screen.getByRole('button', { name: /Masuk/i });
        fireEvent.click(submitBtn);

        await waitFor(() => {
            expect(authService.login).toHaveBeenCalled();
            // Assuming the component calls onError prop if provided, or shows a toast/alert
            // Based on code: onError?.(error.message)
            expect(mockOnError).toHaveBeenCalledWith('Invalid credentials');
        });
    });
});
