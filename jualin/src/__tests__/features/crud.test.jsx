import { productService } from '@/services/product/productService';
import { fetcher } from '@/lib/fetcher';

// Mock the fetcher
jest.mock('@/lib/fetcher', () => ({
    fetcher: {
        get: jest.fn(),
        post: jest.fn(),
        patch: jest.fn(),
        delete: jest.fn(),
        upload: jest.fn(), // for create/update with image
    },
}));

describe('CRUD Feature (Product Service)', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should fetch list of products successfully', async () => {
        const mockResponse = {
            products: [
                { id: 1, name: 'Product 1', price: 10000, category: 'Food' },
                { id: 2, name: 'Product 2', price: 20000, category: 'Drink' },
            ],
            totalProducts: 2,
        };

        fetcher.get.mockResolvedValue(mockResponse);

        const result = await productService.fetchAll();

        expect(fetcher.get).toHaveBeenCalledWith('/api/v1/products', { params: {} });
        expect(result.products).toHaveLength(2);
        expect(result.products[0].name).toBe('Product 1');
    });

    test('should create a product successfully', async () => {
        // Mock localstorage for token
        Storage.prototype.getItem = jest.fn((key) => {
            if (key === 'token') return 'fake-token';
            if (key === 'user') return JSON.stringify({ id: 123 });
            return null;
        });

        const newProduct = { name: 'New Product', price: 30000, category: 'Food' };
        const mockApiResponse = { data: { id: 3, ...newProduct } };

        fetcher.post.mockResolvedValue(mockApiResponse);

        const result = await productService.create(newProduct);

        expect(fetcher.post).toHaveBeenCalledWith(
            '/api/v1/products',
            expect.objectContaining({
                name: 'New Product',
                seller_id: 123
            })
        );
        expect(result.name).toBe('New Product');
    });

    test('should delete a product successfully', async () => {
        fetcher.delete.mockResolvedValue({ success: true });

        const result = await productService.delete(1);

        expect(fetcher.delete).toHaveBeenCalledWith('/api/v1/products/1/delete');
        expect(result).toBe(true);
    });
});
