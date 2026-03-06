package com.clickeat.main;

import com.clickeat.dal.impl.UserDAO;
import com.clickeat.model.User;
import java.util.List;

public class Testconnection {
    public static void main(String[] args) {
        UserDAO userDAO = new UserDAO();

        // 1. Test hàm lấy tất cả
        List<User> list = userDAO.findAll();
        System.out.println("🔹 Tổng số user tìm thấy: " + list.size());

        if (!list.isEmpty()) {
            System.out.println("   - User đầu tiên: " + list.get(0).getFullName());
        }

        // 2. Test hàm Login (Thử với tài khoản Admin trong SQL)
        // Username: 0900000001, Pass: hash_admin (Dữ liệu mẫu trong file SQL)
        User admin = userDAO.checkLogin("0900000001", "hash_admin");
        
        if (admin != null) {
            System.out.println("✅ Đăng nhập Admin THÀNH CÔNG! Xin chào: " + admin.getFullName());
        } else {
            System.out.println("❌ Đăng nhập THẤT BẠI! Kiểm tra lại code UserDAO hoặc dữ liệu SQL.");
        }
    }
}