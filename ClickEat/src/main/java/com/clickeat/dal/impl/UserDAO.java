package com.clickeat.dal.impl;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import com.clickeat.dal.interfaces.IUserDAO;
import com.clickeat.model.User;

public class UserDAO extends AbstractDAO<User> implements IUserDAO {
    
    @Override //day la ham map du lieu tu 1 dong trong database sang object java
    protected User mapRow(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("id"));
        user.setFullName(rs.getString("fullname"));
        user.setEmail(rs.getString("email"));
        user.setPhone(rs.getString("phone"));
        user.setPasswordHash(rs.getString("password_hash"));
        user.setRole(rs.getString("role"));
        user.setStatus(rs.getString("status"));
        user.setCreatedAt(rs.getTimestamp("created_at"));
        return user;
    }
    @Override
    public User checkLogin(String username, String password) {
        String sql = "SELECT * FROM Users WHERE (phone = ? OR email = ?) AND password_hash = ? AND status = 'ACTIVE'";
        return queryOne(sql, username, username, password);
    }
    @Override
    public boolean checkPhoneExist(String phone){
        String sql = "SELECT * FROM Users WHERE phone = ?";
        List<User> list = query(sql, phone);
        return !list.isEmpty();
    }
    @Override
    public boolean checkEmailExist(String email){
        String sql = "SELECT * FROM Users WHERE email = ?";
        List<User> list = query(sql, email);
        return !list.isEmpty();
    }
    @Override
    public List<User> findByRole(String role){
        String sql = "SELECT * FROM Users WHERE role = ?";
        return query(sql, role);
    }
    @Override
    public List<User> searchUsers(String keyword){
        String searchPattern = "%" + keyword + "%";
        String sql = "SELECT * FROM Users WHERE full_name LIKE ? OR email LIKE ? OR phone LIKE ?";
        return query(sql, searchPattern, searchPattern, searchPattern);
    }
    @Override
    public boolean changePassword(int userId, String newPasswordHash) {
        String sql = "UPDATE Users SET password_hash = ?, updated_at = GETDATE() WHERE id = ?";
        // update() trả về số dòng ảnh hưởng, > 0 nghĩa là thành công
        return update(sql, newPasswordHash, userId) > 0;
    }
    @Override
    public List<User> findAll() {
        String sql = "SELECT * FROM Users";
        return query(sql);
    }
    @Override
    public User findById(int id) {
        String sql = "SELECT * FROM Users WHERE id = ?";
        return queryOne(sql, id);
    }
    @Override
    public int insert(User user) {
        // Insert user mới (Đăng ký)
        // status mặc định là ACTIVE
        String sql = "INSERT INTO Users (full_name, email, phone, password_hash, role, status) VALUES (?, ?, ?, ?, ?, ?)";
        return update(sql, 
                user.getFullName(), 
                user.getEmail(), 
                user.getPhone(), 
                user.getPasswordHash(), 
                user.getRole(), 
                "ACTIVE");
    }
    @Override
    public boolean update(User user) {
        // Cập nhật thông tin profile (Tên, Email)
        String sql = "UPDATE Users SET full_name = ?, email = ?, updated_at = GETDATE() WHERE id = ?";
        return update(sql, user.getFullName(), user.getEmail(), user.getId()) > 0;
    }
    @Override
    public boolean delete(int id) {
        // Xóa mềm (Soft Delete) - Chỉ đổi trạng thái sang INACTIVE chứ không xóa mất dữ liệu
        String sql = "UPDATE Users SET status = 'INACTIVE', updated_at = GETDATE() WHERE id = ?";
        return update(sql, id) > 0;
    }
}
