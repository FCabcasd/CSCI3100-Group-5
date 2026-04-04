📱 CUHK Venue & Equipment Booking - 前端开发指南

欢迎前端团队！这份指南帮助你快速熟悉后端API，开始前端开发。

═══════════════════════════════════════════════════════════════════════════════

第一步：了解项目结构和API

所有API文档都在这里：
https://github.com/FCabcasd/CSCI3100-Group-5/blob/master/backend/README.md

关键信息：
  • Backend URL: http://localhost:8000 (本地开发)
  • 生产URL: https://group5app-e244cbe44724.herokuapp.com/
  • API基础路径: /api
  • 文档: http://localhost:8000/docs (Swagger UI)

═══════════════════════════════════════════════════════════════════════════════

第二步：环境设置

1. 后端环境启动（后端团队负责）
   cd backend
   bash quickstart.sh
   python init_db.py
   uvicorn app.main:app --reload

   后端将运行在: http://localhost:8000

2. 前端环境设置（你负责）
   # 推荐的前端技术栈：
   - React 18+ / Vue 3 / Next.js
   - TypeScript (推荐)
   - Axios / Fetch API 用于HTTP请求
   - Zustand / Redux 用于状态管理
   - Tailwind CSS / Material UI

示例创建React项目：
   npx create-react-app booking-frontend
   cd booking-frontend
   npm install axios zustand react-router-dom

═══════════════════════════════════════════════════════════════════════════════

第三步：API端点速查表

📌 认证 (用户登录/注册)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

注册新用户
  POST /api/auth/register
  请求体:
  {
    "email": "user@example.com",
    "username": "username",
    "full_name": "Full Name",
    "password": "password123"
  }

用户登录
  POST /api/auth/login
  请求体:
  {
    "email": "user@example.com",
    "password": "password123"
  }
  响应:
  {
    "access_token": "eyJ0eXAi...", ← 保存这个令牌！
    "refresh_token": "eyJ0eXAi...",
    "expires_in": 1800
  }

获取当前用户信息
  GET /api/auth/me
  请求头: Authorization: Bearer <access_token>

刷新令牌
  POST /api/auth/refresh
  请求体:
  {
    "refresh_token": "<refresh_token>"
  }

═══════════════════════════════════════════════════════════════════════════════

📌 预订 (核心功能)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

创建预订 ⭐
  POST /api/bookings
  请求头: Authorization: Bearer <token>
  请求体:
  {
    "venue_id": 1,
    "title": "Team Meeting",
    "description": "Weekly sync",
    "start_time": "2024-04-15T10:00:00",
    "end_time": "2024-04-15T11:00:00",
    "contact_person": "John Doe",
    "contact_email": "john@example.com",
    "contact_phone": "12345678",
    "estimated_attendance": 10,
    "special_requirements": "Projector needed",
    "equipment_ids": [1, 2]  ← 可选，选择设备
  }
  响应: { "id": 1, "status": "pending", ... }

获取我的预订列表
  GET /api/bookings
  请求头: Authorization: Bearer <token>
  参数: skip=0&limit=10
  响应: [ { ...booking1 }, { ...booking2 }, ... ]

获取预订详情
  GET /api/bookings/{booking_id}
  请求头: Authorization: Bearer <token>

取消预订
  POST /api/bookings/{booking_id}/cancel
  请求头: Authorization: Bearer <token>
  请求体:
  {
    "reason": "Schedule conflict"
  }

確认预订 (仅管理员)
  POST /api/bookings/{booking_id}/confirm
  请求头: Authorization: Bearer <token>

═══════════════════════════════════════════════════════════════════════════════

📌 场地 (浏览和管理)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

获取场地列表 (公开API)
  GET /api/venues
  参数: skip=0&limit=10
  响应:
  [
    {
      "id": 1,
      "name": "多媒体教室A",
      "capacity": 50,
      "location": "李兆基楼3楼",
      "latitude": 22.3026,
      "longitude": 114.2068,
      "features": {
        "projector": true,
        "whiteboard": true,
        "wifi": true
      },
      "available_from": "08:00",
      "available_until": "22:00",
      "image_url": "..."
    },
    ...
  ]

