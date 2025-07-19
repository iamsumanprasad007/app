import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import styled from 'styled-components';
import { motion } from 'framer-motion';
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd';
import { FiList, FiTrendingUp, FiMove } from 'react-icons/fi';
import { topListAPI } from '../services/api';
import TopListItem from '../components/TopListItem';

const CategoryContainer = styled.div`
  padding: 40px 20px;
  max-width: 1200px;
  margin: 0 auto;
`;

const CategoryHeader = styled.div`
  text-align: center;
  margin-bottom: 40px;
`;

const CategoryTitle = styled(motion.h1)`
  font-size: 42px;
  font-weight: 700;
  color: white;
  margin-bottom: 16px;
  text-transform: capitalize;
`;

const CategorySubtitle = styled(motion.p)`
  font-size: 18px;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 32px;
`;

const ViewToggle = styled.div`
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-bottom: 40px;
`;

const ToggleButton = styled.button`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: ${props => props.active ? 'rgba(255, 255, 255, 0.2)' : 'transparent'};
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  
  &:hover {
    background: rgba(255, 255, 255, 0.2);
  }
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
`;

const DraggableGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
`;

const DragInstruction = styled.div`
  text-align: center;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 20px;
  font-style: italic;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  color: white;
  font-size: 18px;
`;

const CategoryView = () => {
  const { category } = useParams();
  const [items, setItems] = useState([]);
  const [viewMode, setViewMode] = useState('rank'); // 'rank' or 'votes'
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchItems();
  }, [category, viewMode]);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const response = viewMode === 'votes' 
        ? await topListAPI.getItemsByCategoryOrderByVotes(category)
        : await topListAPI.getItemsByCategory(category);
      setItems(response.data);
    } catch (err) {
      setError('Failed to load items');
      console.error('Error fetching items:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (itemId) => {
    try {
      await topListAPI.voteForItem(itemId);
      fetchItems(); // Refresh items
    } catch (err) {
      console.error('Error voting for item:', err);
    }
  };

  const handleDelete = async (itemId) => {
    try {
      await topListAPI.deleteItem(itemId);
      setItems(items.filter(item => item.id !== itemId));
    } catch (err) {
      console.error('Error deleting item:', err);
    }
  };

  const handleDragEnd = async (result) => {
    if (!result.destination || viewMode !== 'rank') return;

    const newItems = Array.from(items);
    const [reorderedItem] = newItems.splice(result.source.index, 1);
    newItems.splice(result.destination.index, 0, reorderedItem);

    // Update ranks
    const updatedItems = newItems.map((item, index) => ({
      ...item,
      rank: index + 1
    }));

    setItems(updatedItems);

    try {
      await topListAPI.updateRanks(category, updatedItems);
    } catch (err) {
      console.error('Error updating ranks:', err);
      fetchItems(); // Revert on error
    }
  };

  if (loading) {
    return <LoadingSpinner>Loading {category} items...</LoadingSpinner>;
  }

  if (error) {
    return <LoadingSpinner>{error}</LoadingSpinner>;
  }

  return (
    <CategoryContainer>
      <CategoryHeader>
        <CategoryTitle
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          {category}
        </CategoryTitle>
        <CategorySubtitle
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          Discover the best {category.toLowerCase()} according to our community
        </CategorySubtitle>
      </CategoryHeader>

      <ViewToggle>
        <ToggleButton
          active={viewMode === 'rank'}
          onClick={() => setViewMode('rank')}
        >
          <FiList />
          By Rank
        </ToggleButton>
        <ToggleButton
          active={viewMode === 'votes'}
          onClick={() => setViewMode('votes')}
        >
          <FiTrendingUp />
          By Votes
        </ToggleButton>
      </ViewToggle>

      {viewMode === 'rank' && (
        <DragInstruction>
          <FiMove style={{ marginRight: '8px' }} />
          Drag and drop items to reorder the list
        </DragInstruction>
      )}

      {viewMode === 'rank' ? (
        <DragDropContext onDragEnd={handleDragEnd}>
          <Droppable droppableId="items">
            {(provided) => (
              <DraggableGrid {...provided.droppableProps} ref={provided.innerRef}>
                {items.map((item, index) => (
                  <Draggable key={item.id} draggableId={item.id.toString()} index={index}>
                    {(provided, snapshot) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        {...provided.dragHandleProps}
                        style={{
                          ...provided.draggableProps.style,
                          transform: snapshot.isDragging 
                            ? provided.draggableProps.style?.transform 
                            : 'none',
                        }}
                      >
                        <TopListItem
                          item={item}
                          onVote={handleVote}
                          onDelete={handleDelete}
                        />
                      </div>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </DraggableGrid>
            )}
          </Droppable>
        </DragDropContext>
      ) : (
        <Grid>
          {items.map((item) => (
            <TopListItem
              key={item.id}
              item={item}
              onVote={handleVote}
              onDelete={handleDelete}
            />
          ))}
        </Grid>
      )}
    </CategoryContainer>
  );
};

export default CategoryView;
