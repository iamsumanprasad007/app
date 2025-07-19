import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for debugging
api.interceptors.request.use(
  (config) => {
    console.log('API Request:', config);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export const topListAPI = {
  // Get all items
  getAllItems: () => api.get('/toplist'),
  
  // Get item by ID
  getItemById: (id) => api.get(`/toplist/${id}`),
  
  // Get items by category
  getItemsByCategory: (category) => api.get(`/toplist/category/${category}`),
  
  // Get items by category ordered by votes
  getItemsByCategoryOrderByVotes: (category) => api.get(`/toplist/category/${category}/by-votes`),
  
  // Get all categories
  getAllCategories: () => api.get('/toplist/categories'),
  
  // Get top voted items
  getTopItemsByVotes: () => api.get('/toplist/top-voted'),
  
  // Create new item
  createItem: (item) => api.post('/toplist', item),
  
  // Update item
  updateItem: (id, item) => api.put(`/toplist/${id}`, item),
  
  // Vote for item
  voteForItem: (id) => api.post(`/toplist/${id}/vote`),
  
  // Delete item
  deleteItem: (id) => api.delete(`/toplist/${id}`),
  
  // Update ranks
  updateRanks: (category, items) => api.put(`/toplist/category/${category}/reorder`, items),
};

export default api;
