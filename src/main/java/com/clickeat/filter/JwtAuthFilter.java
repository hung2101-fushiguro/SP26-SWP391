package com.clickeat.filter;

import com.clickeat.security.JwtUtil;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Set;

/**
 * JWT authentication filter. Skips /api/auth/** (login, register). For all
 * other /api/** endpoints it validates the Bearer token and stores merchantId
 * as a request attribute.
 */
public class JwtAuthFilter implements Filter {

    /**
     * Public paths that don't need a token.
     */
    private static final Set<String> PUBLIC_PATHS = Set.of(
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/refresh",
            "/api/auth/google",
            "/api/auth/forgot-password",
            "/api/auth/reset-password"
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        // Build full path: servletPath + pathInfo (Tomcat splits them)
        // e.g. servletPath="/api/auth", pathInfo="/login" → "/api/auth/login"
        String servletPath = req.getServletPath();
        String pathInfo = req.getPathInfo();
        String path = (pathInfo != null) ? servletPath + pathInfo : servletPath;

        // Let public paths through
        if (PUBLIC_PATHS.contains(path) || path.startsWith("/api/auth")) {
            chain.doFilter(request, response);
            return;
        }

        // Extract bearer token
        String authHeader = req.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            sendUnauthorized(resp, "Missing or invalid Authorization header");
            return;
        }

        String token = authHeader.substring(7);

        if (!JwtUtil.validateToken(token)) {
            sendUnauthorized(resp, "Token is expired or invalid");
            return;
        }

        // Attach merchantId so servlets can use it without re-parsing the token
        req.setAttribute("merchantId", JwtUtil.extractMerchantId(token));
        req.setAttribute("merchantEmail", JwtUtil.extractEmail(token));

        chain.doFilter(request, response);
    }

    private void sendUnauthorized(HttpServletResponse resp, String message) throws IOException {
        resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write(
                "{\"success\":false,\"message\":\"" + message + "\"}"
        );
    }
}
