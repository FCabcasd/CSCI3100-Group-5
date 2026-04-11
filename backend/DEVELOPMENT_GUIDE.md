# 开发指南 - FastAPI后端开发步骤

## 第一阶段：项目初始化和环境设置 ✅

### 已完成：
1. ✅ 创建Python项目结构
2. ✅ 配置requirements.txt
3. ✅ 创建Docker && docker-compose配置
4. ✅ 配置settings和环境变量

## 第二阶段：数据库和模型 ✅

### 已完成：
1. ✅ 定义SQLAlchemy模型
   - User（用户）
   - Tenant（租户）
   - Venue（场地）
   - Equipment（设备）
   - Booking（预订）
   - Cancellation（取消）
   - PointDeduction（积分）

2. ✅ 设置数据库连接和ORM
3. ✅ 定义Pydantic schemas用于验证

## 第三阶段：认证和授权 ✅

### 已完成：
1. ✅ JWT令牌实现
2. ✅ 密码哈希（bcrypt）
3. ✅ 用户注册/登录
4. ✅ 令牌刷新机制
5. ✅ 基于角色的权限检查

## 第四阶段：核心业务逻辑 ✅

### 已完成：
1. ✅ ConflictDetectionService
   - 场地冲突检测
   - 设备冲突检测
   - 时间重叠验证

2. ✅ BookingService
   - 创建单次预订
   - 创建重复预订
   - 取消预订
   - 积分扣除

3. ✅ UserService
   - 账户暂停
   - 权限检查

## 第五阶段：API路由（进行中 🚀）

### 已完成：
1. ✅ `/api/auth` - 认证路由
   - `POST /register`
   - `POST /login`
   - `POST /refresh`
   - `GET /me`

2. ✅ `/api/bookings` - 预订路由
   - `POST /` - 创建预订
   - `GET /` - 列表
   - `GET /{id}` - 详情
   - `POST /{id}/cancel` - 取消
   - `POST /{id}/confirm` - 确认

3. ✅ `/api/venues` - 场地路由
   - `POST /` - 创建
   - `GET /` - 列表
   - `GET /{id}` - 详情
   - `PUT /{id}` - 更新
   - `DELETE /{id}` - 删除

### 待实现：
1. ❌ `/api/equipment` - 设备路由
2. ❌ `/api/analytics` - 分析路由
3. ❌ `/api/admin` - 管理路由

## 第六階段：外部集成

### 已完成：
1. ✅ 郵件服務（確認、取消通知）- 全英文模板
   - `app/utils/email.py` - 郵件發送模組
   - 預訂確認郵件
   - 管理員確認郵件
   - 取消通知郵件
   - 重複預訂確認郵件

### 待實現：
1. ❌ Google Maps API集成
2. ✅ OpenAI API集成（AI諮詢）✅ (已完成)
3. ❌ Redis緩存層

## 第七階段：後台任務

### 已完成：
1. ✅ Celery 任務配置
   - `app/celery_config.py` - Celery 配置和 Beat 排程
   - `app/tasks.py` - 後台任務實現
2. ✅ 定時任務
   - 預訂提醒（24h/1h）- 每 30 分鐘執行
   - 清理 90 天前取消記錄 - 每天 03:00
   - 檢查用戶封禁狀態 - 每小時執行
3. ✅ 郵件發送任務（非同步）
   - `send_booking_confirmation_task`
   - `send_booking_confirmed_by_admin_task`
   - `send_booking_cancellation_task`

### 待實現：
1. ❌ WebSocket 實時通知

## 第八阶段：测试

### 待实现：
1. ❌ 单元测试
2. ❌ 集成测试
3. ❌ 性能测试

---

## 如何继续开发

### 接下来的步骤（优先级）：

### 1. 实现Equipment路由 (★★★★☆)

```python
# app/routes/equipment.py
# 类似于venues.py，实现CRUD操作
```

创建步骤：
```bash
# 创建文件
touch app/routes/equipment.py

# 在main.py中导入和注册
from app.routes import equipment
app.include_router(equipment.router)
```

### 2. 实现Analytics路由 (★★★★☆)

需要的查询：
```python
# 获取预订统计
SELECT COUNT(*), status FROM booking GROUP BY status

# 获取高峰时间
SELECT EXTRACT(HOUR FROM start_time) as hour, COUNT(*) 
FROM booking GROUP BY hour ORDER BY COUNT(*) DESC

# 获取场地利用率
SELECT venue_id, COUNT(*) as total_bookings,
       SUM(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as hours_used
FROM booking WHERE status='completed'
GROUP BY venue_id
```

### 3. 实现Admin路由 (★★★☆☆)

权限管理、系统配置等

### 4. Google Maps集成 (★★☆☆☆)

```python
# app/utils/google_maps.py
import googlemaps

def get_venues_near_location(latitude, longitude, radius=5000):
    # 根据用户位置查找附近场地
    pass
```

### 5. OpenAI AI諮詢 (已完成) ✅

