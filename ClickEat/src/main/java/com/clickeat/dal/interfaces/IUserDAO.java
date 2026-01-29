package com.clickeat.dal.interfaces;

import java.util.List;

import com.clickeat.model.User;

public interface IUserDAO extends IGenericDAO<User> {
    User checkLogin(String username, String password);
    boolean checkPhoneExist(String phone);
    boolean checkEmailExist(String email);
    List<User> findByRole(String role);
    List<User> searchUsers(String keyword);
    boolean changePassword(int userId, String newPasswordHash);
}
