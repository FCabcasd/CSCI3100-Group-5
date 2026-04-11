# CUHK Venue & Equipment Booking Backend - FastAPI

这是CUHK Venue & Equipment Booking系统的Python/FastAPI后端实现。

## 项目概述

这个后端系统提供REST API来支持场地和设备预订：

- **用户管理**：注册、登录、权限管理
- **冲突检测**：实时检测场地/设备时间冲突
- **预订管理**：单次预订和重复预订
- **场地&设备管理**：CRUD操作
- **取消管理**：处理预订取消和积分扣除
- **分析仪表板**：使用统计和峰值时间分析
- **AI 諮詢助手**：GPT 驅動的預訂政策問答、場地推薦、預訂指引
- **郵件通知**：英文模板通知（Celery 異步）
- **外部集成**：Google Maps、OpenAI API

## 技术栈

- **框架**：FastAPI
- **数据库**：PostgreSQL + SQLAlchemy ORM
- **缓存/消息队列**：Redis
- **后台任务**：Celery
- **认证**：JWT (python-jose)
- **API文档**：Swagger UI (自动生成)

## 快速开始

### 1. 环境设置

```bash
# 克隆项目
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # 或 venv\Scripts\activate (Windows)

# 安装依赖
pip install -r requirements.txt

# 复制环境变量文件
cp .env.example .env

# 根据需要编辑.env文件
# 需要填入：数据库URL、API密钥等
```

### 2. 数据库初始化

```bash
# 使用Alembic进行数据库迁移
alembic upgrade head

# 或手动创建表（仅用于开发）
python -c "from app.database import Base, engine; Base.metadata.create_all(engine)"
```

### 3. 启动开发服务器

```bash
# 方式1：直接运行
uvicorn app.main:app --reload --port 8000

# 方式2：使用Docker Compose
docker-compose up
```

访问 http://localhost:8000 查看API基本信息
访问 http://localhost:8000/docs 查看Swagger UI文档

### 4. 啟動後台任務處理（Celery）

```bash
# 終端 1：啟動 Redis（如需要）
redis-server

# 終端 2：啟動 Celery Worker
celery -A app.celery_config worker --loglevel=info

# 終端 3：啟動 Celery Beat（定時任務）
celery -A app.celery_config beat --loglevel=info
```

## 项目结构

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI应用主文件
│   ├── config.py            # 应用配置
│   ├── database.py          # 数据库配置和会话管理
│   ├── models.py            # SQLAlchemy数据模型
│   ├── schemas.py           # Pydantic请求/响应模型
│   ├── auth.py              # 认证和授权逻辑
│   ├── celery_config.py     # Celery 配置和 Beat 排程
│   ├── services.py          # 业务逻辑（冲突检测、预订等）
│   ├── tasks.py             # Celery 后台任务
│   ├── utils/
│   │   ├── email.py         # 邮件发送
│   │   ├── google_maps.py   # Google Maps集成
│   │   └── ai_consultant.py # AI咨询助手
│   └── routes/
│       ├── __init__.py
│       ├── auth.py          # 认证路由
│       ├── bookings.py      # 预订路由
│       ├── venues.py        # 场地路由
│       ├── equipment.py     # 设备路由
│       ├── analytics.py     # 分析路由
│       └── admin.py         # 管理员路由
├── tests/
│   ├── test_auth.py
│   ├── test_conflicts.py
│   ├── test_email.py       # 郵件通知測試
│   ├── test_tasks.py       # Celery 任務測試
│   └── test_venues.py
├── migrations/              # Alembic迁移文件
├── .env.example             # 环境变量示例
├── requirements.txt         # Python依赖
├── Dockerfile              # Docker配置
├── docker-compose.yml      # Docker Compose配置
└── README.md              # 本文件
```

## 核心功能詳解

### 1. 郵件通知系統（Email Notification）

系統在以下事件觸發郵件通知（全英文模板）：

| 事件 | 郵件內容 |
|------|---------|
| 創建預訂 | 預訂詳情、場地、時間、設備列表、聯絡人資訊 |
| 管理員確認 | 確認成功、場地詳情、注意事項 |
| 取消預訂 | 取消原因、如為遲到取消顯示扣分通知 |
| 重複預訂 | 預訂總數、 recurrence pattern、首次時間 |
| 賬戶暫停 | 暫停時長、原因、解封時間 |

**郵件特色**：
- HTML 模板，使用 CSS 樣式
- 響應式設計（最大寬度 600px）
- 區分顏色的 header（藍/綠/紅）
- 設備列表、聯絡人資訊格式化顯示

**配置**（`.env`）：
```bash
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@yourdomain.com
```

### 2. AI 諮詢助手（OpenAI GPT）

系統使用 GPT 驅動的 AI 助手提供預訂相關問答服務：

| 功能 | 描述 |
|------|------|
| 政策問答 | 用戶詢問預訂規則，AI 根據系統政策回答 |
| 場地推薦 | 根據用戶需求（如「30人會議室」）推薦合適場地 |
| 預訂指引 | 引導用戶完成預訂流程 |
| 衝突檢查 | 分析建議的時間段是否有衝突 |

**API 端點**：
- `POST /api/ai/ask` - 政策問答
- `POST /api/ai/recommend-venues` - 場地推薦
- `POST /api/ai/guide-booking` - 預訂指引
- `POST /api/ai/check-conflicts` - 衝突檢查
- `GET /api/ai/status` - AI 服務狀態

**配置**（`.env`）：
```bash
OPENAI_API_KEY=sk-your-openai-api-key
```

**使用示例**：
```bash
# 詢問政策
curl -X POST "http://localhost:8000/api/ai/ask" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"question": "取消預訂會怎樣？"}'

