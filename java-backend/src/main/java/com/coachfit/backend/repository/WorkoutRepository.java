package com.coachfit.backend.repository;

import com.coachfit.backend.entity.WorkoutRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkoutRepository extends JpaRepository<WorkoutRecord, Long> {

    List<WorkoutRecord> findAllByOrderByWorkoutDateDescCreatedAtDesc();

    List<WorkoutRecord> findByUserIdOrderByWorkoutDateDescCreatedAtDesc(String userId);

    List<WorkoutRecord> findTop10ByUserIdOrderByWorkoutDateDescCreatedAtDesc(String userId);
}
