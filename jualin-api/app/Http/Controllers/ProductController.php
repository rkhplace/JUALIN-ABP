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
        $filters = $request->validated();

        // Admin bisa melihat semua produk, seller hanya miliknya sendiri
        if (Auth::user()->role !== 'admin') {
            $filters['seller_id'] = Auth::id();
        }

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

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image');
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

        if ($product->seller_id !== Auth::id() && Auth::user()->role !== 'admin') {
            return ApiResponse::error('Forbidden', null, 403);
        }

        $data = $request->validated();

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image');
        }

        $updatedProduct = $this->repo->update($id, $data);
        return ApiResponse::success('Product updated successfully', new ProductResponse($updatedProduct));
    }

    public function destroy($id): JsonResponse
    {
        $product = $this->repo->find($id);
        if (!$product) {
            return ApiResponse::error('Product not found', null, 404);
        }

        if ($product->seller_id !== Auth::id() && Auth::user()->role !== 'admin') {
            return ApiResponse::error('Forbidden', null, 403);
        }
        $this->repo->delete($id);
        return ApiResponse::success('Product deleted successfully', null);
    }
}
