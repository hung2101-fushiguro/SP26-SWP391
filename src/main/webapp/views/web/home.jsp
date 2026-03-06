<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html>
    <head>
        <title>Trang Chủ - ClickEat</title>
        <style>
            .header { background-color: #f8f9fa; padding: 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #ddd; }
            .btn-logout { background-color: #dc3545; color: white; padding: 8px 15px; text-decoration: none; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h2>ClickEat 🍔</h2>
            <div>
                <span>Xin chào, <b>${sessionScope.account.fullName}</b>!</span>
                <a href="logout" class="btn-logout">Đăng Xuất</a>
            </div>
        </div>

        <div style="padding: 20px;">
            <h3>Danh sách món ngon hôm nay</h3>
            <p><i>(Chỗ này sau nhóm sẽ code hiển thị list món ăn từ Database...)</i></p>
        </div>
    </body>
</html>