#!/bin/bash

# 快速启动脚本 - FastAPI后端

set -e

echo "🚀 CUHK Venue & Equipment Booking Backend - Quick Start"
echo "=========================================="

# 检查Python版本
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.11+"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo "✅ Python version: $PYTHON_VERSION"

# 创建虚拟环境
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
else
    echo "✅ Virtual environment already exists"
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📥 Installing dependencies..."
    pip install -q -r requirements.txt
else
    echo "✅ Dependencies already installed"
fi

# 检查.env文件
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file..."
    cp .env.example .env
    echo "   Please edit .env with your configuration"
else
    echo "✅ .env file already exists"
fi

# 启动Docker容器（如果Docker可用）
if command -v docker-compose &> /dev/null; then
    echo "🐳 Docker Compose found"
    read -p "Do you want to start PostgreSQL and Redis? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting containers..."
        docker-compose up -d postgres redis
        echo "✅ PostgreSQL and Redis started"
        sleep 3
    fi
fi

# 显示使用说明
echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run migrations: alembic upgrade head"
echo "3. Start the server: uvicorn app.main:app --reload"
echo "4. Open http://localhost:8000/docs for API documentation"
echo ""
echo "Development commands:"
echo "  # Format code"
echo "  black app/ && isort app/"
echo ""
echo "  # Run tests"
echo "  pytest tests/"
echo ""
echo "  # Check code quality"
echo "  flake8 app/"
echo ""
