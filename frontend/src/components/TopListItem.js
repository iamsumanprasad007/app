import React from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';
import { motion } from 'framer-motion';
import { FiHeart, FiEdit, FiTrash2, FiImage } from 'react-icons/fi';

const ItemCard = styled(motion.div)`
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  position: relative;
  
  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
  }
`;

const RankBadge = styled.div`
  position: absolute;
  top: 15px;
  left: 15px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
  z-index: 2;
`;

const ImageContainer = styled.div`
  position: relative;
  height: 200px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
`;

const ItemImage = styled.img`
  width: 100%;
  height: 100%;
  object-fit: cover;
`;

const ImagePlaceholder = styled.div`
  color: #6c757d;
  font-size: 48px;
`;

const ItemContent = styled.div`
  padding: 20px;
`;

const ItemTitle = styled.h3`
  font-size: 18px;
  font-weight: 600;
  color: #212529;
  margin-bottom: 8px;
  line-height: 1.4;
`;

const ItemDescription = styled.p`
  color: #6c757d;
  font-size: 14px;
  line-height: 1.5;
  margin-bottom: 15px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
`;

const ItemFooter = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 15px;
`;

const VoteButton = styled.button`
  display: flex;
  align-items: center;
  gap: 6px;
  background: ${props => props.voted ? '#dc3545' : '#f8f9fa'};
  color: ${props => props.voted ? 'white' : '#495057'};
  border: 1px solid ${props => props.voted ? '#dc3545' : '#dee2e6'};
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    background: ${props => props.voted ? '#c82333' : '#e9ecef'};
    transform: translateY(-1px);
  }
`;

const ActionButtons = styled.div`
  display: flex;
  gap: 8px;
`;

const ActionButton = styled(Link)`
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: #f8f9fa;
  color: #495057;
  border-radius: 6px;
  text-decoration: none;
  transition: all 0.3s ease;
  
  &:hover {
    background: #e9ecef;
    transform: translateY(-1px);
  }
`;

const DeleteButton = styled.button`
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: #f8f9fa;
  color: #dc3545;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    background: #dc3545;
    color: white;
    transform: translateY(-1px);
  }
`;

const CategoryBadge = styled.span`
  background: #e9ecef;
  color: #495057;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
`;

const TopListItem = ({ item, onVote, onDelete, showActions = true }) => {
  const handleVote = () => {
    onVote(item.id);
  };

  const handleDelete = () => {
    if (window.confirm('Are you sure you want to delete this item?')) {
      onDelete(item.id);
    }
  };

  return (
    <ItemCard
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <RankBadge>#{item.rank}</RankBadge>
      
      <ImageContainer>
        {item.imageUrl ? (
          <ItemImage src={item.imageUrl} alt={item.title} />
        ) : (
          <ImagePlaceholder>
            <FiImage />
          </ImagePlaceholder>
        )}
      </ImageContainer>
      
      <ItemContent>
        <ItemTitle>{item.title}</ItemTitle>
        <CategoryBadge>{item.category}</CategoryBadge>
        {item.description && (
          <ItemDescription>{item.description}</ItemDescription>
        )}
        
        <ItemFooter>
          <VoteButton onClick={handleVote}>
            <FiHeart />
            {item.voteCount || 0}
          </VoteButton>
          
          {showActions && (
            <ActionButtons>
              <ActionButton to={`/edit/${item.id}`}>
                <FiEdit />
              </ActionButton>
              <DeleteButton onClick={handleDelete}>
                <FiTrash2 />
              </DeleteButton>
            </ActionButtons>
          )}
        </ItemFooter>
      </ItemContent>
    </ItemCard>
  );
};

export default TopListItem;
