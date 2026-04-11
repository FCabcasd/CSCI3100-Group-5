# 项目完整规划 - CUHK Venue & Equipment Booking Backend

## 📋 项目概览

**项目名称**：CUHK Venue & Equipment Booking SaaS  
**技术栈**：Python + FastAPI + PostgreSQL + Redis  
**当前状态**：✅ 第一阶段完成（核心架构）  
**下一步**：实现剩余路由和外部集成

---

## 🎯 功能需求对应

### Proposal中的需求 → 实现方案

#### 1. 冲突检测 ✅
**Proposal**: "Checking conflicts manually often results in human error"  
**解决方案**:
- ✅ `ConflictDetectionService.check_venue_availability()` - 场地冲突检测
- ✅ `ConflictDetectionService.check_equipment_availability()` - 设备冲突检测
- ✅ 时间重叠算法：`start_time < other.end_time AND end_time > other.start_time`
- ✅ 即时拒绝冲突预订

#### 2. 多租户隔离 ✅
**Proposal**: "Each venue and equipment belongs to exactly one tenant; data are tenant-scoped"  
**解决方案**:
- ✅ `Tenant` 模型（部门级别）
- ✅ 所有资源（Venue, Equipment, User）都属于Tenant
- ✅ 所有查询自动过滤tenant_id

#### 3. 取消机制和积分系统 ✅
**Proposal**: "Setup waitlist for other user as well as punishment mechanism for frequent late cancellation"  
**解决方案**:
- ✅ `Cancellation` 模型记录取消信息
- ✅ `PointDeduction` 模型记录扣分
- ✅ 迟到取消检测（距开始时间 < 24小时）
- ✅ 自动扣分机制
- ✅ 积分<=0时暂停账户

#### 4. 递归预订 ✅
**Proposal**: "For recurring needs (e.g., weekly meetings), the system supports recurring reservations"  
**解决方案**:
- ✅ `BookingService.create_recurring_booking()`
- ✅ 支持daily, weekly, monthly模式
- ✅ 自动冲突检测和生成

#### 5. 實時通知 ✅
**Proposal**: "receive instant email confirmations after booking"  
**解決方案**:
- ✅ 郵件服務 (已完成)
  - 預訂確認郵件
  - 管理員確認郵件
  - 取消通知郵件
  - 重複預訂確認郵件
  - 預訂提醒郵件（24h/1h）
- ❌ WebSocket 推送 (待實現)
- ✅ Celery 異步任務 (已完成)

#### 6. Google Maps集成（待实现）
**Proposal**: "view locations via integrated Google Maps"  
**解决方案**:
- ❌ Google Maps API集成 (待实现)
- ❌ 地理位置查询 (待实现)

#### 7. AI諮詢助手 ✅
**Proposal**: "AI-powered consultation assistant driven by a public large language model API"  
**解決方案**:
- ✅ OpenAI GPT集成 (已完成)
- ✅ 預訂政策Q&A (已完成)
- ✅ 場地推薦 (已完成)
- ✅ 預訂指引 (已完成)

#### 8. 仪表板统计（待实现）
**Proposal**: "Administrators access usage statistics through an interactive dashboard"  
**解决方案**:
- ❌ Analytics API端点 (待实现)
- ❌ 预订频率、高峰时间分析 (待实现)

---

## 📊 项目架构

```
┌─────────────────────────────────────────────────────┐
│                    FastAPI Server                   │
│                 (uvicorn on port 8000)              │
└─────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   ┌────────────┐   ┌────────────┐   ┌────────────┐
   │   Routes   │   │ Services   │   │   Auth     │
   │  (API)     │   │ (Logic)    │   │(JWT, PWD)  │
   └────────────┘   └────────────┘   └────────────┘
        ↓                 ↓
   ┌────────────────────────────────┐
   │      SQLAlchemy ORM            │
   │  (Models, Relationships)       │
   └────────────────────────────────┘
        ↓
   ┌────────────────────────────────┐
   │    PostgreSQL Database         │
   │  (Users, Bookings, Venues...)  │
   └────────────────────────────────┘
```

---

