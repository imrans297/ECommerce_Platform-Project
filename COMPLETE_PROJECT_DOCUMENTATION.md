# Complete Enterprise E-commerce Platform - Detailed Implementation Guide
## From Infrastructure to Production Deployment

---

## 🎯 **Project Overview**

**Project Name:** Enterprise E-commerce Microservices Platform  
**Timeline:** 8 weeks implementation  
**Architecture:** Cloud-native microservices with complete DevOps lifecycle  
**Scale:** Production-ready with high availability and security  

### **Business Context**
Multi-tenant e-commerce platform supporting:
- User management and authentication
- Product catalog with search capabilities
- Order processing and payment integration
- Real-time notifications
- Admin dashboard and analytics

---

## 🏗️ **Complete Application Architecture**

### **Frontend Application (React.js)**
```
Frontend Architecture:
├── React.js 18 with TypeScript
├── Redux Toolkit for state management
├── Material-UI for components
├── Axios for API communication
├── React Router for navigation
└── Jest + React Testing Library
```

**Frontend Features:**
- Responsive design for mobile/desktop
- User authentication with JWT
- Product browsing and search
- Shopping cart functionality
- Order tracking
- Admin dashboard

### **Backend Microservices**

#### **1. User Service (Node.js/Express)**
```javascript
// Core Features:
- User registration/login
- JWT token management
- Profile management
- Role-based access control
- Password reset functionality

// Technology Stack:
- Node.js 18 + Express.js
- MongoDB for user data
- bcryptjs for password hashing
- jsonwebtoken for JWT
- Mongoose ODM
```

#### **2. Product Service (Python/Flask)**
```python
# Core Features:
- Product catalog management
- Category management
- Search and filtering
- Inventory tracking
- Price management

# Technology Stack:
- Python 3.9 + Flask
- PostgreSQL for product data
- SQLAlchemy ORM
- Redis for caching
- Elasticsearch for search
```

#### **3. Order Service (Java/Spring Boot)**
```java
// Core Features:
- Order creation and management
- Payment processing integration
- Order status tracking
- Invoice generation
- Inventory updates

// Technology Stack:
- Java 17 + Spring Boot 3.0
- PostgreSQL for order data
- Spring Data JPA
- Spring Security
- RabbitMQ for messaging
```

#### **4. Notification Service (Go)**
```go
// Core Features:
- Email notifications
- SMS notifications
- Push notifications
- Event-driven messaging
- Template management

// Technology Stack:
- Go 1.21
- Gin web framework
- Redis for queuing
- SMTP integration
- WebSocket support
```

---

## 🛠️ **Infrastructure Implementation Details**

### **Phase 1: AWS Infrastructure with Terraform**

#### **1.1 Network Infrastructure**
```hcl
# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "ecommerce-vpc-dev"
    Environment = "dev"
    Project     = "ecommerce-platform"
  }
}

# Subnets across 2 AZs
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "ecommerce-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "ecommerce-private-subnet-${count.index + 1}"
    Type = "private"
  }
}
```

#### **1.2 EKS Cluster Configuration**
```hcl
# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "ecommerce-platform-dev-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}
```

#### **1.3 Database Infrastructure**
```hcl
# RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier     = "ecommerce-db-dev"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  
  db_name  = "ecommerce"
  username = "postgres"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "ecommerce-cache-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "ecommerce-redis-dev"
  description                = "Redis cluster for ecommerce platform"
  
  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"
  
  num_cache_clusters = 2
  
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
}
```

#### **1.4 Security Groups**
```hcl
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "ecommerce-eks-cluster-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "ecommerce-rds-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_node_group.id]
  }
}
```

### **Deployment Commands & Process**
```bash
# 1. Initialize Terraform
cd infrastructure/terraform
terraform init -backend-config=backend-dev.hcl

# 2. Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# 3. Deploy in stages (recommended)
terraform apply -target='module.vpc' -var-file="environments/dev.tfvars"
terraform apply -target='module.security' -var-file="environments/dev.tfvars"
terraform apply -target='module.rds' -var-file="environments/dev.tfvars"
terraform apply -target='module.redis' -var-file="environments/dev.tfvars"
terraform apply -target='module.eks' -var-file="environments/dev.tfvars"

# 4. Full deployment
terraform apply -var-file="environments/dev.tfvars"

# 5. Configure kubectl
aws eks update-kubeconfig --name ecommerce-platform-dev-eks --region us-east-1
```