```python
# app/utils/ai_consultant.py
from openai import OpenAI

async def answer_booking_question(question: str) -> str:
    # 使用GPT回答關於預訂的問題
    # 已實現政策問答、場地推薦、預訂指引等功能
```

### 6. 邮件系统 (★★☆☆☆)

```python
# app/utils/email.py
# 发送预订确认、取消通知等
```

### 7. WebSocket和实时通知 (★☆☆☆☆)

```python
# app/websocket.py
# 使用WebSocket推送实时更新
```

---

## 开发工作流

### 本地开发：

```bash
# 1. 启动数据库和Redis
docker-compose up -d postgres redis

# 2. 在另一个终端运行API服务
uvicorn app.main:app --reload --port 8000

# 3. 在第三个终端运行Celery Worker
celery -A app.celery_config worker --loglevel=info

# 4. 在第四个终端运行Celery Beat（定時任務）
celery -A app.celery_config beat --loglevel=info

# 5. 访问文档
http://localhost:8000/docs
```

### 测试API：

```bash
# 注册用户
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "full_name": "Test User",
    "password": "password123"
  }'

# 登录
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 获取令牌后，使用Bearer token调用API
curl -X GET "http://localhost:8000/api/bookings" \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

### 代码风格：

```bash
# 使用Black格式化
black app/

# 使用isort排列imports
isort app/

# 使用flake8检查
flake8 app/
```

---

## 关键设计决策

### 1. 时间重叠检测算法

```sql
-- 两个时间段重叠的条件
start_time_1 < end_time_2 AND end_time_1 > start_time_2
```

### 2. 乐观锁实现

使用status字段作为版本标记，防止并发修改：
```python
# 只有在status=pending时才能确认
UPDATE booking SET status='confirmed' 
WHERE id=1 AND status='pending'
```

### 3. 多租户隔离

```python
# 所有查询都必须包含tenant_id过滤
.where(Venue.tenant_id == current_user.tenant_id)
```

### 4. 积分系统

- 初始积分：100
- 迟到取消扣分：10分
- 积分过低（<10）：无法预订
- 迟到取消过多（积分<=0）：账户暂停

---

## 部署清單

- [ ] 生成數據庫遷移腳本
- [ ] 配置生產環境的秘密密鑰
- [x] 設置郵件服務 ✅（需配置 SMTP）
- [ ] 配置Google Maps API
- [x] 配置OpenAI API密鑰 ✅ (已完成)
- [x] 設置Redis ✅
- [x] 配置Celery workers ✅
- [ ] 設置Nginx反向代理
- [ ] 配置SSL證書
- [ ] 設置監控和日誌
- [ ] 編寫健康檢查
- [ ] 準備數據庫備份策略

---

## 常用命令

```bash
# 检查代码质量
black app/ && isort app/ && flake8 app/

# 运行测试
pytest tests/ -v --cov=app

# 生成数据库迁移
alembic revision --autogenerate -m "description"
alembic upgrade head

# 启动开发服务器
uvicorn app.main:app --reload

# 启动Celery Worker
celery -A app.celery_config worker --loglevel=info

# 启动Celery Beat（定時任務）
celery -A app.celery_config beat --loglevel=info

# Docker命令
docker-compose up -d
docker-compose down
docker-compose logs -f api
```

---

## 文件检查清单

已创建的关键文件：
- ✅ `backend/requirements.txt` - 依赖
- ✅ `backend/.env.example` - 环境变量示例
- ✅ `backend/docker-compose.yml` - 本地开发环境
- ✅ `backend/Dockerfile` - 生产镜像
- ✅ `app/config.py` - 配置
- ✅ `app/database.py` - 数据库
- ✅ `app/models.py` - ORM模型
- ✅ `app/schemas.py` - Pydantic schemas
- ✅ `app/auth.py` - 认证逻辑
- ✅ `app/services.py` - 业务逻辑
- ✅ `app/main.py` - FastAPI应用
- ✅ `app/routes/auth.py` - 认证路由
- ✅ `app/routes/bookings.py` - 预订路由
- ✅ `app/routes/venues.py` - 场地路由

待创建的文件：
- ❌ `app/routes/equipment.py` - 设备路由
- ❌ `app/routes/analytics.py` - 分析路由
- ❌ `app/routes/admin.py` - 管理路由
- ✅ `app/utils/email.py` - 邮件 ✅
- ❌ `app/utils/google_maps.py` - Google Maps
- ✅ `app/utils/ai_consultant.py` - AI ✅
- ✅ `app/tasks.py` - Celery 任务 ✅
- ✅ `app/celery_config.py` - Celery 配置 ✅
- ✅ `tests/test_email.py` - 邮件測試（22 tests）✅
- ✅ `tests/test_tasks.py` - 任務測試（17 tests）✅
- ❌ `migrations/` - Alembic迁移

---

希望这个指南对你的开发有帮助！祝你编码愉快！ 🚀
