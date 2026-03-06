<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="jakarta.tags.core" %> <!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Đăng Nhập - ClickEat</title>
        <style>
            body { font-family: Arial, sans-serif; display: flex; justify-content: center; margin-top: 50px; }
            .login-container { border: 1px solid #ccc; padding: 20px; border-radius: 8px; width: 300px; }
            input { width: 100%; padding: 8px; margin: 5px 0; box-sizing: border-box; }
            button { width: 100%; padding: 10px; background-color: #28a745; color: white; border: none; cursor: pointer; }
            .error { color: red; font-size: 14px; text-align: center; }
        </style>
    </head>
    <body>
        <div class="login-container">
            <h2 style="text-align: center;">ClickEat Login</h2>
            
            <c:if test="${not empty error}">
                <p class="error">${error}</p>
            </c:if>

            <form action="login" method="post">
                <label>Tài khoản (SĐT/Email):</label>
                <input type="text" name="username" required>
                
                <label>Mật khẩu:</label>
                <input type="password" name="password" required>
                
                <button type="submit">Đăng Nhập</button>
            </form>
        </div>
    </body>
</html>