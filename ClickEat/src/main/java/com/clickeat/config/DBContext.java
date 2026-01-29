package com.clickeat.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DBContext {
    public static String driverName = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
    public static String dbURL = "jdbc:sqlserver://localhost:1433;databaseName=BookZone;encrypt=true;trustServerCertificate=true;";
    public static String userDB = "sa";
    public static String passDB = "hungsatoru";
    
    public static Connection getConnection(){
        Connection con = null;
        try{
            Class.forName(driverName);
            con = DriverManager.getConnection(dbURL, userDB, passDB);
            return con;
        } catch(Exception ex){
            Logger.getLogger(DBContext.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }
    public static void main(String[] args) {
        try(Connection con = getConnection()){
            if(con!=null)
                System.out.println(" Connect to ClickEat Success");
        } catch(SQLException ex){
            Logger.getLogger(DBContext.class.getName()).log(Level.SEVERE, null, ex);
        }
    }
}
