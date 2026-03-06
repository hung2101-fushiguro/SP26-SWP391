package com.clickeat.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Singleton HikariCP DataSource. Replaces raw DriverManager calls in DBContext.
 */

public final class DataSourceConfig {

    private static final HikariDataSource DATA_SOURCE;

    static {
        HikariConfig cfg = new HikariConfig();
        cfg.setJdbcUrl(
                "jdbc:sqlserver://localhost:1433;"
                + "databaseName=ClickEat;"
                + "encrypt=true;"
                + "trustServerCertificate=true;"
        );
        cfg.setUsername("sa");
        cfg.setPassword("11012004");
        cfg.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

        // Pool settings
        cfg.setMaximumPoolSize(20);
        cfg.setMinimumIdle(5);
        cfg.setConnectionTimeout(30_000);
        cfg.setIdleTimeout(600_000);
        cfg.setMaxLifetime(1_800_000);
        cfg.setPoolName("ClickEatPool");

        DATA_SOURCE = new HikariDataSource(cfg);
    }

    private DataSourceConfig() {}

    public static DataSource get() {
        return DATA_SOURCE;
    }

    /** Convenience method used by DAOs. */
    public static Connection getConnection() throws SQLException {
        return DATA_SOURCE.getConnection();
    }
}