# 場地推薦
curl -X POST "http://localhost:8000/api/ai/recommend-venues" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"requirements": "30人會議，需投影機"}'
```

### 3. 衝突檢測（ConflictDetectionService）

**问题**：手动检查冲突容易出错

**解决方案**：
```python
# 自动检查时间重叠
available, message = await ConflictDetectionService.validate_booking_times(
    db,
    venue_id=1,
    equipment_ids=[1, 2],
    start_time=datetime.now(),
    end_time=datetime.now() + timedelta(hours=2),
)
```

**实现原理**：
- 查询指定时间内的所有已确认/待定预订
- 检查时间重叠：`start_time < other.end_time AND end_time > other.start_time`
- 检查所有场地和设备

### 4. 重複預訂

**支持的模式**：daily, weekly, monthly

```python
# 创建每周重复的预订
recurring_booking = await BookingService.create_recurring_booking(
    db,
    user,
    RecurringBookingCreate(
        title="Weekly Meeting",
        venue_id=1,
        start_time=datetime.now(),
        end_time=datetime.now() + timedelta(hours=1),
        recurrence_pattern="weekly",
        recurrence_end_date=datetime.now() + timedelta(days=90),
    )
)
```

### 5. 遲到取消和積分系統

**流程**：
1. 用户取消预订
2. 系统检查是否为迟到取消（距离开始时间 < N小时）
3. 如果是迟到取消，从用户积分中扣除
4. 积分过低会被暂停预订权限

```python
cancellation = await BookingService.cancel_booking(db, booking, reason)
# 如果is_late_cancellation=True，自动扣分
```

### 6. 多租戶支援

**特点**：
- 数据完全隔离
- 每个租户有独立的场地、设备、用户
- 租户可以制定自己的规则（如取消截止时间、扣分规则）

```python
class Tenant(Base):
    cancellation_deadline_hours = 24  # 自定义取消截止时间
    point_deduction_per_late_cancel = 10  # 自定义扣分
