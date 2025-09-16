from flask import Flask

def create_app():
    app = Flask(__name__)
    
    @app.route('/health')
    def health():
        return {'status': 'healthy', 'service': 'product-service'}
    
    @app.route('/products')
    def products():
        return {'products': [], 'message': 'Product service running'}
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000)