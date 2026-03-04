import React from 'react';
import { render, screen } from '@testing-library/react';

// A generic reusable component for testing UI states, 
// or importing a real one if available. 
// Let's assume a generic Card or Button component tests, or checking "Loading..." text global.

const LoadingComponent = ({ isLoading, data }) => {
    if (isLoading) return <div data-testid="loading">Loading...</div>;
    if (!data) return <div>Empty Data</div>;
    return <div>{data}</div>;
};

describe('UI State Feature', () => {
    test('should render loading indicator when loading', () => {
        render(<LoadingComponent isLoading={true} />);
        expect(screen.getByTestId('loading')).toBeInTheDocument();
        expect(screen.queryByText('Empty Data')).not.toBeInTheDocument();
    });

    test('should render empty state when no data and not loading', () => {
        render(<LoadingComponent isLoading={false} data={null} />);
        expect(screen.getByText('Empty Data')).toBeInTheDocument();
        expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    });

    test('should render content when data exists and not loading', () => {
        render(<LoadingComponent isLoading={false} data="Hello World" />);
        expect(screen.getByText('Hello World')).toBeInTheDocument();
        expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
        expect(screen.queryByText('Empty Data')).not.toBeInTheDocument();
    });

    test('should disable button when processing', () => {
        const Button = ({ disabled, children }) => (
            <button disabled={disabled}>{children}</button>
        );

        const { rerender } = render(<Button disabled={false}>Click me</Button>);
        expect(screen.getByText('Click me')).toBeEnabled();

        rerender(<Button disabled={true}>Click me</Button>);
        expect(screen.getByText('Click me')).toBeDisabled();
    });
});
