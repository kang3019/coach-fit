package com.coachfit.backend.dto;

import com.coachfit.backend.entity.WorkoutRecord;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkoutResponse {
    private Long id;
    private String userId;
    private String exerciseName;
    private Integer sets;
    private Integer reps;
    private Double weight;
    private LocalDate workoutDate;
    private String memo;
    private LocalDateTime createdAt;

    public static WorkoutResponse fromEntity(WorkoutRecord entity) {
        return WorkoutResponse.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .exerciseName(entity.getExerciseName())
                .sets(entity.getSets())
                .reps(entity.getReps())
                .weight(entity.getWeight())
                .workoutDate(entity.getWorkoutDate())
                .memo(entity.getMemo())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
