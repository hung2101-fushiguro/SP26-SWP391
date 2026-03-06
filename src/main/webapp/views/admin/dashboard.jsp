<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Admin Dashboard</title>
    </head>
    <body style="background-color: #f0f2f5;">
        <div style="text-align: center; margin-top: 50px;">
            <h1>👑 TRANG QUẢN TRỊ ADMIN</h1>
            <p>Chào sếp: <b>${sessionScope.account.fullName}</b></p>
            
            <div style="margin-top: 20px;">
                <button>Quản lý Người dùng</button>
                <button>Quản lý Nhà hàng</button>
                <button>Duyệt Đơn hàng</button>
            </div>
            
            <br><br>
            <a href="../logout">Đăng Xuất</a>
        </div>
    </body>
</html>