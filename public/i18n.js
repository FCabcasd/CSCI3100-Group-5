/* ============================================================
   i18n – bilingual support (EN / 中文)
   Usage:
     HTML:  <span data-i18n="key">Fallback</span>
            <input data-i18n-placeholder="key" placeholder="Fallback">
     JS:    t('key')          // returns translated string
            setLang('zh')     // switch language
            getLang()          // 'en' | 'zh'
   ============================================================ */
(function () {
  const LANGS = {
    en: {
      // ── Global / Nav ──
      brand: "CUHK Venue Booking",
      menu: "Menu",
      logout: "Logout",
      login: "Sign In",
      close: "Close",
      refresh: "Refresh",
      loading: "Loading...",
      back_to_menu: "Back to Menu",
      hi: "Hi, ",
      pts: "pts",

      // ── Index (Login/Register) ──
      brand_sub: "Book venues & equipment across departments",
      tab_signin: "Sign In",
      tab_register: "Create Account",
      ph_email: "Email address",
      ph_password: "Password",
      ph_username: "Username",
      ph_fullname: "Full Name",
      ph_dept: "-- Select Department (optional) --",
      ph_password_min: "Password (min 6 chars)",
      ph_confirm_pw: "Confirm Password",
      btn_signin: "Sign In",
      btn_register: "Create Account",
      footer: "© 2026 CUHK Venue & Equipment Booking System",
      login_wait: "Please wait...",
      login_fill: "Please fill in all fields.",
      login_success: "Login successful! Redirecting...",
      login_fail: "Login failed.",
      login_no_token: "Login succeeded but no token returned.",
      reg_fill: "Please fill in all fields.",
      reg_pw_min: "Password must be at least 6 characters.",
      reg_pw_mismatch: "Passwords do not match.",
      reg_success: "Account created! Please sign in.",
      reg_fail: "Registration failed.",
      reg_no_user: "Registration succeeded but response is missing user data.",

      // ── Menu ──
      menu_title: "Dashboard",
      card_home: "Home",
      card_home_desc: "Return to the welcome page",
      card_venues: "Browse Venues",
      card_venues_desc: "Search and explore available venues",
      card_equip: "Equipment",
      card_equip_desc: "View and book equipment",
      card_bookings: "My Bookings",
      card_bookings_desc: "View, manage and check in",
      card_calendar: "Venue Calendar",
      card_calendar_desc: "See venue availability",
      card_ai: "AI Consultant",
      card_ai_desc: "Smart Q&A and recommendations",
      card_profile: "My Profile",
      card_profile_desc: "View your account details and points",
      card_analytics: "Analytics",
      card_analytics_desc: "Usage stats and reports",
      card_admin: "Admin Panel",
      card_admin_desc: "Manage users and bookings",

      // ── Catalog (Venues) ──
      browse_venues: "Browse Venues",
      browse_venues_sub: "Search and explore available venues across all departments",
      ph_search_venues: "Type to search venues...",
      any_capacity: "Any Capacity",
      any_feature: "Any Feature",
      apply_filters: "Apply Filters",
      loading_venues: "Loading venues...",
      load_more: "Load More",
      no_venues_found: "No venues found",
      venues_found: " venue(s) found",
      no_venues_match: "No venues match your filters.",
      failed_load_venues: "Failed to load venues.",
      lbl_location: "Location",
      lbl_capacity: "Capacity",
      lbl_people: " people",
      lbl_hours: "Available Hours",
      lbl_description: "Description",
      lbl_no_desc: "No description",
      lbl_features: "Features",
      lbl_none_listed: "None listed",
      lbl_map: "Map",
      btn_open_map: "Open in Google Maps",

      // ── Equipment ──
      browse_equip: "Browse Equipment",
      browse_equip_sub: "Search and explore available equipment across all departments",
      ph_search_equip: "Type to search equipment...",
      any_type: "Any Type",
      any_status: "Any Status",
      available: "Available",
      in_use: "In Use",
      maintenance: "Maintenance",
      loading_equip: "Loading equipment...",
      no_equip_found: "No equipment found",
      items_found: " item(s) found",
      no_equip_match: "No equipment matches your filters.",
      failed_load_equip: "Failed to load equipment.",
      lbl_type: "Type",
      lbl_quantity: "Quantity",
      lbl_status: "Status",

      // ── Booking Form (shared) ──
      book_venue_title: "Book Venue",
      book_equip_title: "Book Equipment",
      lbl_book_title: "Booking Title",
      ph_book_venue: "e.g. Team meeting, Course defense",
      ph_book_equip: "e.g. Lab equipment, Event devices",
      lbl_start_time: "Start Time",
      lbl_end_time: "End Time",
      lbl_remarks: "Remarks (optional)",
      ph_remarks: "Additional notes...",
      btn_submit_booking: "Confirm Booking",
      btn_select_venue: "Select this venue for booking",
      btn_select_equip: "Select this equipment for booking",
      btn_deselect: "Deselect",
      err_fill_all: "Please fill in all fields.",
      err_end_before_start: "End time must be after start time.",
      err_max_hours: "Booking duration cannot exceed 4 hours.",
      btn_submitting: "Submitting...",
      book_venue_success: "Booking successful! View in My Bookings.",
      book_equip_success: "Equipment booked! View in My Bookings.",
      book_fail: "Booking failed. Please try again.",

      // ── Booking Policy ──
      bp_title: "Booking Policy",
      bp_max_hours: "Bookings cannot exceed 4 hours.",
      bp_late_cancel: "Late cancellation within 24 hours may result in point deduction.",
      bp_frequent_cancel: "Frequent late cancellations or no-shows may lead to suspension.",
      lbl_action: "Action",
      btn_approve: "Approve",
      btn_reject: "Reject",
      confirm_approve: "Approve this booking?",
      confirm_reject: "Reject this booking?",
      action_fail: "Action failed. Please try again.",

      // ── My Bookings ──
      my_bookings: "My Bookings",
      no_bookings: "No bookings yet.",
      load_fail: "Failed to load.",
      booking_detail: "Booking Details",
      cancel_booking: "Cancel Booking",
      lbl_title: "Title",
      lbl_venue: "Venue",
      lbl_equipment: "Equipment",
      lbl_time: "Time",
      lbl_remarks_label: "Remarks",
      confirm_cancel: "Are you sure you want to cancel this booking?",
      cancel_fail: "Failed to cancel.",
      detail_btn: "Details",
      venue_prefix: "Venue: ",
      equip_prefix: "Equipment: ",

      // ── My Bookings ──
      my_bookings_sub: "View and manage all your venue and equipment bookings",

      // ── Venue Calendar ──
      venue_calendar: "Venue Booking Calendar",
      venue_calendar_sub: "Select a venue to view its booking schedule",
      select_venue: "Select Venue",
      confirmed: "Confirmed",
      pending: "Pending",

      // ── Admin Panel ──
      admin_center: "Admin Center",
      admin_sub: "Manage users, venues, equipment, and bookings",
      admin_users: "Users",
      admin_venues: "Venues",
      admin_equip: "Equipment",
      admin_bookings: "Bookings",
      admin_stats: "Stats",
      chart_confirmed: "Confirmed",
      chart_pending: "Pending",
      chart_cancelled: "Cancelled",
      chart_completed: "Completed",
      lbl_name: "Name",
      lbl_qty: "Quantity",
      lbl_user: "User",
      no_data: "No data available",

      // ── Profile ──
      my_profile: "My Profile",
      profile_sub: "View your account information and current status.",
      log_out: "Log Out",
      no_token: "No token found. Please log in first.",
      profile_fail: "Failed to load profile.",
      lbl_username: "Username:",
      lbl_fullname: "Full name:",
      lbl_email: "Email:",
      lbl_role: "Role:",
      lbl_tenant: "Tenant ID:",
      lbl_points: "Points:",
      na: "N/A",

      // ── Analytics ──
      analytics_title: "Analytics Dashboard",
      analytics_sub: "Usage overview for bookings, venues, and peak periods.",
      booking_stats: "Booking Stats",
      venue_usage: "Venue Usage",
      peak_times: "Peak Times",
      total_bookings: "Total bookings:",
      pending_bookings: "Pending bookings:",
      confirmed_bookings: "Confirmed bookings:",
      cancelled_bookings: "Cancelled bookings:",
      rejected_bookings: "Rejected bookings:",
      completed_bookings: "Completed bookings:",
      noshow_bookings: "No-show bookings:",
      bookings_word: "bookings",
      hours_word: "hours",
      view_map: "View Map",
      by_hour: "By hour",
      by_weekday: "By weekday",
      no_hourly: "No hourly data available",
      no_weekday: "No weekday data available",

      // ── AI ──
      ai_title: "AI Consultant",
      ai_intro: "Ask me anything about venue booking!",
      ai_welcome: "Hi there! I'm your booking assistant. Ask me anything about venues, equipment, or booking rules!",
      ai_q1: "How to book a venue?",
      ai_q2: "Recommend a venue for 30 people",
      ai_q3: "What happens if I cancel late?",
      ai_q4: "How do points work?",
      ai_placeholder: "Type your question...",
      ai_thinking: "AI is thinking...",
      ai_no_answer: "No answer",
      ai_error: "AI service error",

      // ── Language ──
      lang_label: "EN",
    },

    zh: {
      // ── 全局 / 导航 ──
      brand: "CUHK 场地预约",
      menu: "菜单",
      logout: "退出",
      login: "登录",
      close: "关闭",
      refresh: "刷新",
      loading: "加载中...",
      back_to_menu: "返回菜单",
      hi: "你好，",
      pts: "积分",

      // ── 登录/注册 ──
      brand_sub: "跨部门预约场地与设备",
      tab_signin: "登录",
      tab_register: "注册账号",
      ph_email: "邮箱地址",
      ph_password: "密码",
      ph_username: "用户名",
      ph_fullname: "姓名",
      ph_dept: "-- 选择部门（可选）--",
      ph_password_min: "密码（至少6位）",
      ph_confirm_pw: "确认密码",
      btn_signin: "登录",
      btn_register: "注册账号",
      footer: "© 2026 CUHK 场地与设备预约系统",
      login_wait: "请稍候...",
      login_fill: "请填写所有字段。",
      login_success: "登录成功！正在跳转...",
      login_fail: "登录失败。",
      login_no_token: "登录成功但未返回令牌。",
      reg_fill: "请填写所有字段。",
      reg_pw_min: "密码至少6个字符。",
      reg_pw_mismatch: "两次密码不一致。",
      reg_success: "注册成功！请登录。",
      reg_fail: "注册失败。",
      reg_no_user: "注册成功但响应缺少用户数据。",

      // ── 菜单 ──
      menu_title: "功能面板",
      card_home: "首页",
      card_home_desc: "返回欢迎页面",
      card_venues: "浏览场地",
      card_venues_desc: "搜索和浏览可用场地",
      card_equip: "设备",
      card_equip_desc: "查看和预约设备",
      card_bookings: "我的预约",
      card_bookings_desc: "查看、管理和签到",
      card_calendar: "场地日历",
      card_calendar_desc: "查看场地可用时间",
      card_ai: "AI顾问",
      card_ai_desc: "智能问答与推荐",
      card_profile: "个人资料",
      card_profile_desc: "查看账号详情和积分",
      card_analytics: "数据分析",
      card_analytics_desc: "使用统计和报告",
      card_admin: "管理面板",
      card_admin_desc: "管理用户和预约",

      // ── 场地浏览 ──
      browse_venues: "浏览场地",
      browse_venues_sub: "搜索和浏览所有部门的可用场地",
      ph_search_venues: "搜索场地...",
      any_capacity: "不限容量",
      any_feature: "不限设施",
      apply_filters: "筛选",
      loading_venues: "加载场地中...",
      load_more: "加载更多",
      no_venues_found: "未找到场地",
      venues_found: " 个场地",
      no_venues_match: "没有符合筛选条件的场地。",
      failed_load_venues: "场地加载失败。",
      lbl_location: "位置",
      lbl_capacity: "容量",
      lbl_people: " 人",
      lbl_hours: "开放时间",
      lbl_description: "描述",
      lbl_no_desc: "暂无描述",
      lbl_features: "设施",
      lbl_none_listed: "暂无",
      lbl_map: "地图",
      btn_open_map: "在 Google Maps 中查看",

      // ── 设备浏览 ──
      browse_equip: "浏览设备",
      browse_equip_sub: "搜索和浏览所有部门的可用设备",
      ph_search_equip: "搜索设备...",
      any_type: "不限类型",
      any_status: "不限状态",
      available: "可用",
      in_use: "使用中",
      maintenance: "维护中",
      loading_equip: "加载设备中...",
      no_equip_found: "未找到设备",
      items_found: " 个设备",
      no_equip_match: "没有符合筛选条件的设备。",
      failed_load_equip: "设备加载失败。",
      lbl_type: "类型",
      lbl_quantity: "数量",
      lbl_status: "状态",

      // ── 预约表单 ──
      book_venue_title: "预约场地",
      book_equip_title: "预约设备",
      lbl_book_title: "预约标题",
      ph_book_venue: "如：团队会议、课程答辩",
      ph_book_equip: "如：实验课器材、活动设备",
      lbl_start_time: "开始时间",
      lbl_end_time: "结束时间",
      lbl_remarks: "备注（选填）",
      ph_remarks: "其他说明...",
      btn_submit_booking: "确认提交预约",
      btn_select_venue: "选择此场地进行预约",
      btn_select_equip: "选择此设备进行预约",
      btn_deselect: "取消选择",
      err_fill_all: "请填写完整信息。",
      err_end_before_start: "结束时间必须晚于开始时间。",
      err_max_hours: "预约时长不得超过4小时。",
      btn_submitting: "提交中...",
      book_venue_success: "预约成功！可在【我的预约】中查看。",
      book_equip_success: "设备预约成功！可在【我的预约】中查看。",
      book_fail: "预约失败，请重试。",

      // ── 预约规则 ──
      bp_title: "预约规则",
      bp_max_hours: "预约时长不得超过4小时。",
      bp_late_cancel: "24小时内取消预约可能会扣除积分。",
      bp_frequent_cancel: "频繁迟取消或未到场可能导致账号暂停使用。",
      lbl_action: "操作",
      btn_approve: "通过",
      btn_reject: "拒绝",
      confirm_approve: "确认通过该预约？",
      confirm_reject: "确认拒绝该预约？",
      action_fail: "操作失败，请重试。",

      // ── 我的预约 ──
      my_bookings: "我的预约",
      my_bookings_sub: "查看和管理你的场地和设备预约",
      no_bookings: "暂无预约",
      load_fail: "加载失败",
      booking_detail: "预约详情",
      cancel_booking: "取消预约",
      lbl_title: "预约标题",
      lbl_venue: "场地",
      lbl_equipment: "设备",
      lbl_time: "时间",
      lbl_remarks_label: "备注",
      confirm_cancel: "确定要取消该预约吗？",
      cancel_fail: "取消失败",
      detail_btn: "详情",
      venue_prefix: "场地：",
      equip_prefix: "设备：",

      // ── 场地日历 ──
      venue_calendar: "场地预约日历",
      venue_calendar_sub: "选择场地查看预约日程",
      select_venue: "选择场地",
      confirmed: "已确认",
      pending: "待处理",

      // ── 管理面板 ──
      admin_center: "后台管理中心",
      admin_sub: "管理用户、场地、设备和预约",
      admin_users: "用户",
      admin_venues: "场地",
      admin_equip: "设备",
      admin_bookings: "预约",
      admin_stats: "统计",
      chart_confirmed: "已确认",
      chart_pending: "待处理",
      chart_cancelled: "已取消",
      chart_completed: "已完成",
      lbl_name: "名称",
      lbl_qty: "数量",
      lbl_user: "用户",
      no_data: "暂无数据",

      // ── 个人资料 ──
      my_profile: "个人资料",
      profile_sub: "查看你的账户信息和当前状态。",
      log_out: "退出登录",
      no_token: "未找到令牌，请先登录。",
      profile_fail: "加载资料失败。",
      lbl_username: "用户名：",
      lbl_fullname: "姓名：",
      lbl_email: "邮箱：",
      lbl_role: "角色：",
      lbl_tenant: "租户ID：",
      lbl_points: "积分：",
      na: "无",

      // ── 数据分析 ──
      analytics_title: "数据分析面板",
      analytics_sub: "预约、场地及高峰时段的使用概览。",
      booking_stats: "预约统计",
      venue_usage: "场地使用",
      peak_times: "高峰时段",
      total_bookings: "总预约数：",
      pending_bookings: "待处理：",
      confirmed_bookings: "已确认：",
      cancelled_bookings: "已取消：",
      rejected_bookings: "已拒绝：",
      completed_bookings: "已完成：",
      noshow_bookings: "未到场：",
      bookings_word: "次预约",
      hours_word: "小时",
      view_map: "查看地图",
      by_hour: "按小时",
      by_weekday: "按星期",
      no_hourly: "暂无小时数据",
      no_weekday: "暂无星期数据",

      // ── AI ──
      ai_title: "AI 顾问",
      ai_intro: "有任何关于场地预约的问题，尽管问我！",
      ai_welcome: "你好！我是你的预约助手，有关场地、设备或预约规则的问题，尽管问我！",
      ai_q1: "如何预约场地？",
      ai_q2: "推荐适合30人的场地",
      ai_q3: "迟取消会怎样？",
      ai_q4: "积分怎么用？",
      ai_placeholder: "输入你的问题...",
      ai_thinking: "AI 正在思考...",
      ai_no_answer: "无回答",
      ai_error: "AI 服务异常",

      // ── 语言 ──
      lang_label: "中文",
    },
  };

  function getLang() {
    return localStorage.getItem("app_lang") || "en";
  }

  function setLang(lang) {
    if (!LANGS[lang]) return;
    localStorage.setItem("app_lang", lang);
    document.documentElement.lang = lang === "zh" ? "zh-CN" : "en";
    applyLang();
  }

  function toggleLang() {
    setLang(getLang() === "en" ? "zh" : "en");
  }

  function t(key) {
    const lang = getLang();
    return (LANGS[lang] && LANGS[lang][key]) || (LANGS.en[key]) || key;
  }

  function applyLang() {
    // Static HTML elements with data-i18n
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      el.textContent = t(el.getAttribute("data-i18n"));
    });
    // Placeholders
    document.querySelectorAll("[data-i18n-placeholder]").forEach(function (el) {
      el.placeholder = t(el.getAttribute("data-i18n-placeholder"));
    });
    // Update toggle button label
    var btn = document.getElementById("lang-toggle-btn");
    if (btn) {
      btn.textContent = getLang() === "en" ? "中文" : "EN";
    }
    // Fire custom event for JS-rendered content
    document.dispatchEvent(new CustomEvent("langchange", { detail: { lang: getLang() } }));
  }

  // Auto-apply on turbo:load and DOMContentLoaded
  document.addEventListener("turbo:load", function () {
    document.documentElement.lang = getLang() === "zh" ? "zh-CN" : "en";
    applyLang();
  });
  document.addEventListener("DOMContentLoaded", function () {
    document.documentElement.lang = getLang() === "zh" ? "zh-CN" : "en";
    applyLang();
  });

  // Expose globally
  window.t = t;
  window.getLang = getLang;
  window.setLang = setLang;
  window.toggleLang = toggleLang;
  window.applyLang = applyLang;
})();
