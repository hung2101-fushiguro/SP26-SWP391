package com.clickeat.service;

import com.clickeat.dao.CategoryDAO;
import com.clickeat.dao.MenuItemDAO;
import com.clickeat.model.CategoryModel;
import com.clickeat.model.MenuItem;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

public class MenuService {

    private final CategoryDAO categoryDAO = new CategoryDAO();
    private final MenuItemDAO menuItemDAO = new MenuItemDAO();

    // ------------------------------------------------------------ categories
    public List<CategoryModel> getCategories(long merchantUserId) throws SQLException {
        return categoryDAO.findByMerchant(merchantUserId);
    }

    public CategoryModel createCategory(long merchantUserId, String name) throws SQLException {
        long id = categoryDAO.create(merchantUserId, name);
        return categoryDAO.findById(id).orElseThrow();
    }

    public CategoryModel updateCategory(long categoryId, long merchantUserId, String name) throws SQLException {
        boolean ok = categoryDAO.update(categoryId, merchantUserId, name);
        if (!ok) {
            throw new IllegalArgumentException("Category not found or forbidden");
        }
        return categoryDAO.findById(categoryId).orElseThrow();
    }

    public boolean deleteCategory(long categoryId, long merchantUserId) throws SQLException {
        return categoryDAO.delete(categoryId, merchantUserId);
    }

    // -------------------------------------------------------------- menu items
    public List<MenuItem> getMenuItems(long merchantUserId) throws SQLException {
        return menuItemDAO.findByMerchant(merchantUserId);
    }

    public Optional<MenuItem> getMenuItemById(long id) throws SQLException {
        return menuItemDAO.findById(id);
    }

    public MenuItem createMenuItem(long merchantUserId, long categoryId, String name,
            String description, BigDecimal price, String imageUrl) throws SQLException {
        long id = menuItemDAO.create(merchantUserId, categoryId, name, description, price, imageUrl);
        return menuItemDAO.findById(id).orElseThrow();
    }

    public MenuItem updateMenuItem(long id, long merchantUserId, long categoryId,
            String name, String description, BigDecimal price,
            String imageUrl, boolean isAvailable) throws SQLException {
        boolean ok = menuItemDAO.update(id, merchantUserId, categoryId, name, description, price, imageUrl, isAvailable);
        if (!ok) {
            throw new IllegalArgumentException("MenuItem not found or forbidden");
        }
        return menuItemDAO.findById(id).orElseThrow();
    }

    public boolean toggleAvailability(long id, long merchantUserId, boolean available) throws SQLException {
        return menuItemDAO.toggleAvailability(id, merchantUserId, available);
    }

    public boolean deleteMenuItem(long id, long merchantUserId) throws SQLException {
        return menuItemDAO.delete(id, merchantUserId);
    }
}
