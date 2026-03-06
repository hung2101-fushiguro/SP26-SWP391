package com.clickeat.service;

import com.clickeat.dao.ReviewDAO;
import com.clickeat.model.ReviewModel;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class ReviewService {

    private final ReviewDAO reviewDAO = new ReviewDAO();

    /**
     * Paginated reviews for the merchant (from dbo.Ratings WHERE
     * target_type='MERCHANT').
     */
    public Map<String, Object> getReviews(long merchantUserId, int page, int pageSize) throws SQLException {
        List<ReviewModel> reviews = reviewDAO.findByMerchant(merchantUserId, page, pageSize);
        int total = reviewDAO.countByMerchant(merchantUserId);
        double avg = reviewDAO.averageRating(merchantUserId);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("items", reviews);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);
        result.put("totalPages", (int) Math.ceil((double) total / pageSize));
        result.put("avgStars", Math.round(avg * 10.0) / 10.0);
        return result;
    }

    public Optional<ReviewModel> getById(long id) throws SQLException {
        return reviewDAO.findById(id);
    }
}
