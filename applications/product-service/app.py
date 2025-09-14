from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os
import logging
from datetime import datetime
import uuid
from prometheus_client import Counter, Histogram, generate_latest
import time

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Rate limiting
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Metrics
REQUEST_COUNT = Counter('product_service_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('product_service_request_duration_seconds', 'Request latency')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# In-memory product store (replace with database in production)
products = [
    {
        "id": "1",
        "name": "Laptop",
        "description": "High-performance laptop",
        "price": 999.99,
        "category": "Electronics",
        "stock": 50,
        "created_at": "2024-01-01T00:00:00Z"
    },
    {
        "id": "2", 
        "name": "Smartphone",
        "description": "Latest smartphone",
        "price": 699.99,
        "category": "Electronics",
        "stock": 100,
        "created_at": "2024-01-01T00:00:00Z"
    }
]

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    # Record metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    if hasattr(request, 'start_time'):
        REQUEST_LATENCY.observe(time.time() - request.start_time)
    
    return response

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "product-service",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()

@app.route('/products', methods=['GET'])
@limiter.limit("100 per minute")
def get_products():
    """Get all products with optional filtering"""
    try:
        category = request.args.get('category')
        min_price = request.args.get('min_price', type=float)
        max_price = request.args.get('max_price', type=float)
        
        filtered_products = products.copy()
        
        if category:
            filtered_products = [p for p in filtered_products if p['category'].lower() == category.lower()]
        
        if min_price is not None:
            filtered_products = [p for p in filtered_products if p['price'] >= min_price]
            
        if max_price is not None:
            filtered_products = [p for p in filtered_products if p['price'] <= max_price]
        
        logger.info(f"Retrieved {len(filtered_products)} products")
        
        return jsonify({
            "products": filtered_products,
            "total": len(filtered_products),
            "timestamp": datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Error retrieving products: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/products/<product_id>', methods=['GET'])
@limiter.limit("200 per minute")
def get_product(product_id):
    """Get a specific product by ID"""
    try:
        product = next((p for p in products if p['id'] == product_id), None)
        
        if not product:
            return jsonify({"error": "Product not found"}), 404
        
        logger.info(f"Retrieved product {product_id}")
        return jsonify(product), 200
        
    except Exception as e:
        logger.error(f"Error retrieving product {product_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/products', methods=['POST'])
@limiter.limit("10 per minute")
def create_product():
    """Create a new product"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'description', 'price', 'category', 'stock']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Validate data types
        if not isinstance(data['price'], (int, float)) or data['price'] <= 0:
            return jsonify({"error": "Price must be a positive number"}), 400
            
        if not isinstance(data['stock'], int) or data['stock'] < 0:
            return jsonify({"error": "Stock must be a non-negative integer"}), 400
        
        # Create new product
        new_product = {
            "id": str(uuid.uuid4()),
            "name": data['name'],
            "description": data['description'],
            "price": float(data['price']),
            "category": data['category'],
            "stock": int(data['stock']),
            "created_at": datetime.utcnow().isoformat()
        }
        
        products.append(new_product)
        
        logger.info(f"Created product {new_product['id']}")
        return jsonify(new_product), 201
        
    except Exception as e:
        logger.error(f"Error creating product: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/products/<product_id>', methods=['PUT'])
@limiter.limit("20 per minute")
def update_product(product_id):
    """Update an existing product"""
    try:
        product = next((p for p in products if p['id'] == product_id), None)
        
        if not product:
            return jsonify({"error": "Product not found"}), 404
        
        data = request.get_json()
        
        # Update fields if provided
        if 'name' in data:
            product['name'] = data['name']
        if 'description' in data:
            product['description'] = data['description']
        if 'price' in data:
            if not isinstance(data['price'], (int, float)) or data['price'] <= 0:
                return jsonify({"error": "Price must be a positive number"}), 400
            product['price'] = float(data['price'])
        if 'category' in data:
            product['category'] = data['category']
        if 'stock' in data:
            if not isinstance(data['stock'], int) or data['stock'] < 0:
                return jsonify({"error": "Stock must be a non-negative integer"}), 400
            product['stock'] = int(data['stock'])
        
        product['updated_at'] = datetime.utcnow().isoformat()
        
        logger.info(f"Updated product {product_id}")
        return jsonify(product), 200
        
    except Exception as e:
        logger.error(f"Error updating product {product_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/products/<product_id>', methods=['DELETE'])
@limiter.limit("5 per minute")
def delete_product(product_id):
    """Delete a product"""
    try:
        global products
        product = next((p for p in products if p['id'] == product_id), None)
        
        if not product:
            return jsonify({"error": "Product not found"}), 404
        
        products = [p for p in products if p['id'] != product_id]
        
        logger.info(f"Deleted product {product_id}")
        return jsonify({"message": "Product deleted successfully"}), 200
        
    except Exception as e:
        logger.error(f"Error deleting product {product_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/products/<product_id>/stock', methods=['PATCH'])
@limiter.limit("50 per minute")
def update_stock(product_id):
    """Update product stock"""
    try:
        product = next((p for p in products if p['id'] == product_id), None)
        
        if not product:
            return jsonify({"error": "Product not found"}), 404
        
        data = request.get_json()
        
        if 'quantity' not in data:
            return jsonify({"error": "Missing quantity field"}), 400
        
        quantity = data['quantity']
        if not isinstance(quantity, int):
            return jsonify({"error": "Quantity must be an integer"}), 400
        
        # Update stock
        new_stock = product['stock'] + quantity
        if new_stock < 0:
            return jsonify({"error": "Insufficient stock"}), 400
        
        product['stock'] = new_stock
        product['updated_at'] = datetime.utcnow().isoformat()
        
        logger.info(f"Updated stock for product {product_id}: {quantity}")
        return jsonify({
            "product_id": product_id,
            "previous_stock": product['stock'] - quantity,
            "current_stock": product['stock'],
            "quantity_changed": quantity
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating stock for product {product_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({"error": "Rate limit exceeded", "message": str(e.description)}), 429

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger.info(f"Starting Product Service on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)