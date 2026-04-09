<?php

namespace App\Http\Controllers;
use App\Http\Requests\ProductFilterRequest;
use App\Http\Requests\ProductStoreRequest;
use App\Http\Requests\ProductUpdateRequest;
use App\Repositories\ProductRepository;
use App\Http\Responses\ApiResponse;
use App\Http\Responses\ProductResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ProductController extends Controller
{
    protected $repo;

    public function __construct(ProductRepository $repo)
    {
        $this->repo = $repo;
    }

    public function index(ProductFilterRequest $request)
    {
        $filters = $request->validated();

        $paginated = $this->repo->getAll($filters);

        return response()->json([
            'products' => $paginated->items(),
            'totalProducts' => $paginated->total(),
            'totalPages' => $paginated->lastPage() ?: 1, // Minimal bernilai 1
            'currentPage' => $paginated->currentPage()
        ]);
    }

    public function indexMe(ProductFilterRequest $request)
    {
        $user = Auth::user();
        if (!$user) {
            return ApiResponse::error('Unauthorized', null, 401);
        }

        $filters = $request->validated();

        // CRITICAL: seller hanya bisa lihat produk mereka sendiri
        // Admin boleh lihat semua produk
        if ($user->role === 'admin') {
            // Admin bisa melihat semua, or filter jika query param ada
            // Jangan override jika admin explicit filter seller_id
        } else if ($user->role === 'seller') {
            // Seller HARUS hanya lihat produk milik mereka - FORCE SET
            $filters['seller_id'] = $user->id;
        } else {
            // Role lain tidak boleh akses endpoint ini
            return ApiResponse::error('Forbidden', null, 403);
        }

        Log::debug('Seller products filter', [
            'user_id' => $user->id,
            'user_role' => $user->role,
            'filters' => $filters
        ]);

        $paginated = $this->repo->getAll($filters);

        return response()->json([
            'products' => $paginated->items(),
            'totalProducts' => $paginated->total(),
            'totalPages' => $paginated->lastPage() ?: 1,
            'currentPage' => $paginated->currentPage()
        ]);
    }

    public function store(ProductStoreRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['seller_id'] = Auth::id();

        // Handle multiple images
        if ($request->hasFile('images')) {
            $data['images'] = $request->file('images');
        }

        $product = $this->repo->create($data);
        return ApiResponse::success('Product created successfully', new ProductResponse($product), 201);
    }

    public function show($id): JsonResponse
    {
        $product = $this->repo->find($id);
        if (!$product) {
            return ApiResponse::error('Product not found', null, 404);
        }
        return ApiResponse::success('Product retrieved successfully', new ProductResponse($product));
    }

    public function update(ProductUpdateRequest $request, $id): JsonResponse
    {
        $product = $this->repo->find($id);
        if (!$product) {
            return ApiResponse::error('Product not found', null, 404);
        }

        // Check authorization: only seller of product or admin can update
        $user = Auth::user();
        if (!$user) {
            return ApiResponse::error('Unauthorized', null, 401);
        }

        if ($product->seller_id !== $user->id && $user->role !== 'admin') {
            return ApiResponse::error('Forbidden', null, 403);
        }

        $data = $request->validated();

        // Handle multiple images
        if ($request->hasFile('images')) {
            $data['images'] = $request->file('images');
        }

        $updatedProduct = $this->repo->update($id, $data);
        return ApiResponse::success('Product updated successfully', new ProductResponse($updatedProduct));
    }

    public function destroy($id): JsonResponse
    {
        try {
            Log::info("Delete product attempt", [
                'product_id' => $id,
                'user_id' => Auth::id(),
                'user_role' => Auth::user()?->role ?? 'null'
            ]);

            $product = $this->repo->find($id);
            if (!$product) {
                Log::info("Product not found", ['product_id' => $id]);
                return ApiResponse::error('Product not found', null, 404);
            }

            Log::info("Product found", [
                'product_id' => $product->id,
                'seller_id' => $product->seller_id
            ]);

            // Check authorization: only seller of product or admin can delete
            $user = Auth::user();
            if (!$user) {
                Log::warning("No authenticated user for delete", ['product_id' => $id]);
                return ApiResponse::error('Unauthorized', null, 401);
            }

            Log::info("Auth user check", [
                'user_id' => $user->id,
                'user_role' => $user->role,
                'product_seller_id' => $product->seller_id,
                'is_seller' => $product->seller_id === $user->id,
                'is_admin' => $user->role === 'admin'
            ]);

            if ($product->seller_id !== $user->id && $user->role !== 'admin') {
                Log::warning("Authorization failed for product delete", [
                    'user_id' => $user->id,
                    'user_role' => $user->role,
                    'product_seller_id' => $product->seller_id
                ]);
                return ApiResponse::error('Forbidden', null, 403);
            }

            $deleted = $this->repo->delete($id);
            if ($deleted) {
                Log::info("Product deleted successfully", ['product_id' => $id]);
                return ApiResponse::success('Product deleted successfully', null);
            } else {
                Log::error("Delete repository returned false", ['product_id' => $id]);
                return ApiResponse::error('Failed to delete product', null, 500);
            }
        } catch (\Exception $e) {
            Log::error("Exception during product delete", [
                'product_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ApiResponse::error('Internal server error', null, 500);
        }
    }
}
