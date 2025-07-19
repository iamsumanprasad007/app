import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import styled from 'styled-components';
import { FiHome, FiPlus, FiList, FiTrendingUp } from 'react-icons/fi';
import { topListAPI } from '../services/api';

const HeaderContainer = styled.header`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  z-index: 1000;
  padding: 0 20px;
`;

const HeaderContent = styled.div`
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 70px;
`;

const Logo = styled(Link)`
  font-size: 24px;
  font-weight: 700;
  color: #667eea;
  text-decoration: none;
  display: flex;
  align-items: center;
  gap: 8px;
`;

const Nav = styled.nav`
  display: flex;
  align-items: center;
  gap: 30px;
`;

const NavLink = styled(Link)`
  display: flex;
  align-items: center;
  gap: 8px;
  color: #495057;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.3s ease;
  
  &:hover {
    color: #667eea;
  }
`;

const CategorySelect = styled.select`
  padding: 8px 12px;
  border: 2px solid #e9ecef;
  border-radius: 6px;
  background: white;
  color: #495057;
  font-weight: 500;
  cursor: pointer;
  transition: border-color 0.3s ease;
  
  &:focus {
    outline: none;
    border-color: #667eea;
  }
`;

const Header = () => {
  const [categories, setCategories] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      const response = await topListAPI.getAllCategories();
      setCategories(response.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const handleCategoryChange = (e) => {
    const category = e.target.value;
    if (category) {
      navigate(`/category/${category}`);
    }
  };

  return (
    <HeaderContainer>
      <HeaderContent>
        <Logo to="/">
          <FiList />
          TopList
        </Logo>
        
        <Nav>
          <NavLink to="/">
            <FiHome />
            Home
          </NavLink>
          
          <CategorySelect onChange={handleCategoryChange} defaultValue="">
            <option value="">Select Category</option>
            {categories.map(category => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </CategorySelect>
          
          <NavLink to="/create">
            <FiPlus />
            Add Item
          </NavLink>
        </Nav>
      </HeaderContent>
    </HeaderContainer>
  );
};

export default Header;
