package com.toplist.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.toplist.model.TopListItem;
import com.toplist.service.TopListService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TopListController.class)
public class TopListControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TopListService topListService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetAllItems() throws Exception {
        TopListItem item1 = new TopListItem("Test Movie", "Description", "Movies", 1);
        TopListItem item2 = new TopListItem("Test Book", "Description", "Books", 1);
        
        when(topListService.getAllItems()).thenReturn(Arrays.asList(item1, item2));

        mockMvc.perform(get("/api/toplist"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].title").value("Test Movie"))
                .andExpect(jsonPath("$[1].title").value("Test Book"));
    }

    @Test
    public void testGetItemById() throws Exception {
        TopListItem item = new TopListItem("Test Movie", "Description", "Movies", 1);
        item.setId(1L);
        
        when(topListService.getItemById(1L)).thenReturn(Optional.of(item));

        mockMvc.perform(get("/api/toplist/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Test Movie"))
                .andExpect(jsonPath("$.category").value("Movies"));
    }

    @Test
    public void testCreateItem() throws Exception {
        TopListItem item = new TopListItem("New Movie", "Description", "Movies", 1);
        item.setId(1L);
        
        when(topListService.createItem(any(TopListItem.class))).thenReturn(item);

        mockMvc.perform(post("/api/toplist")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(item)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title").value("New Movie"));
    }

    @Test
    public void testVoteForItem() throws Exception {
        TopListItem item = new TopListItem("Test Movie", "Description", "Movies", 1);
        item.setId(1L);
        item.setVoteCount(5);
        
        when(topListService.voteForItem(1L)).thenReturn(item);

        mockMvc.perform(post("/api/toplist/1/vote"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.voteCount").value(5));
    }

    @Test
    public void testGetItemsByCategory() throws Exception {
        TopListItem item1 = new TopListItem("Movie 1", "Description", "Movies", 1);
        TopListItem item2 = new TopListItem("Movie 2", "Description", "Movies", 2);
        
        when(topListService.getItemsByCategory("Movies")).thenReturn(Arrays.asList(item1, item2));

        mockMvc.perform(get("/api/toplist/category/Movies"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].category").value("Movies"))
                .andExpect(jsonPath("$[1].category").value("Movies"));
    }
}
