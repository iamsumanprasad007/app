import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import styled from 'styled-components';
import { motion } from 'framer-motion';
import { FiEdit, FiSave, FiArrowLeft } from 'react-icons/fi';
import { topListAPI } from '../services/api';

const EditContainer = styled.div`
  padding: 40px 20px;
  max-width: 800px;
  margin: 0 auto;
`;

const Header = styled.div`
  text-align: center;
  margin-bottom: 40px;
`;

const Title = styled(motion.h1)`
  font-size: 36px;
  font-weight: 700;
  color: white;
  margin-bottom: 16px;
`;

const Subtitle = styled(motion.p)`
  font-size: 18px;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 32px;
`;

const FormCard = styled(motion.div)`
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  padding: 40px;
`;

const Form = styled.form`
  display: flex;
  flex-direction: column;
  gap: 24px;
`;

const FormGroup = styled.div`
  display: flex;
  flex-direction: column;
  gap: 8px;
`;

const Label = styled.label`
  font-weight: 600;
  color: white;
  font-size: 16px;
`;

const Input = styled.input`
  padding: 16px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 16px;
  backdrop-filter: blur(10px);
  transition: border-color 0.3s ease;
  
  &::placeholder {
    color: rgba(255, 255, 255, 0.6);
  }
  
  &:focus {
    outline: none;
    border-color: rgba(255, 255, 255, 0.5);
  }
`;

const TextArea = styled.textarea`
  padding: 16px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 16px;
  backdrop-filter: blur(10px);
  transition: border-color 0.3s ease;
  resize: vertical;
  min-height: 120px;
  font-family: inherit;
  
  &::placeholder {
    color: rgba(255, 255, 255, 0.6);
  }
  
  &:focus {
    outline: none;
    border-color: rgba(255, 255, 255, 0.5);
  }
`;

const Select = styled.select`
  padding: 16px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 16px;
  backdrop-filter: blur(10px);
  transition: border-color 0.3s ease;
  cursor: pointer;
  
  &:focus {
    outline: none;
    border-color: rgba(255, 255, 255, 0.5);
  }
  
  option {
    background: #333;
    color: white;
  }
`;

const ButtonGroup = styled.div`
  display: flex;
  gap: 16px;
  justify-content: center;
  margin-top: 32px;
`;

const Button = styled.button`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 32px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
`;

const PrimaryButton = styled(Button)`
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  
  &:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
  }
`;

const SecondaryButton = styled(Button)`
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  
  &:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }
`;

const ErrorMessage = styled.div`
  background: rgba(220, 53, 69, 0.2);
  color: #ff6b7a;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid rgba(220, 53, 69, 0.3);
  margin-bottom: 20px;
`;

const SuccessMessage = styled.div`
  background: rgba(40, 167, 69, 0.2);
  color: #51cf66;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid rgba(40, 167, 69, 0.3);
  margin-bottom: 20px;
`;

const LoadingSpinner = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  color: white;
  font-size: 18px;
`;

const EditItem = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    rank: 1,
    imageUrl: ''
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const categories = ['Movies', 'Books', 'Music', 'Travel', 'Food', 'Technology', 'Sports', 'Art'];

  useEffect(() => {
    fetchItem();
  }, [id]);

  const fetchItem = async () => {
    try {
      setLoading(true);
      const response = await topListAPI.getItemById(id);
      const item = response.data;
      setFormData({
        title: item.title || '',
        description: item.description || '',
        category: item.category || '',
        rank: item.rank || 1,
        imageUrl: item.imageUrl || ''
      });
    } catch (err) {
      setError('Failed to load item');
      console.error('Error fetching item:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'rank' ? parseInt(value) || 1 : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.title.trim() || !formData.category) {
      setError('Title and category are required');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      
      await topListAPI.updateItem(id, formData);
      setSuccess(true);
      
      setTimeout(() => {
        navigate(`/category/${formData.category}`);
      }, 1500);
    } catch (err) {
      setError('Failed to update item. Please try again.');
      console.error('Error updating item:', err);
    } finally {
      setSaving(false);
    }
  };

  const handleBack = () => {
    navigate(-1);
  };

  if (loading) {
    return <LoadingSpinner>Loading item...</LoadingSpinner>;
  }

  return (
    <EditContainer>
      <Header>
        <Title
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          Edit Item
        </Title>
        <Subtitle
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          Update your item details
        </Subtitle>
      </Header>

      <FormCard
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.4 }}
      >
        {error && <ErrorMessage>{error}</ErrorMessage>}
        {success && <SuccessMessage>Item updated successfully! Redirecting...</SuccessMessage>}
        
        <Form onSubmit={handleSubmit}>
          <FormGroup>
            <Label htmlFor="title">Title *</Label>
            <Input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Enter item title"
              required
            />
          </FormGroup>

          <FormGroup>
            <Label htmlFor="category">Category *</Label>
            <Select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              required
            >
              <option value="">Select a category</option>
              {categories.map(category => (
                <option key={category} value={category}>
                  {category}
                </option>
              ))}
            </Select>
          </FormGroup>

          <FormGroup>
            <Label htmlFor="description">Description</Label>
            <TextArea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Enter item description"
            />
          </FormGroup>

          <FormGroup>
            <Label htmlFor="rank">Rank</Label>
            <Input
              type="number"
              id="rank"
              name="rank"
              value={formData.rank}
              onChange={handleChange}
              min="1"
              placeholder="Enter rank position"
            />
          </FormGroup>

          <FormGroup>
            <Label htmlFor="imageUrl">Image URL</Label>
            <Input
              type="url"
              id="imageUrl"
              name="imageUrl"
              value={formData.imageUrl}
              onChange={handleChange}
              placeholder="Enter image URL"
            />
          </FormGroup>

          <ButtonGroup>
            <SecondaryButton type="button" onClick={handleBack}>
              <FiArrowLeft />
              Back
            </SecondaryButton>
            <PrimaryButton type="submit" disabled={saving}>
              <FiSave />
              {saving ? 'Updating...' : 'Update Item'}
            </PrimaryButton>
          </ButtonGroup>
        </Form>
      </FormCard>
    </EditContainer>
  );
};

export default EditItem;
