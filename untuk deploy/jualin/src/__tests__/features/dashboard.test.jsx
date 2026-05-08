import React from 'react';
import { render, screen } from '@testing-library/react';
import Navbar from '@/components/ui/Navbar';
import { AuthContext } from '@/context/AuthProvider';

// Mock navigation
jest.mock('next/navigation', () => ({
    usePathname: () => '/dashboard',
    useSearchParams: () => new URLSearchParams(),
    useRouter: () => ({ push: jest.fn() }),
}));

// Helper to render with Auth Context
const renderWithAuth = (ui, authValue) => {
    return render(
        <AuthContext.Provider value={authValue}>
            {ui}
        </AuthContext.Provider>
    );
};

describe('Dashboard Feature (Navbar)', () => {
    test('should render guest view when not logged in', () => {
        renderWithAuth(<Navbar />, { user: null, loading: false });

        expect(screen.getByText(/masuk/i)).toBeInTheDocument();
        expect(screen.getByText(/daftar/i)).toBeInTheDocument();
        expect(screen.queryByText(/jual/i)).not.toBeInTheDocument();
    });

    test('should render seller view when logged in as seller', () => {
        const sellerUser = { id: 1, name: 'Seller User', role: 'seller' };
        renderWithAuth(<Navbar />, { user: sellerUser, loading: false });

        expect(screen.getByText(/jual/i)).toBeInTheDocument();
        expect(screen.getByText(/Seller User/i)).toBeInTheDocument();
    });

    test('should render buyer view when logged in as buyer', () => {
        const buyerUser = { id: 2, name: 'Buyer User', role: 'buyer' };
        renderWithAuth(<Navbar />, { user: buyerUser, loading: false });

        expect(screen.queryByText(/Beli/i)).not.toBeInTheDocument();
        expect(screen.getByText(/Buyer User/i)).toBeInTheDocument();
    });

    test('should render loading skeleton when auth is loading', () => {
        const { container } = renderWithAuth(<Navbar />, { user: null, loading: true });

        // Check for pulse animation class or specific skeleton structure
        // The navbar has .animate-pulse when loading
        const skeletons = container.querySelectorAll('.animate-pulse');
        expect(skeletons.length).toBeGreaterThan(0);

        expect(screen.queryByText(/masuk/i)).not.toBeInTheDocument();
    });
});