## 📁 完整目录结构

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                      # ✅ FastAPI应用入口
│   ├── config.py                    # ✅ 配置管理
│   ├── database.py                  # ✅ 数据库连接
│   ├── models.py                    # ✅ SQLAlchemy模型
│   ├── schemas.py                   # ✅ Pydantic schemas
│   ├── auth.py                      # ✅ JWT認證
│   ├── celery_config.py             # ✅ Celery 配置
│   ├── services.py                  # ✅ 業務邏輯
│   ├── tasks.py                     # ✅ Celery 任務
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py                  # ✅ 认证API
│   │   ├── bookings.py              # ✅ 预订API (基础)
│   │   ├── venues.py                # ✅ 场地API
│   │   ├── equipment.py             # ❌ 设备API (待实现)
│   │   ├── analytics.py             # ❌ 分析API (待实现)
│   │   └── admin.py                 # ❌ 管理API (待实现)
│   └── utils/
│       ├── email.py                 # ✅ 郵件服務 (全英文模板)
│       ├── google_maps.py           # ❌ Google Maps (待實現)
│       └── ai_consultant.py         # ❌ AI 諮詢 (待實現)
├── tests/
│   ├── test_auth.py                 # ❌ 認證測試 (待實現)
│   ├── test_bookings.py             # ❌ 預訂測試 (待實現)
│   ├── test_conflicts.py            # ❌ 衝突檢測測試 (待實現)
│   ├── test_email.py               # ✅ 郵件測試（22 tests）
│   ├── test_tasks.py               # ✅ Celery 任務測試（17 tests）
│   └── test_venues.py               # ❌ 場地測試 (待實現)
├── migrations/
│   ├── alembic.ini                  # ❌ (待创建)
│   └── versions/                    # ❌ (待创建)
├── .env.example                     # ✅ 环境变量示例
├── .gitignore
├── requirements.txt                 # ✅ 依赖列表
├── Dockerfile                       # ✅ Docker镜像
├── docker-compose.yml               # ✅ Docker Compose配置
├── pyproject.toml                   # ✅ Poetry配置
├── README.md                        # ✅ 项目说明
├── DEVELOPMENT_GUIDE.md             # ✅ 开发指南
├── quickstart.sh                    # ✅ 快速启动脚本
├── init_db.py                       # ✅ 数据库初始化
├── test_api.py                      # ✅ API测试脚本
└── PROJECT_PLAN.md                  # 📍 本文件
```

---

## 🚀 快速启动（3分钟）

### 前置条件
- Python 3.11+
- Docker & Docker Compose (可选)
- PostgreSQL & Redis (或使用Docker)

### 启动步骤

```bash
# 1. 进入backend目录
cd backend

# 2. 运行快速启动脚本
bash quickstart.sh

# 3. 启动Docker容器（可选）
docker-compose up -d postgres redis

# 4. 初始化数据库
python init_db.py

# 5. 启动开发服务器
uvicorn app.main:app --reload

# 6. 打开浏览器
# API文档: http://localhost:8000/docs
# 健康检查: http://localhost:8000/api/health
```

### 测试API

```bash
# 运行API测试脚本
python test_api.py
```

---

## 💻 核心代码示例

### 1. 冲突检测（最关键的功能）

```python
# app/services.py
class ConflictDetectionService:
    @staticmethod
    async def check_venue_availability(
        db: AsyncSession,
        venue_id: int,
        start_time: datetime,
        end_time: datetime,
    ) -> Tuple[bool, Optional[str]]:
        """检查场地时间冲突"""
        # 查询重叠的已确认/待定预订
        query = select(Booking).where(
            and_(
                Booking.venue_id == venue_id,
                Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PENDING]),
                # 时间重叠逻辑
                Booking.start_time < end_time,
                Booking.end_time > start_time,
            )
        )
        
        conflicts = await db.execute(query)
        if conflicts.scalars().all():
            return False, "场地在该时段已被预订"
        return True, None