**Infrastructure Outputs:**
```
VPC ID: vpc-0123456789abcdef0
EKS Cluster: ecommerce-platform-dev-eks
RDS Endpoint: ecommerce-db-dev.xyz.us-east-1.rds.amazonaws.com
Redis Endpoint: ecommerce-redis-dev.xyz.cache.amazonaws.com
```

---

## 📱 **Application Development Details**

### **Frontend Application (React.js)**

#### **Project Structure**
```
applications/frontend/
├── public/
│   ├── index.html
│   └── favicon.ico
├── src/
│   ├── components/
│   │   ├── Header/
│   │   ├── ProductCard/
│   │   ├── ShoppingCart/
│   │   └── UserProfile/
│   ├── pages/
│   │   ├── Home/
│   │   ├── Products/
│   │   ├── Orders/
│   │   └── Admin/
│   ├── store/
│   │   ├── slices/
│   │   └── index.js
│   ├── services/
│   │   └── api.js
│   ├── utils/
│   └── App.js
├── package.json
├── Dockerfile
└── nginx.conf
```

#### **Key Frontend Components**

**1. App.js (Main Application)**
```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';

import store from './store';
import theme from './theme';
import Header from './components/Header';
import Home from './pages/Home';
import Products from './pages/Products';
import Orders from './pages/Orders';
import Login from './pages/Login';

function App() {
  return (
    <Provider store={store}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <Header />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/products" element={<Products />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/login" element={<Login />} />
          </Routes>
        </Router>
      </ThemeProvider>
    </Provider>
  );
}

export default App;
```

**2. API Service Layer**
```javascript
// services/api.js
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Request interceptor for auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const userAPI = {
  login: (credentials) => api.post('/auth/login', credentials),
  register: (userData) => api.post('/auth/register', userData),
  getProfile: () => api.get('/users/profile'),
};

export const productAPI = {
  getProducts: (params) => api.get('/products', { params }),
  getProduct: (id) => api.get(`/products/${id}`),
  searchProducts: (query) => api.get(`/products/search?q=${query}`),
};

export const orderAPI = {
  createOrder: (orderData) => api.post('/orders', orderData),
  getOrders: () => api.get('/orders'),
  getOrder: (id) => api.get(`/orders/${id}`),
};

export default api;
```

**3. Redux Store Configuration**
```javascript
// store/index.js
import { configureStore } from '@reduxjs/toolkit';
import authSlice from './slices/authSlice';
import productSlice from './slices/productSlice';
import cartSlice from './slices/cartSlice';
import orderSlice from './slices/orderSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice,
    products: productSlice,
    cart: cartSlice,
    orders: orderSlice,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST'],
      },
    }),
});

export default store;
```

**4. Frontend Dockerfile**
```dockerfile
# Build stage
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### **Backend Services Detailed Implementation**

#### **User Service (Node.js) - Complete Implementation**

**1. Project Structure**
```
applications/user-service/
├── src/
│   ├── controllers/
│   │   ├── authController.js
│   │   └── userController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── validation.js
│   ├── models/
│   │   └── User.js
│   ├── routes/
│   │   ├── auth.js
│   │   └── users.js
│   ├── utils/
│   │   ├── jwt.js
│   │   └── bcrypt.js
│   └── app.js
├── tests/
├── package.json
└── Dockerfile
```

**2. User Model (MongoDB)**
```javascript
// models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 30
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Invalid email']
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Update timestamp on save
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('User', userSchema);
```

**3. Authentication Controller**
```javascript
// controllers/authController.js
const User = require('../models/User');
const jwt = require('../utils/jwt');
const { validationResult } = require('express-validator');

class AuthController {
  async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation errors',
          errors: errors.array()
        });
      }

      const { username, email, password, firstName, lastName } = req.body;

      // Check if user already exists
      const existingUser = await User.findOne({
        $or: [{ email }, { username }]
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'User already exists with this email or username'
        });
      }

      // Create new user
      const user = new User({
        username,
        email,
        password,
        firstName,
        lastName
      });

      await user.save();

      // Generate JWT token
      const token = jwt.generateToken({
        userId: user._id,
        email: user.email,
        role: user.role
      });

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: {
            id: user._id,
            username: user.username,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role
          },
          token
        }
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation errors',
          errors: errors.array()
        });
      }

      const { email, password } = req.body;

      // Find user by email
      const user = await User.findOne({ email, isActive: true });
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Check password
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Update last login
      user.lastLogin = new Date();
      await user.save();

      // Generate JWT token
      const token = jwt.generateToken({
        userId: user._id,
        email: user.email,
        role: user.role
      });

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user._id,
            username: user.username,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role,
            lastLogin: user.lastLogin
          },
          token
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  async refreshToken(req, res) {
    try {
      const { token } = req.body;
      
      if (!token) {
        return res.status(400).json({
          success: false,
          message: 'Token is required'
        });
      }

      const decoded = jwt.verifyToken(token);
      const user = await User.findById(decoded.userId);

      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Invalid token'
        });
      }

      const newToken = jwt.generateToken({
        userId: user._id,
        email: user.email,
        role: user.role
      });

      res.json({
        success: true,
        data: { token: newToken }
      });
    } catch (error) {
      res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }
  }
}

