package com.toplist.repository;

import com.toplist.model.TopListItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TopListItemRepository extends JpaRepository<TopListItem, Long> {
    
    List<TopListItem> findByCategoryOrderByRankAsc(String category);
    
    List<TopListItem> findByCategoryOrderByVoteCountDesc(String category);
    
    @Query("SELECT DISTINCT t.category FROM TopListItem t")
    List<String> findAllCategories();
    
    @Query("SELECT t FROM TopListItem t WHERE t.category = :category AND t.rank >= :startRank AND t.rank <= :endRank ORDER BY t.rank ASC")
    List<TopListItem> findByCategoryAndRankBetween(@Param("category") String category, 
                                                   @Param("startRank") Integer startRank, 
                                                   @Param("endRank") Integer endRank);
    
    @Query("SELECT t FROM TopListItem t ORDER BY t.voteCount DESC")
    List<TopListItem> findAllOrderByVoteCountDesc();
}
