package com.clickeat.servlet;

import com.clickeat.dao.AnalyticsDAO;
import com.clickeat.util.JsonUtil;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.*;

/**
 * GET  /api/wallet                    – wallet stats + recent transactions
 * GET  /api/wallet/transactions       – paginated order history
 * GET  /api/wallet/withdrawals        – list of withdrawal requests
 * POST /api/wallet/withdraw           – request a new withdrawal
 */
public class WalletServlet extends HttpServlet {

    private final AnalyticsDAO dao = new AnalyticsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo(); // null | "/transactions" | "/withdrawals"

        try {
            if ("/transactions".equals(pathInfo)) {
                int limit = parseIntParam(req, "limit", 20);
                ResponseUtil.ok(resp, dao.getWalletTransactions(merchantId, limit));
            } else if ("/withdrawals".equals(pathInfo)) {
                int limit = parseIntParam(req, "limit", 50);
                ResponseUtil.ok(resp, dao.getWithdrawals(merchantId, limit));
            } else {
                Map<String, Object> result = new LinkedHashMap<>();
                result.putAll(dao.getWalletStats(merchantId));
                result.put("recentTransactions", dao.getWalletTransactions(merchantId, 10));
                result.put("withdrawals", dao.getWithdrawals(merchantId, 5));
                ResponseUtil.ok(resp, result);
            }
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo(); // "/withdraw"

        if (!"/withdraw".equals(pathInfo)) {
            ResponseUtil.badRequest(resp, "Use POST /api/wallet/withdraw");
            return;
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = JsonUtil.readBody(req, Map.class);

            String amountStr   = String.valueOf(body.getOrDefault("amount", "0"));
            String bankName    = String.valueOf(body.getOrDefault("bankName", "")).trim();
            String bankAccount = String.valueOf(body.getOrDefault("bankAccount", "")).trim();
            String holder      = String.valueOf(body.getOrDefault("accountHolder", "")).trim();

            if (bankName.isEmpty() || bankAccount.isEmpty() || holder.isEmpty()) {
                ResponseUtil.badRequest(resp, "bankName, bankAccount và accountHolder là bắt buộc");
                return;
            }

            BigDecimal amount;
            try {
                amount = new BigDecimal(amountStr);
            } catch (NumberFormatException ex) {
                ResponseUtil.badRequest(resp, "Số tiền không hợp lệ");
                return;
            }

            if (amount.compareTo(new BigDecimal("100000")) < 0) {
                ResponseUtil.badRequest(resp, "Số tiền rút tối thiểu là 100,000đ");
                return;
            }

            // Check available balance
            Map<String, Object> stats = dao.getWalletStats(merchantId);
            BigDecimal available = (BigDecimal) stats.get("availableBalance");
            if (available == null || amount.compareTo(available) > 0) {
                ResponseUtil.badRequest(resp, "Số tiền rút vượt quá số dư khả dụng");
                return;
            }

            long id = dao.createWithdrawal(merchantId, amount, bankName, bankAccount, holder);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("id", id);
            result.put("amount", amount);
            result.put("status", "PENDING");
            result.put("message", "Yêu cầu rút tiền đã được ghi nhận. Thường xử lý trong 1-2 ngày làm việc.");
            ResponseUtil.ok(resp, result);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    private int parseIntParam(HttpServletRequest req, String name, int def) {
        String v = req.getParameter(name);
        if (v == null) return def;
        try {
            return Integer.parseInt(v);
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