module.exports = new AuthController();
```

**4. User Service Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

EXPOSE 3000

CMD ["npm", "start"]
```

#### **Product Service (Python/Flask) - Complete Implementation**

**1. Project Structure**
```
applications/product-service/
├── app/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── product.py
│   │   └── category.py
│   ├── controllers/
│   │   ├── __init__.py
│   │   ├── product_controller.py
│   │   └── category_controller.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── product_service.py
│   │   └── search_service.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── database.py
│   │   └── cache.py
│   └── config.py
├── migrations/
├── tests/
├── requirements.txt
├── app.py
└── Dockerfile
```

**2. Product Model (SQLAlchemy)**
```python
# app/models/product.py
from datetime import datetime
from app.utils.database import db
from sqlalchemy.dialects.postgresql import UUID
import uuid

class Product(db.Model):
    __tablename__ = 'products'
    
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = db.Column(db.String(255), nullable=False, index=True)
    description = db.Column(db.Text)
    short_description = db.Column(db.String(500))
    sku = db.Column(db.String(100), unique=True, nullable=False, index=True)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    compare_price = db.Column(db.Numeric(10, 2))
    cost_price = db.Column(db.Numeric(10, 2))
    
    # Inventory
    quantity = db.Column(db.Integer, default=0)
    track_quantity = db.Column(db.Boolean, default=True)
    allow_backorder = db.Column(db.Boolean, default=False)
    
    # SEO
    meta_title = db.Column(db.String(255))
    meta_description = db.Column(db.String(500))
    slug = db.Column(db.String(255), unique=True, index=True)
    
    # Status
    is_active = db.Column(db.Boolean, default=True)
    is_featured = db.Column(db.Boolean, default=False)
    
    # Relationships
    category_id = db.Column(UUID(as_uuid=True), db.ForeignKey('categories.id'))
    category = db.relationship('Category', backref='products')
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Product {self.name}>'
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'name': self.name,
            'description': self.description,
            'short_description': self.short_description,
            'sku': self.sku,
            'price': float(self.price),
            'compare_price': float(self.compare_price) if self.compare_price else None,
            'quantity': self.quantity,
            'is_active': self.is_active,
            'is_featured': self.is_featured,
            'category': self.category.to_dict() if self.category else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    @classmethod
    def search(cls, query, category_id=None, min_price=None, max_price=None, 
               is_active=True, page=1, per_page=20):
        """Advanced product search with filters"""
        query_obj = cls.query.filter(cls.is_active == is_active)
        
        if query:
            search_filter = db.or_(
                cls.name.ilike(f'%{query}%'),
                cls.description.ilike(f'%{query}%'),
                cls.sku.ilike(f'%{query}%')
            )
            query_obj = query_obj.filter(search_filter)
        
        if category_id:
            query_obj = query_obj.filter(cls.category_id == category_id)
        
        if min_price:
            query_obj = query_obj.filter(cls.price >= min_price)
        
        if max_price:
            query_obj = query_obj.filter(cls.price <= max_price)
        
        return query_obj.paginate(
            page=page, 
            per_page=per_page, 
            error_out=False
        )

class Category(db.Model):
    __tablename__ = 'categories'
    
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    slug = db.Column(db.String(255), unique=True, index=True)
    parent_id = db.Column(UUID(as_uuid=True), db.ForeignKey('categories.id'))
    
    # Self-referential relationship for nested categories
    children = db.relationship('Category', backref=db.backref('parent', remote_side=[id]))
    
    is_active = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Category {self.name}>'
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'name': self.name,
            'description': self.description,
            'slug': self.slug,
            'parent_id': str(self.parent_id) if self.parent_id else None,
            'is_active': self.is_active,
            'sort_order': self.sort_order,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
```