```

## API端点概览

### 认证 `/api/auth`
- `POST /register` - 用户注册
- `POST /login` - 用户登录
- `POST /refresh` - 刷新令牌
- `GET /me` - 获取当前用户

### 预订 `/api/bookings`
- `POST /` - 创建预订
- `GET /` - 获取用户预订列表
- `GET /{booking_id}` - 获取预订详情
- `POST /{booking_id}/cancel` - 取消预订
- `POST /{booking_id}/confirm` - 确认预订（管理员）

### 场地 `/api/venues`
- `POST /` - 创建场地
- `GET /` - 获取场地列表
- `GET /{venue_id}` - 获取场地详情
- `PUT /{venue_id}` - 更新场地
- `DELETE /{venue_id}` - 删除场地

### 设备 `/api/equipment` (待实现)
- 类似于场地的CRUD操作

### 分析 `/api/analytics` (待实现)
- `GET /bookings/stats` - 预订统计
- `GET /venues/usage` - 场地使用情况
- `GET /peak-times` - 高峰时间分析

### 管理员 `/api/admin` (待实现)
- 用户管理、系统配置等

## 认证机制

### JWT令牌

```
POST /api/auth/login
{
    "email": "user@example.com",
    "password": "password"
}

响应：
{
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "expires_in": 1800
}
```

### 使用令牌

```
GET /api/bookings
Authorization: Bearer <access_token>
```

### 刷新令牌

```
POST /api/auth/refresh
{
    "refresh_token": "<refresh_token>"
}
```

## 数据模型关系

```
User (用户)
  ├─ Bookings (预订)
  ├─ PointDeductions (积分扣除)
  └─ Tenant (租户)

Tenant (租户)
  ├─ Venues (场地)
  ├─ Equipment (设备)
  └─ Users (用户)

Booking (预订)
  ├─ Venue (场地)
  ├─ Equipment (设备, 多对多)
  └─ Cancellation (取消记录)
```

## 数据库模式

### 优化

1. **索引**：在频繁查询的字段上创建索引
   - user_id, venue_id, start_time, end_time, status

2. **乐观锁**：防止并发冲突
   ```sql
   -- 在Booking表中
   UPDATE booking SET status='confirmed' WHERE id=1 AND status='pending'
   ```

3. **分区**（可选）：按时间分区booking表以提高性能

## 环境变量配置

参考 `.env.example`：

```
# 数据库
DATABASE_URL=postgresql://user:password@localhost/cuhk_booking_dev

# JWT
SECRET_KEY=your-secret-key-change-this-in-production
ALGORITHM=HS256

# Redis
REDIS_URL=redis://localhost:6379/0

# 外部API
GOOGLE_MAPS_API_KEY=...
OPENAI_API_KEY=...

# 邮件
SMTP_SERVER=smtp.gmail.com
SMTP_USER=...
```

## 測試

```bash
# 運行所有測試
pytest

# 運行特定測試
pytest tests/test_bookings.py
pytest tests/test_email.py      # 郵件通知測試（22 tests）
pytest tests/test_tasks.py      # Celery 任務測試（17 tests）

# 顯示覆蓋率
pytest --cov=app tests/

# 測試結果：55 tests（25 email + 17 tasks + 13 AI）
```

## 部署

### Docker部署

```bash
# 构建镜像
docker build -t cuhk-booking-backend .

# 运行容器
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e OPENAI_API_KEY=... \
  cuhk-booking-backend
```

### 使用Docker Compose

```bash
docker-compose up -d
```

### Heroku部署

```bash
# 创建Procfile（已包含）
git push heroku master
```

## 後續開發任務

- [ ] 實現 equipment 路由
- [ ] 實現 analytics 路由（儀表板統計）
- [ ] 實現 admin 路由
- [ ] Google Maps 集成
- [ ] OpenAI AI 諮詢功能
- [ ] WebSocket/ActionCable 實時通知
- [x] 郵件通知系統 ✅
- [x] Celery 後台任務 ✅
- [ ] 單元測試和集成測試
- [ ] API 文檔完善

## 常见问题

### Q: 如何处理并发预订？
A: 使用乐观锁和数据库事务，在booking表中检查status确保原子性。

### Q: 如何扩展到多个微服务？
A: 可以拆分为：auth-service、booking-service、notification-service等，使用消息队列通信。

### Q: 如何处理大量用户？
A: 
- 使用Redis缓存热点数据
- 数据库连接池优化
- 分布式Celery workers
- CDN加速静态资源

## 联系和支持

如有问题，请提交Issue或联系开发团队。

## 许可证

MIT License
