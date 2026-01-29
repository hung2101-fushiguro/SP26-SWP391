package com.clickeat.dal.interfaces;

import java.util.List;

public interface IGenericDAO<T> {
    List<T> findAll();
    int insert(T t);
    boolean update(T t);
    boolean delete(T t);
    T findById(int id);
}
