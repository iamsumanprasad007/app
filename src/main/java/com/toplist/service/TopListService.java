package com.toplist.service;

import com.toplist.model.TopListItem;
import com.toplist.repository.TopListItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class TopListService {
    
    @Autowired
    private TopListItemRepository repository;
    
    public List<TopListItem> getAllItems() {
        return repository.findAll();
    }
    
    public Optional<TopListItem> getItemById(Long id) {
        return repository.findById(id);
    }
    
    public List<TopListItem> getItemsByCategory(String category) {
        return repository.findByCategoryOrderByRankAsc(category);
    }
    
    public List<TopListItem> getItemsByCategoryOrderByVotes(String category) {
        return repository.findByCategoryOrderByVoteCountDesc(category);
    }
    
    public List<String> getAllCategories() {
        return repository.findAllCategories();
    }
    
    public List<TopListItem> getTopItemsByVotes() {
        return repository.findAllOrderByVoteCountDesc();
    }
    
    public TopListItem createItem(TopListItem item) {
        return repository.save(item);
    }
    
    public TopListItem updateItem(Long id, TopListItem updatedItem) {
        return repository.findById(id)
                .map(item -> {
                    item.setTitle(updatedItem.getTitle());
                    item.setDescription(updatedItem.getDescription());
                    item.setCategory(updatedItem.getCategory());
                    item.setRank(updatedItem.getRank());
                    item.setImageUrl(updatedItem.getImageUrl());
                    return repository.save(item);
                })
                .orElseThrow(() -> new RuntimeException("Item not found with id: " + id));
    }
    
    public TopListItem voteForItem(Long id) {
        return repository.findById(id)
                .map(item -> {
                    item.setVoteCount(item.getVoteCount() + 1);
                    return repository.save(item);
                })
                .orElseThrow(() -> new RuntimeException("Item not found with id: " + id));
    }
    
    public void deleteItem(Long id) {
        repository.deleteById(id);
    }
    
    public List<TopListItem> updateRanks(String category, List<TopListItem> items) {
        for (int i = 0; i < items.size(); i++) {
            TopListItem item = items.get(i);
            item.setRank(i + 1);
            repository.save(item);
        }
        return getItemsByCategory(category);
    }
}
