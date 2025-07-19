import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';
import { motion } from 'framer-motion';
import { FiTrendingUp, FiList, FiPlus } from 'react-icons/fi';
import { topListAPI } from '../services/api';
import TopListItem from '../components/TopListItem';

const HomeContainer = styled.div`
  padding: 40px 20px;
  max-width: 1200px;
  margin: 0 auto;
`;

const Hero = styled.section`
  text-align: center;
  margin-bottom: 60px;
`;

const HeroTitle = styled(motion.h1)`
  font-size: 48px;
  font-weight: 700;
  color: white;
  margin-bottom: 16px;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
`;

const HeroSubtitle = styled(motion.p)`
  font-size: 20px;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 32px;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
  line-height: 1.6;
`;

const HeroActions = styled(motion.div)`
  display: flex;
  gap: 20px;
  justify-content: center;
  flex-wrap: wrap;
`;

const HeroButton = styled(Link)`
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 16px 32px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  text-decoration: none;
  border-radius: 12px;
  font-weight: 600;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.3);
  transition: all 0.3s ease;
  
  &:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
  }
`;

const Section = styled.section`
  margin-bottom: 60px;
`;

const SectionHeader = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 30px;
`;

const SectionTitle = styled.h2`
  font-size: 32px;
  font-weight: 600;
  color: white;
  display: flex;
  align-items: center;
  gap: 12px;
`;

const ViewAllLink = styled(Link)`
  display: flex;
  align-items: center;
  gap: 8px;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  font-weight: 500;
  transition: color 0.3s ease;
  
  &:hover {
    color: white;
  }
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
`;

const CategoriesGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
`;

const CategoryCard = styled(motion(Link))`
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  padding: 24px;
  text-decoration: none;
  color: white;
  transition: all 0.3s ease;
  
  &:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateY(-4px);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
  }
`;

const CategoryTitle = styled.h3`
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 8px;
`;

const CategoryCount = styled.p`
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  color: white;
  font-size: 18px;
`;

const Home = () => {
  const [topItems, setTopItems] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [topItemsResponse, categoriesResponse] = await Promise.all([
        topListAPI.getTopItemsByVotes(),
        topListAPI.getAllCategories()
      ]);
      
      setTopItems(topItemsResponse.data.slice(0, 6)); // Show top 6 items
      setCategories(categoriesResponse.data);
    } catch (err) {
      setError('Failed to load data');
      console.error('Error fetching data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (itemId) => {
    try {
      await topListAPI.voteForItem(itemId);
      // Refresh the top items
      const response = await topListAPI.getTopItemsByVotes();
      setTopItems(response.data.slice(0, 6));
    } catch (err) {
      console.error('Error voting for item:', err);
    }
  };

  const handleDelete = async (itemId) => {
    try {
      await topListAPI.deleteItem(itemId);
      setTopItems(topItems.filter(item => item.id !== itemId));
    } catch (err) {
      console.error('Error deleting item:', err);
    }
  };

  if (loading) {
    return <LoadingSpinner>Loading amazing lists...</LoadingSpinner>;
  }

  if (error) {
    return <LoadingSpinner>{error}</LoadingSpinner>;
  }

  return (
    <HomeContainer>
      <Hero>
        <HeroTitle
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          Create Amazing Top Lists
        </HeroTitle>
        <HeroSubtitle
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          Discover, create, and vote on the best lists across all categories. 
          From movies to music, books to travel destinations.
        </HeroSubtitle>
        <HeroActions
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
        >
          <HeroButton to="/create">
            <FiPlus />
            Create New List
          </HeroButton>
          <HeroButton to="#categories">
            <FiList />
            Browse Categories
          </HeroButton>
        </HeroActions>
      </Hero>

      <Section>
        <SectionHeader>
          <SectionTitle>
            <FiTrendingUp />
            Trending Now
          </SectionTitle>
        </SectionHeader>
        <Grid>
          {topItems.map((item) => (
            <TopListItem
              key={item.id}
              item={item}
              onVote={handleVote}
              onDelete={handleDelete}
            />
          ))}
        </Grid>
      </Section>

      <Section id="categories">
        <SectionHeader>
          <SectionTitle>
            <FiList />
            Categories
          </SectionTitle>
        </SectionHeader>
        <CategoriesGrid>
          {categories.map((category) => (
            <CategoryCard
              key={category}
              to={`/category/${category}`}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.3 }}
            >
              <CategoryTitle>{category}</CategoryTitle>
              <CategoryCount>Explore {category.toLowerCase()} lists</CategoryCount>
            </CategoryCard>
          ))}
        </CategoriesGrid>
      </Section>
    </HomeContainer>
  );
};

export default Home;