获取场地详情
  GET /api/venues/{venue_id}

创建场地 (租户管理员)
  POST /api/venues
  请求头: Authorization: Bearer <token>
  请求体:
  {
    "tenant_id": 1,
    "name": "venue name",
    "description": "description",
    "capacity": 50,
    "location": "location",
    "latitude": 22.3,
    "longitude": 114.2,
    "available_from": "08:00",
    "available_until": "22:00",
    "features": { "projector": true }
  }

═══════════════════════════════════════════════════════════════════════════════

第四步：测试用户账号

使用这些账号测试（由后端init_db.py创建）：

┌────────────────────────────────────────────┐
│ 邮箱                      密码      角色    │
├────────────────────────────────────────────┤
│ admin@example.com        admin123  Admin   │
│ tenant_admin@example.com admin123  Admin   │
│ user@example.com         user123   User    │
└────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════

第五步：前端代码示例

示例1: 用户登录 (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import axios from 'axios';
import { useState } from 'react';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await axios.post('http://localhost:8000/api/auth/login', {
        email,
        password,
      });

      // 保存令牌
      localStorage.setItem('access_token', response.data.access_token);
      localStorage.setItem('refresh_token', response.data.refresh_token);

      // 重定向到仪表板
      window.location.href = '/dashboard';
    } catch (err) {
      setError(err.response?.data?.detail || '登录失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-form">
      <form onSubmit={handleLogin}>
        <input
          type="email"
          placeholder="邮箱"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="密码"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        {error && <p className="error">{error}</p>}
        <button type="submit" disabled={loading}>
          {loading ? '登录中...' : '登录'}
        </button>
      </form>
    </div>
  );
}

示例2: 获取场地列表 (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useEffect, useState } from 'react';
import axios from 'axios';

