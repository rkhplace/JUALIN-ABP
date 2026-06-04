import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

class ProductCard extends StatelessWidget {
  final int productId;
  final String title;
  final String category;
  final int price;
  final String description;
  final String sellerName;
  final int stock;
  final String imagePath;

  const ProductCard({
    super.key,
    required this.productId,
    required this.title,
    required this.category,
    required this.price,
    required this.description,
    required this.sellerName,
    required this.stock,
    this.imagePath = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product_detail', arguments: productId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF8F9FA),
                child: imagePath.isNotEmpty
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.image_outlined,
                              size: 40, color: Colors.grey[400]),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.image_outlined,
                            size: 40, color: Colors.grey[400]),
                      ),
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1890FF),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Description
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Seller Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: Color(0xFFF5222D)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF5222D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price Area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          formatCurrency(price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stok: $stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