```

### 2. 预订创建

```python
# app/routes/bookings.py
@router.post("/", response_model=BookingResponse)
async def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建预订"""
    # 1. 验证冲突
    available, msg = await ConflictDetectionService.validate_booking_times(...)
    if not available:
        raise HTTPException(status_code=400, detail=msg)
    
    # 2. 检查积分
    if current_user.points < 10:
        raise HTTPException(status_code=400, detail="积分不足")
    
    # 3. 创建预订
    booking = Booking(
        user_id=current_user.id,
        venue_id=booking_data.venue_id,
        ...
    )
    
    db.add(booking)
    await db.commit()
    return booking
```

### 3. 取消预订和积分扣除

```python
# app/services.py
@staticmethod
async def cancel_booking(db: AsyncSession, booking: Booking, reason: str):
    """取消预订"""
    now = datetime.utcnow()
    hours_before = (booking.start_time - now).total_seconds() / 3600
    
    # 获取租户的取消截止时间
    tenant = await db.get(Tenant, booking.venue.tenant_id)
    is_late = hours_before < tenant.cancellation_deadline_hours
    
    # 更新预订状态
    booking.status = BookingStatus.CANCELLED
    
    # 如果是迟到取消，扣分
    if is_late:
        user = await db.get(User, booking.user_id)
        user.points -= tenant.point_deduction_per_late_cancel
        
        # 记录扣分
        point_record = PointDeduction(
            user_id=booking.user_id,
            points=tenant.point_deduction_per_late_cancel,
            reason="late_cancellation",
        )
        db.add(point_record)
    
    await db.commit()
```

---

## 🔄 API端点完整列表

### 认证 `/api/auth` ✅
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| POST | `/register` | 用户注册 | ❌ |
| POST | `/login` | 用户登录 | ❌ |
| POST | `/refresh` | 刷新令牌 | ❌ |
| GET | `/me` | 获取当前用户 | ✅ |

### 预订 `/api/bookings` ✅
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| POST | `/` | 创建预订 | ✅ |
| GET | `/` | 获取用户预订列表 | ✅ |
| GET | `/{id}` | 获取预订详情 | ✅ |
| POST | `/{id}/cancel` | 取消预订 | ✅ |
| POST | `/{id}/confirm` | 确认预订 | ✅ 管理员 |

### 场地 `/api/venues` ✅
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| POST | `/` | 创建场地 | ✅ 租户管理员 |
| GET | `/` | 获取场地列表 | ✅ |
| GET | `/{id}` | 获取场地详情 | ✅ |
| PUT | `/{id}` | 更新场地 | ✅ 租户管理员 |
| DELETE | `/{id}` | 删除场地 | ✅ 租户管理员 |

### 设备 `/api/equipment` ❌ 待实现
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| POST | `/` | 创建设备 | ✅ 租户管理员 |
| GET | `/` | 获取设备列表 | ✅ |
| GET | `/{id}` | 获取设备详情 | ✅ |
| PUT | `/{id}` | 更新设备 | ✅ 租户管理员 |
| DELETE | `/{id}` | 删除设备 | ✅ 租户管理员 |

### 分析 `/api/analytics` ❌ 待实现
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| GET | `/bookings/stats` | 预订统计 | ✅ 管理员 |
| GET | `/venues/usage` | 场地利用率 | ✅ 管理员 |
| GET | `/peak-times` | 高峰时间 | ✅ 管理员 |

### 管理员 `/api/admin` ❌ 待实现
| Method | Endpoint | 功能 | 认证 |
|--------|----------|------|------|
| GET | `/users` | 获取用户列表 | ✅ 管理员 |
| POST | `/users/{id}/suspend` | 暂停用户 | ✅ 管理员 |
| DELETE | `/users/{id}` | 删除用户 | ✅ 管理员 |

---

## 📝 数据库模式

### 核心表结构

```sql
-- 用户表
CREATE TABLE user (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    hashed_password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'tenant_admin', 'user'),
    tenant_id INTEGER REFERENCES tenant(id),
    is_active BOOLEAN DEFAULT TRUE,
    points INTEGER DEFAULT 100,
    suspension_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 预订表
CREATE TABLE booking (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user(id),
    venue_id INTEGER REFERENCES venue(id),
    title VARCHAR(255) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled', 'completed', 'no_show'),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(50),
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    -- 关键索引
    INDEX idx_start_end_time (start_time, end_time),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- 取消记录表
CREATE TABLE cancellation (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER UNIQUE REFERENCES booking(id),
    hours_before_start FLOAT,
    is_late_cancellation BOOLEAN,
    cancelled_at TIMESTAMP DEFAULT NOW()
);

-- 积分扣除表
CREATE TABLE point_deduction (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user(id),
    booking_id INTEGER REFERENCES booking(id),
    points INTEGER NOT NULL,
    reason VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 关键性能优化

1. **索引策略**
   - 预订表：(start_time, end_time) 复合索引
   - 用户表：(email, username) 唯一索引
   - 场地表：(tenant_id, status) 复合索引

2. **查询优化**
   ```python
   # 高效的冲突检测查询
   SELECT * FROM booking 
   WHERE venue_id = ?
     AND status IN ('confirmed', 'pending')
     AND start_time < ? AND end_time > ?
   LIMIT 1  # 只需找到一个冲突
   ```

3. **乐观锁**
   ```python
   # 防止并发修改
   UPDATE booking 
   SET status = 'confirmed' 
   WHERE id = ? AND status = 'pending'
   ```

---

## 🛠️ 技术决策

### 为何选择FastAPI？
- ⚡ 高性能（接近Golang）
- 📖 自动OpenAPI/Swagger文档
- 🔒 内置数据验证（Pydantic）
- 🔄 异步支持
- 📦 现代化Python特性

### 为何选择PostgreSQL？
- 🔐 ACID事务支持（冲突检测的关键）
- 🗂️ 复杂查询能力
- 📊 适合关系数据模型
- 🚀 高并发性能

### 为何选择Redis？
- ⚡ 缓存热点数据
- 📨 消息队列（Celery）
- 🔔 实时通知
- 🗝️ 会话存储

---

## 📋 下一步开发计划

### Phase 2: 完成剩余API和功能 (1-2周)

#### Week 1
- [ ] Equipment路由完全实现
- [ ] Analytics路由实现
  - 预订统计
  - 高峰时间分析
  - 场地利用率
- [ ] Admin路由基础框架
- [ ] 单元测试编写

#### Week 2
- [x] 邮件系统集成 ✅
- [ ] Google Maps集成
- [x] OpenAI AI諮詢 ✅
- [x] Celery后台任务 ✅

### Phase 3: 高级特性 (1周)

- [ ] WebSocket实时通知
- [x] 分布式Celery workers ✅
- [ ] 缓存层优化
- [ ] 数据库备份策略

### Phase 4: 测试和部署 (1周)

- [ ] 综合测试
- [ ] 性能测试（压力测试）
- [ ] 安全审计
- [ ] 生产环境部署

---

## 📊 当前进度

```
总进度: ████████░░ 60% (已完成邮件通知 + Celery 任务)

第一阶段 (核心架构): ██████████ 100% ✅
├─ 项目配置
├─ 数据库模型
├─ 认证系统
├─ 冲突检测
└─ 基础API

第二阶段 (完整API):  ░░░░░░░░░░ 0% ⏳
├─ Equipment API
├─ Analytics API
├─ Admin API
└─ 测试

第三阶段 (外部集成): ██████░░░░ 60% ⏳
├─ Google Maps (待实现)
├─ OpenAI ✅ (已完成)
├─ 邮件服务 ✅ (已完成 - 英文模板)
└─ 缓存策略

第四阶段 (部署优化):  ████░░░░░░ 40% ⏳
├─ WebSocket (待实现)
├─ Celery集群 ✅ (已完成)
├─ 性能优化
└─ 生产部署
```

---

## 🎓 学习资源

### 推荐阅读
- [FastAPI官方文档](https://fastapi.tiangolo.com/)
- [SQLAlchemy ORM教程](https://docs.sqlalchemy.org/en/20/)
- [PostgreSQL查询优化](https://www.postgresql.org/docs/)
- [JWT认证最佳实践](https://tools.ietf.org/html/rfc7519)

### 相关工具
- Postman: API测试
- pgAdmin: 数据库管理
- Redis Desktop Manager: Redis可视化
- Swagger UI: API文档（自动生成）

---

## ✅ 质量检查清单

在提交代码前：

- [ ] 代码通过black格式化
- [ ] 通过isort自动import排序
- [ ] flake8检查无错误
- [x] 单元测试通过 ✅ (55 tests: 25 email + 17 tasks + 13 AI)
- [ ] 没有SQL注入风险
- [ ] 没有暴露敏感信息（API密钥等）
- [ ] 数据库查询有正确的索引
- [ ] 错误处理完善
- [x] 文档更新 ✅

---

## 🚨 常见陷阱和解决方案

### 1. 并发冲突问题
**问题**：两个用户同时预订同一个场地
**解决**：使用乐观锁 + 事务
```python
UPDATE booking SET status='confirmed' 
WHERE id=1 AND status='pending'
```

### 2. N+1查询问题
**问题**：循环中为每个预订查询用户信息
**解决**：使用eager loading
```python
bookings = select(Booking).options(joinedload(Booking.user))
```

### 3. 数据库连接泄漏
**问题**：连接没有正确关闭
**解决**：使用async context manager
```python
async with AsyncSessionLocal() as session:
    # 自动处理关闭
```

### 4. 密码安全
**问题**：明文存储密码
**解决**：使用bcrypt哈希
```python
hashed_password = hash_password(plain_password)
```

---

## 📞 支持和联系

如有问题，请：
1. 查看README.md和DEVELOPMENT_GUIDE.md
2. 检查FastAPI文档
3. 查看test_api.py的使用示例
4. 提交Issue或联系开发团队

---

**最后更新**: 2026-04-11  
**维护者**: CSCI3100 Group 5  
**许可证**: MIT
