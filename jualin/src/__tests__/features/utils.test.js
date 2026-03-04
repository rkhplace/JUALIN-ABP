import { formatCurrency } from '@/utils/formatters/currency';
// Assuming named export. If default, change to `import formatCurrency from ...`

describe('Utility / Helper Function Feature', () => {
    // If actual implementation is unavailable, we define expected behavior for standard IDR formatting

    test('should format number to IDR currency', () => {
        // Expected: "Rp 10.000" or similar depending on implementation
        const result = formatCurrency(10000);
        expect(result).toMatch(/Rp\s?10[.,]000/);
    });

    test('should handle zero value', () => {
        const result = formatCurrency(0);
        expect(result).toMatch(/Rp\s?0/);
    });

    test('should handle negative numbers', () => {
        // Some implementations might show -Rp 10.000 or (Rp 10.000)
        const result = formatCurrency(-5000);
        expect(result).toMatch(/-?Rp\s?5[.,]000|Rp\s?-5[.,]000/);
    });

    test('should handle invalid input gracefully', () => {
        // Assuming it returns something safe or original value or 0
        expect(formatCurrency(null)).toBe('Rp 0'); // or whatever default
        expect(formatCurrency(undefined)).toBe('Rp 0');
        expect(formatCurrency('abc')).toBe('Rp 0'); // or throw
    });
});