**3. Product Controller**
```python
# app/controllers/product_controller.py
from flask import Blueprint, request, jsonify
from app.models.product import Product, Category
from app.services.product_service import ProductService
from app.services.search_service import SearchService
from app.utils.cache import cache
from marshmallow import Schema, fields, ValidationError

product_bp = Blueprint('products', __name__, url_prefix='/api/products')

class ProductSchema(Schema):
    name = fields.Str(required=True, validate=lambda x: len(x) >= 2)
    description = fields.Str()
    short_description = fields.Str()
    sku = fields.Str(required=True)
    price = fields.Decimal(required=True, places=2)
    compare_price = fields.Decimal(places=2, allow_none=True)
    quantity = fields.Int(missing=0)
    category_id = fields.UUID(allow_none=True)
    is_active = fields.Bool(missing=True)
    is_featured = fields.Bool(missing=False)

product_schema = ProductSchema()
products_schema = ProductSchema(many=True)

@product_bp.route('/', methods=['GET'])
@cache.cached(timeout=300, query_string=True)
def get_products():
    """Get products with filtering and pagination"""
    try:
        # Get query parameters
        page = request.args.get('page', 1, type=int)
        per_page = min(request.args.get('per_page', 20, type=int), 100)
        search_query = request.args.get('q', '')
        category_id = request.args.get('category_id')
        min_price = request.args.get('min_price', type=float)
        max_price = request.args.get('max_price', type=float)
        is_featured = request.args.get('is_featured', type=bool)
        sort_by = request.args.get('sort_by', 'created_at')
        sort_order = request.args.get('sort_order', 'desc')
        
        # Search products
        pagination = Product.search(
            query=search_query,
            category_id=category_id,
            min_price=min_price,
            max_price=max_price,
            page=page,
            per_page=per_page
        )
        
        # Apply additional filters
        if is_featured is not None:
            pagination.items = [p for p in pagination.items if p.is_featured == is_featured]
        
        # Sort results
        if sort_by in ['name', 'price', 'created_at']:
            reverse = sort_order == 'desc'
            pagination.items = sorted(
                pagination.items, 
                key=lambda x: getattr(x, sort_by), 
                reverse=reverse
            )
        
        return jsonify({
            'success': True,
            'data': {
                'products': [product.to_dict() for product in pagination.items],
                'pagination': {
                    'page': pagination.page,
                    'pages': pagination.pages,
                    'per_page': pagination.per_page,
                    'total': pagination.total,
                    'has_next': pagination.has_next,
                    'has_prev': pagination.has_prev
                }
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching products: {str(e)}'
        }), 500

@product_bp.route('/<uuid:product_id>', methods=['GET'])
@cache.cached(timeout=600)
def get_product(product_id):
    """Get single product by ID"""
    try:
        product = Product.query.get_or_404(product_id)
        
        if not product.is_active:
            return jsonify({
                'success': False,
                'message': 'Product not found'
            }), 404
        
        return jsonify({
            'success': True,
            'data': product.to_dict()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching product: {str(e)}'
        }), 500

@product_bp.route('/', methods=['POST'])
def create_product():
    """Create new product"""
    try:
        # Validate input data
        try:
            product_data = product_schema.load(request.json)
        except ValidationError as err:
            return jsonify({
                'success': False,
                'message': 'Validation errors',
                'errors': err.messages
            }), 400
        
        # Create product using service
        product = ProductService.create_product(product_data)
        
        # Clear cache
        cache.clear()
        
        return jsonify({
            'success': True,
            'message': 'Product created successfully',
            'data': product.to_dict()
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error creating product: {str(e)}'
        }), 500

@product_bp.route('/search', methods=['GET'])
@cache.cached(timeout=300, query_string=True)
def search_products():
    """Advanced product search with Elasticsearch"""
    try:
        query = request.args.get('q', '')
        filters = {
            'category_id': request.args.get('category_id'),
            'min_price': request.args.get('min_price', type=float),
            'max_price': request.args.get('max_price', type=float),
            'is_featured': request.args.get('is_featured', type=bool)
        }
        
        page = request.args.get('page', 1, type=int)
        per_page = min(request.args.get('per_page', 20, type=int), 100)
        
        # Use Elasticsearch for advanced search
        results = SearchService.search_products(
            query=query,
            filters=filters,
            page=page,
            per_page=per_page
        )
        
        return jsonify({
            'success': True,
            'data': results
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Search error: {str(e)}'
        }), 500
```

**4. Product Service Dockerfile**
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python healthcheck.py

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

---

This is the first part of the comprehensive documentation. Would you like me to continue with the remaining services (Order Service, Notification Service) and the complete CI/CD pipeline details?