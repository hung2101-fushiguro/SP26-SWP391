package com.clickeat.dal.impl;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import com.clickeat.config.DBContext;
import com.clickeat.dal.interfaces.IGenericDAO;

public abstract class AbstractDAO<T> extends DBContext implements IGenericDAO<T> {
    protected abstract T mapRow(ResultSet rs) throws SQLException;
    //ham set tham so cho cau lenh sql
    protected void setParameters(PreparedStatement ps, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            Object parameter = parameters[i];
            int index = i + 1;
            if (parameter instanceof Integer) {
                ps.setInt(index, (Integer) parameter);
            } else if (parameter instanceof String) {
                ps.setString(index, (String) parameter);
            } else if (parameter instanceof Timestamp) {
                ps.setTimestamp(index, (Timestamp) parameter);
            } else if (parameter instanceof Double) {
                ps.setDouble(index, (Double) parameter);
            } else if (parameter instanceof Long) {
                ps.setLong(index, (Long) parameter);
            } else {
                ps.setObject(index, parameter);
            }
        }
    }

    protected List<T> query(String sql, Object... parameters){
        List<T> result = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try{
            conn = getConnection();
            if(conn != null){
                ps = conn.prepareStatement(sql);
                setParameters(ps, parameters);
                rs = ps.executeQuery();
                while(rs.next()){
                    result.add(mapRow(rs));
                }
            }
        }catch(SQLException e){
            e.printStackTrace();
        }finally{
            closeResources(conn, ps, rs);
        }
        return result;
    }
    protected T queryOne(String sql, Object... parameters){
        List<T> result = query(sql, parameters);
        return result.isEmpty() ? null : result.get(0);
    }
    protected int update(String sql, Object... parameters){
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try{
            conn = getConnection();
            if(conn != null){
                ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
                setParameters(ps, parameters);
                int rows = ps.executeUpdate();
                if(rows > 0){
                    rs = ps.getGeneratedKeys();
                    if(rs.next()){
                        return rs.getInt(1);
                    }
                    return rows;
                }
            }
        }catch(SQLException e){
            e.printStackTrace();
        }finally{
            closeResources(conn, ps, rs);
        }
        return 0;
    }

    protected void closeResources(Connection conn, PreparedStatement ps, ResultSet rs){
        if(rs != null){
            try{
                rs.close();
            }catch(SQLException e){
                e.printStackTrace();
            }
        }
        if(ps != null){
            try{
                ps.close();
            }catch(SQLException e){
                e.printStackTrace();
            }
        }
        if(conn != null){
            try{
                conn.close();
            }catch(SQLException e){
                e.printStackTrace();
            }
        }
    }
}
