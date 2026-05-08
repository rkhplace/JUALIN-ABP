import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { ProfileFormSection } from '@/app/(private)/profile/sections/profile-form';

describe('User Profile Feature (ProfileFormSection)', () => {
    const mockOnFieldChange = jest.fn();
    const mockOnImageSelect = jest.fn();

    const defaultForm = {
        username: 'John Doe',
        email: 'john@example.com',
        gender: 'male',
        birthday: '',
        region: '',
        city: '',
        bio: 'Hello world',
    };

    const defaultErrors = {};

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should render profile form with initial data', () => {
        render(
            <ProfileFormSection
                form={defaultForm}
                errors={defaultErrors}
                imagePreview={null}
                onFieldChange={mockOnFieldChange}
                onImageSelect={mockOnImageSelect}
            />
        );

        expect(screen.getByDisplayValue('John Doe')).toBeInTheDocument();
        expect(screen.getByDisplayValue('john@example.com')).toBeInTheDocument();
    });

    test('should call onFieldChange when input changes', () => {
        render(
            <ProfileFormSection
                form={defaultForm}
                errors={defaultErrors}
                imagePreview={null}
                onFieldChange={mockOnFieldChange}
                onImageSelect={mockOnImageSelect}
            />
        );

        const nameInput = screen.getByDisplayValue('John Doe');
        fireEvent.change(nameInput, { target: { value: 'Jane Doe' } });

        expect(mockOnFieldChange).toHaveBeenCalledWith('username', 'Jane Doe');
    });

    test('should display validation errors', () => {
        const errors = { username: 'Nama wajib diisi' };
        render(
            <ProfileFormSection
                form={defaultForm}
                errors={errors}
                imagePreview={null}
                onFieldChange={mockOnFieldChange}
                onImageSelect={mockOnImageSelect}
            />
        );

        expect(screen.getByText('Nama wajib diisi')).toBeInTheDocument();
    });
});
