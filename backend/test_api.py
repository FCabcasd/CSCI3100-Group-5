"""API使用示例和测试场景"""

import requests
import json
from typing import Dict, Optional

BASE_URL = "http://localhost:8000"


class APITester:
    def __init__(self):
        self.access_token = None
        self.headers = {}
        
    def set_auth_header(self, token: str):
        """设置授权头"""
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }
    
    def register(self, email: str, username: str, password: str) -> Dict:
        """注册用户"""
        response = requests.post(
            f"{BASE_URL}/api/auth/register",
            json={
                "email": email,
                "username": username,
                "full_name": username,
                "password": password,
            }
        )
        return response.json()
    
    def login(self, email: str, password: str) -> Dict:
        """登录"""
        response = requests.post(
            f"{BASE_URL}/api/auth/login",
            json={"email": email, "password": password}
        )
        data = response.json()
        if "access_token" in data:
            self.access_token = data["access_token"]
            self.set_auth_header(data["access_token"])
        return data
    
    def get_current_user(self) -> Dict:
        """获取当前用户信息"""
        response = requests.get(
            f"{BASE_URL}/api/auth/me",
            headers=self.headers
        )
        return response.json()
    
    def create_venue(self, tenant_id: int, name: str, capacity: int) -> Dict:
        """创建场地"""
        response = requests.post(
            f"{BASE_URL}/api/venues",
            json={
                "tenant_id": tenant_id,
                "name": name,
                "capacity": capacity,
                "location": "Student Center",
                "available_from": "08:00",
                "available_until": "22:00",
            },
            headers=self.headers
        )
        return response.json()
    
    def list_venues(self) -> Dict:
        """获取场地列表"""
        response = requests.get(
            f"{BASE_URL}/api/venues",
            headers=self.headers
        )
        return response.json()
    
    def create_booking(
        self,
        venue_id: int,
        title: str,
        start_time: str,
        end_time: str,
    ) -> Dict:
        """创建预订"""
        response = requests.post(
            f"{BASE_URL}/api/bookings",
            json={
                "venue_id": venue_id,
                "title": title,
                "start_time": start_time,
                "end_time": end_time,
                "contact_person": "Test User",
                "contact_email": "test@example.com",
                "contact_phone": "12345678",
                "equipment_ids": [],
            },
            headers=self.headers
        )
        return response.json()
    
    def list_bookings(self) -> Dict:
        """获取预订列表"""
        response = requests.get(
            f"{BASE_URL}/api/bookings",
            headers=self.headers
        )
        return response.json()
    
    def cancel_booking(self, booking_id: int, reason: str = "User requested") -> Dict:
        """取消预订"""
        response = requests.post(
            f"{BASE_URL}/api/bookings/{booking_id}/cancel",
            json={"reason": reason},
            headers=self.headers
        )
        return response.json()


def test_scenario():
    """测试场景"""
    tester = APITester()
    
    print("=" * 60)
    print("快速API测试场景")
    print("=" * 60)
    
    # 1. 注册用户
    print("\n1️⃣  注册新用户...")
    reg_result = tester.register(
        "test_user@example.com",
        "test_user",
        "password123"
    )
    print(f"   ✅ 注册成功: {reg_result.get('email')}")
    
    # 2. 登录
    print("\n2️⃣  用户登录...")
    login_result = tester.login("test_user@example.com", "password123")
    print(f"   ✅ 令牌: {login_result.get('access_token')[:20]}...")
    
    # 3. 获取用户信息
    print("\n3️⃣  获取当前用户信息...")
    user = tester.get_current_user()
    print(f"   ✅ 用户: {user.get('full_name')} ({user.get('email')})")
    print(f"   ✅ 积分: {user.get('points')}")
    
    # 4. 获取场地列表
    print("\n4️⃣  获取场地列表...")
    venues = tester.list_venues()
    if venues:
        print(f"   ✅ 找到 {len(venues)} 个场地")
        if len(venues) > 0:
            venue = venues[0]
            print(f"      - {venue.get('name')} (容纳{venue.get('capacity')}人)")
            
            # 5. 创建预订
            print("\n5️⃣  创建预订...")
            booking = tester.create_booking(
                venue_id=venue.get('id'),
                title="Team Meeting",
                start_time="2024-04-15T10:00:00",
                end_time="2024-04-15T11:00:00",
            )
            
            if "id" in booking:
                print(f"   ✅ 预订创建成功 (ID: {booking.get('id')})")
                
                # 6. 获取预订列表
                print("\n6️⃣  获取预订列表...")
                bookings = tester.list_bookings()
                print(f"   ✅ 您有 {len(bookings)} 个预订")
                
                # 7. 取消预订
                print("\n7️⃣  取消预订...")
                cancel_result = tester.cancel_booking(
                    booking.get('id'),
                    "Changed my mind"
                )
                print(f"   ✅ 预订已取消")
            else:
                print(f"   ❌ 创建失败: {booking.get('detail')}")
    else:
        print("   ⚠️  没有可用场地")
    
    print("\n" + "=" * 60)
    print("✨ 测试完成!")
    print("=" * 60)


if __name__ == "__main__":
    print("确保FastAPI服务器正在运行: uvicorn app.main:app --reload")
    print()
    
    import time
    time.sleep(2)
    
    try:
        test_scenario()
    except requests.exceptions.ConnectionError:
        print("❌ 无法连接到服务器")
        print("请先运行: uvicorn app.main:app --reload")
