package com.clickeat.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.InputStream;

public final class JsonUtil {

    private static final ObjectMapper MAPPER;

    static {
        MAPPER = new ObjectMapper();
        MAPPER.registerModule(new JavaTimeModule());
        MAPPER.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    private JsonUtil() {
    }

    public static ObjectMapper mapper() {
        return MAPPER;
    }

    /**
     * Deserialize request body to a Java object.
     */
    public static <T> T readBody(HttpServletRequest req, Class<T> clazz) throws IOException {
        try (InputStream is = req.getInputStream()) {
            return MAPPER.readValue(is, clazz);
        }
    }

    /**
     * Write an object as JSON to the response.
     */
    public static void writeJson(HttpServletResponse resp, Object data) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        MAPPER.writeValue(resp.getWriter(), data);
    }

    /**
     * Serialize to String.
     */
    public static String toJson(Object obj) throws IOException {
        return MAPPER.writeValueAsString(obj);
    }
}