export default function VenuesPage() {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchVenues = async () => {
      try {
        const response = await axios.get(
          'http://localhost:8000/api/venues',
          {
            params: { skip: 0, limit: 10 }
          }
        );
        setVenues(response.data);
      } catch (err) {
        setError('获取场地信息失败');
      } finally {
        setLoading(false);
      }
    };

    fetchVenues();
  }, []);

  if (loading) return <p>加载中...</p>;
  if (error) return <p className="error">{error}</p>;

  return (
    <div className="venues-list">
      <h1>可用场地</h1>
      <div className="grid">
        {venues.map((venue) => (
          <div key={venue.id} className="venue-card">
            <h3>{venue.name}</h3>
            <p>容纳: {venue.capacity} 人</p>
            <p>位置: {venue.location}</p>
            <button onClick={() => {
              // 跳转到预订页面
              window.location.href = `/booking?venue_id=${venue.id}`;
            }}>
              预订
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

示例3: 创建预订 (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import axios from 'axios';
import { useState } from 'react';

export default function BookingForm() {
  const [formData, setFormData] = useState({
    venue_id: 1,
    title: '',
    description: '',
    start_time: '',
    end_time: '',
    contact_person: '',
    contact_email: '',
    contact_phone: '',
    estimated_attendance: '',
    equipment_ids: [],
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const token = localStorage.getItem('access_token');
      const response = await axios.post(
        'http://localhost:8000/api/bookings',
        formData,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      setSuccess(true);
      alert(`预订成功！预订ID: ${response.data.id}`);
      // 重置表单
      setFormData({...initial});
    } catch (err) {
      setError(err.response?.data?.detail || '预订失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="预订标题"
        value={formData.title}
        onChange={(e) => setFormData({...formData, title: e.target.value})}
        required
      />
      <textarea
        placeholder="描述"
        value={formData.description}
        onChange={(e) => setFormData({...formData, description: e.target.value})}
      />
      <input
        type="datetime-local"
        value={formData.start_time}
        onChange={(e) => setFormData({...formData, start_time: e.target.value})}
        required
      />
      <input
        type="datetime-local"
        value={formData.end_time}
        onChange={(e) => setFormData({...formData, end_time: e.target.value})}
        required
      />
      <input
        type="text"
        placeholder="联系人"
        value={formData.contact_person}
        onChange={(e) => setFormData({...formData, contact_person: e.target.value})}
        required
      />
      <input
        type="email"
        placeholder="联系邮箱"
        value={formData.contact_email}
        onChange={(e) => setFormData({...formData, contact_email: e.target.value})}
        required
      />
      <input
        type="tel"
        placeholder="联系电话"
        value={formData.contact_phone}
        onChange={(e) => setFormData({...formData, contact_phone: e.target.value})}
        required
      />
      {error && <p className="error">{error}</p>}
      <button type="submit" disabled={loading}>
        {loading ? '预订中...' : '提交预订'}
      </button>
    </form>
  );
}

示例4: API工具函数 (utils/api.ts)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import axios, { AxiosError } from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 创建axios实例
const apiClient = axios.create({
  baseURL: API_BASE_URL,
});

// 添加请求拦截器（自动添加token）
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 添加响应拦截器（处理401错误）
apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    if (error.response?.status === 401) {
      // 令牌过期，尝试刷新
      try {
        const refreshToken = localStorage.getItem('refresh_token');
        const response = await axios.post(`${API_BASE_URL}/auth/refresh`, {
          refresh_token: refreshToken,
        });
        localStorage.setItem('access_token', response.data.access_token);
        // 重试原始请求
        return apiClient.request(error.config!);
      } catch (err) {
        // 刷新失败，跳转到登录
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// API函数
export const authAPI = {
  login: (email: string, password: string) =>
    apiClient.post('/auth/login', { email, password }),
  register: (email: string, username: string, full_name: string, password: string) =>
    apiClient.post('/auth/register', { email, username, full_name, password }),
  getCurrentUser: () => apiClient.get('/auth/me'),
  refresh: (refreshToken: string) =>
    apiClient.post('/auth/refresh', { refresh_token: refreshToken }),
};

export const venueAPI = {
  getAll: (skip = 0, limit = 10) =>
    apiClient.get('/venues', { params: { skip, limit } }),
  getById: (id: number) => apiClient.get(`/venues/${id}`),
  create: (data: any) => apiClient.post('/venues', data),
  update: (id: number, data: any) => apiClient.put(`/venues/${id}`, data),
  delete: (id: number) => apiClient.delete(`/venues/${id}`),
};

export const bookingAPI = {
  getAll: (skip = 0, limit = 10) =>
    apiClient.get('/bookings', { params: { skip, limit } }),
  getById: (id: number) => apiClient.get(`/bookings/${id}`),
  create: (data: any) => apiClient.post('/bookings', data),
  cancel: (id: number, reason: string) =>
    apiClient.post(`/bookings/${id}/cancel`, { reason }),
  confirm: (id: number) =>
    apiClient.post(`/bookings/${id}/confirm`),
};

export default apiClient;

═══════════════════════════════════════════════════════════════════════════════

第六步：CORS和网络问题

如果在浏览器控制台看到CORS错误：

错误示例:
  Access to XMLHttpRequest at 'http://localhost:8000/api/...'
  from origin 'http://localhost:3000' has been blocked by CORS policy

解决方案：
  ✅ 后端已配置CORS，应该没问题
  如果仍然有问题，请确保：
  1. 后端在http://localhost:8000运行
  2. 前端在http://localhost:3000运行
  3. 后端config.py中CORS_ORIGINS包含前端URL

前端配置示例（如果需要）:
  // 在你的.env文件中
  REACT_APP_API_URL=http://localhost:8000/api

═══════════════════════════════════════════════════════════════════════════════

第七步：构建建议页面

核心页面列表:
  
1. 登录/注册页面
   - 用户注册
   - 用户登录
   - 令牌存储

2. 仪表板/主页
   - 显示最近的预订
   - 快速链接

3. 场地列表页面
   - 显示所有可用场地
   - 根据容量、特性过滤
   - 显示Google Maps位置 (待实现)

4. 预订页面
   - 创建新预订
   - 选择场地和时间
   - 选择设备
   - 表单验证

5. 我的预订页面
   - 显示用户的所有预订
   - 状态标记（待确认、已确认、已取消）
   - 取消预订按钮

6. 预订详情页面
   - 显示预订的所有信息
   - 取消选项

7. 管理页面 (仅管理员)
   - 管理用户
   - 管理场地
   - 管理设备
   - 确认待定预订
   - 查看统计 (待实现)

═══════════════════════════════════════════════════════════════════════════════

第八步：开发路线图

Week 1 - MVP功能
  Week 1a:
    □ 创建React项目和基础布局
    □ 实现登录/注册页面
    □ 设置axios和API工具函数
  
  Week 1b:
    □ 实现场地列表页面
    □ 实现预订表单
    □ 实现我的预订页面（读取）

Week 2 - 完整功能
  Week 2a:
    □ 取消预订功能
    □ 预订详情页面
    □ 错误处理和加载状态
  
  Week 2b:
    □ 管理页面基础
    □ 状态管理优化（Zustand/Redux）
    □ 响应式设计

Week 3 - 高级功能和优化
  Week 3a:
    □ Google Maps集成 (当后端实现时)
    □ 实时通知 (当后端实现时)
    □ 邮件确认提示
  
  Week 3b:
    □ 性能优化和缓存
    □ 单元/集成测试
    □ 部署准备

═══════════════════════════════════════════════════════════════════════════════

第九步：常见问题解答

Q: 我需要等待后端完全完成吗？
A: 不需要！核心API已经完成。你现在就可以开始开发：
   - 所有认证API ✅
   - 所有预订API ✅
   - 所有场地API ✅
   设备和分析API稍后再加。

Q: 令牌保存在哪里？
A: localStorage.setItem('access_token', token)
   localStorage.getItem('access_token')
   
   ⚠️ 注意：localStorage不是最安全的地方
   生产环境建议使用httpOnly cookie

Q: 如何处理令牌过期？
A: 使用axios拦截器自动刷新（见示例4）
   如果刷新失败，跳转到登录页面

Q: 如何测试API？
A: 方式1: 使用Swagger UI
      http://localhost:8000/docs
   
   方式2: 使用Postman
      https://www.postman.com/
   
   方式3: 使用curl
      curl -X GET http://localhost:8000/api/venues

Q: API响应格式是什么？
A: 所有响应都是JSON
   成功: { "id": 1, "name": "...", ... }
   错误: { "detail": "错误信息" }

Q: 我如何知道什么时候可以调用新的API？
A: 查看后端的DEVELOPMENT_GUIDE.md
   https://github.com/FCabcasd/CSCI3100-Group-5/blob/master/backend/DEVELOPMENT_GUIDE.md
   
   或者关注提交记录

═══════════════════════════════════════════════════════════════════════════════

第十步：有用的资源

文档:
  ✅ 完整的后端API文档: http://localhost:8000/docs
  ✅ README.md: 项目概述和API列表
  ✅ PROJECT_PLAN.md: 架构和数据模型
  ✅ QUICKSTART.md: 快速开始

代码示例:
  ✅ test_api.py: 后端API测试脚本（参考!）
  ✅ app/routes/*.py: 查看实现细节
  ✅ app/schemas.py: 所有数据模型的定义

推荐库:
  • axios or fetch - HTTP请求
  • zustand or redux - 状态管理
  • react-router-dom - 路由
  • tailwindcss or material-ui - 样式
  • formik or react-hook-form - 表单
  • react-query - 数据缓存

═══════════════════════════════════════════════════════════════════════════════

第十一步：与后端团队沟通

问题需要后端修改吗？
  1. 创建GitHub Issue描述问题
  2. 或者直接在team chat中讨论
  3. 后端会在下一个迭代处理

API有问题吗？
  1. 检查http://localhost:8000/docs
  2. 查看示例代码
  3. 测试curl命令
  4. 查看后端日志

═══════════════════════════════════════════════════════════════════════════════

现在就开始吧！🚀

下一步：
1. 启动后端服务
2. 访问http://localhost:8000/docs查看完整API文档
3. 创建React项目
4. 实现登录/预订页面
5. 联系我如有问题

祝你开发顺利！💪
