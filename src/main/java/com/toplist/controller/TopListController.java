package com.toplist.controller;

import com.toplist.model.TopListItem;
import com.toplist.service.TopListService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/toplist")
@CrossOrigin(origins = "*")
public class TopListController {
    
    @Autowired
    private TopListService topListService;
    
    @GetMapping
    public ResponseEntity<List<TopListItem>> getAllItems() {
        List<TopListItem> items = topListService.getAllItems();
        return ResponseEntity.ok(items);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<TopListItem> getItemById(@PathVariable Long id) {
        return topListService.getItemById(id)
                .map(item -> ResponseEntity.ok(item))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/category/{category}")
    public ResponseEntity<List<TopListItem>> getItemsByCategory(@PathVariable String category) {
        List<TopListItem> items = topListService.getItemsByCategory(category);
        return ResponseEntity.ok(items);
    }
    
    @GetMapping("/category/{category}/by-votes")
    public ResponseEntity<List<TopListItem>> getItemsByCategoryOrderByVotes(@PathVariable String category) {
        List<TopListItem> items = topListService.getItemsByCategoryOrderByVotes(category);
        return ResponseEntity.ok(items);
    }
    
    @GetMapping("/categories")
    public ResponseEntity<List<String>> getAllCategories() {
        List<String> categories = topListService.getAllCategories();
        return ResponseEntity.ok(categories);
    }
    
    @GetMapping("/top-voted")
    public ResponseEntity<List<TopListItem>> getTopItemsByVotes() {
        List<TopListItem> items = topListService.getTopItemsByVotes();
        return ResponseEntity.ok(items);
    }
    
    @PostMapping
    public ResponseEntity<TopListItem> createItem(@Valid @RequestBody TopListItem item) {
        TopListItem createdItem = topListService.createItem(item);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdItem);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<TopListItem> updateItem(@PathVariable Long id, @Valid @RequestBody TopListItem item) {
        try {
            TopListItem updatedItem = topListService.updateItem(id, item);
            return ResponseEntity.ok(updatedItem);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @PostMapping("/{id}/vote")
    public ResponseEntity<TopListItem> voteForItem(@PathVariable Long id) {
        try {
            TopListItem votedItem = topListService.voteForItem(id);
            return ResponseEntity.ok(votedItem);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteItem(@PathVariable Long id) {
        topListService.deleteItem(id);
        return ResponseEntity.noContent().build();
    }
    
    @PutMapping("/category/{category}/reorder")
    public ResponseEntity<List<TopListItem>> updateRanks(@PathVariable String category, @RequestBody List<TopListItem> items) {
        List<TopListItem> updatedItems = topListService.updateRanks(category, items);
        return ResponseEntity.ok(updatedItems);
    }
}
