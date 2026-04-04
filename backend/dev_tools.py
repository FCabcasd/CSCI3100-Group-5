"""
实用工具集合 - 常见操作脚本
"""

import subprocess
import sys
from pathlib import Path


def run_command(cmd, description):
    """运行命令并显示结果"""
    print(f"\n{'=' * 60}")
    print(f"🔧 {description}")
    print(f"{'=' * 60}")
    try:
        result = subprocess.run(cmd, shell=True, check=True)
        print(f"✅ {description} 完成")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 失败: {e}")
        return False


def format_code():
    """格式化代码"""
    print("\n📝 格式化代码...")
    run_command("black app/", "Black代码格式化")
    run_command("isort app/", "isort import排序")


def check_code_quality():
    """检查代码质量"""
    print("\n🔍 检查代码质量...")
    run_command("flake8 app/", "Flake8代码检查")


def run_tests():
    """运行测试"""
    print("\n🧪 运行测试...")
    run_command("pytest tests/ -v", "Pytest单元测试")
    run_command("pytest tests/ --cov=app", "覆盖率报告")


def setup_git_hooks():
    """设置Git hooks"""
    hooks_dir = Path(".git/hooks")
    pre_commit = hooks_dir / "pre-commit"
    
    content = """#!/bin/bash
# Pre-commit hook - 提交前检查

echo "Running code quality checks..."
black app/ && isort app/ && flake8 app/

if [ $? -ne 0 ]; then
    echo "Code quality checks failed!"
    exit 1
fi

echo "Running tests..."
pytest tests/ -q

if [ $? -ne 0 ]; then
    echo "Tests failed!"
    exit 1
fi

exit 0
"""
    
    if hooks_dir.exists():
        pre_commit.write_text(content)
        pre_commit.chmod(0o755)
        print("✅ Pre-commit hook已安装")
    else:
        print("❌ .git目录不存在，跳过hook安装")


def create_migration():
    """创建数据库迁移"""
    message = input("输入迁移说明: ")
    run_command(
        f'alembic revision --autogenerate -m "{message}"',
        "创建数据库迁移"
    )


def apply_migrations():
    """应用数据库迁移"""
    run_command("alembic upgrade head", "应用数据库迁移")


def display_menu():
    """显示菜单"""
    print("""
╔══════════════════════════════════════════════════════════════╗
║         CUHK Venue & Equipment Booking - 开发工具             ║
╚══════════════════════════════════════════════════════════════╝

1. 📝 格式化代码 (Black + isort)
2. 🔍 检查代码质量 (Flake8)
3. 🧪 运行测试 (Pytest)
4. 🔧 格式化 + 检查 + 测试
5. 🪝 设置Git hooks
6. 💾 创建数据库迁移 (Alembic)
7. ⬆️  应用数据库迁移
8. 🚀 启动开发服务器
9. 🐳 启动Docker容器
10. 📖 显示帮助信息
11. 🚪 退出

请选择 (1-11): 
""")


def main():
    """主函数"""
    while True:
        display_menu()
        choice = input().strip()
        
        if choice == "1":
            format_code()
        elif choice == "2":
            check_code_quality()
        elif choice == "3":
            run_tests()
        elif choice == "4":
            format_code()
            check_code_quality()
            run_tests()
        elif choice == "5":
            setup_git_hooks()
        elif choice == "6":
            create_migration()
        elif choice == "7":
            apply_migrations()
        elif choice == "8":
            run_command(
                "uvicorn app.main:app --reload --port 8000",
                "启动FastAPI开发服务器"
            )
        elif choice == "9":
            run_command("docker-compose up -d", "启动Docker容器")
        elif choice == "10":
            print("""
📚 快速帮助:

1. 环境设置:
   source venv/bin/activate
   pip install -r requirements.txt

2. 数据库初始化:
   python init_db.py

3. 启动服务:
   uvicorn app.main:app --reload

4. 查看API文档:
   http://localhost:8000/docs

5. 测试API:
   python test_api.py

6. 数据库管理:
   pgAdmin: http://localhost:5050

7. Redis管理:
   redis-cli

常用命令:
   - black app/          # 代码格式化
   - pytest tests/       # 运行测试
   - flake8 app/         # 代码检查
   - isort app/          # 排序imports
""")
        elif choice == "11":
            print("👋 再见!")
            sys.exit(0)
        else:
            print("❌ 无效选择，请重试")


if __name__ == "__main__":
    main()
