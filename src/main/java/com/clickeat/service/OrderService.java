package com.clickeat.service;

import com.clickeat.dao.OrderDAO;
import com.clickeat.model.OrderModel;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

public class OrderService {

    private final OrderDAO orderDAO = new OrderDAO();

    /**
     * Paginated order list, optionally filtered by order_status.
     */
    public Map<String, Object> getOrders(long merchantUserId, String status,
            int page, int pageSize) throws SQLException {
        List<OrderModel> orders = orderDAO.findByMerchant(merchantUserId, status, page, pageSize);
        int total = orderDAO.countByMerchant(merchantUserId, status);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("items", orders);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);
        result.put("totalPages", (int) Math.ceil((double) total / pageSize));
        return result;
    }

    public Optional<OrderModel> getOrderById(long id) throws SQLException {
        return orderDAO.findById(id);
    }

    /**
     * Merchant-allowed status transitions: MERCHANT_ACCEPTED,
     * MERCHANT_REJECTED, PREPARING, READY_FOR_PICKUP, CANCELLED
     */
    private static final Set<String> ALLOWED_STATUSES = Set.of(
            "MERCHANT_ACCEPTED", "MERCHANT_REJECTED",
            "PREPARING", "READY_FOR_PICKUP", "CANCELLED"
    );

    public boolean updateStatus(long orderId, long merchantUserId, String status) throws SQLException {
        if (!ALLOWED_STATUSES.contains(status.toUpperCase())) {
            throw new IllegalArgumentException("Invalid or disallowed status: " + status);
        }
        return orderDAO.updateStatus(orderId, merchantUserId, status.toUpperCase());
    }
}
