package com.coachfit.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CoachingRequestDto {

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("user_goal")
    private String userGoal;

    @JsonProperty("recent_workouts")
    private List<WorkoutItemDto> recentWorkouts;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WorkoutItemDto {
        @JsonProperty("exercise_name")
        private String exerciseName;
        private Integer sets;
        private Integer reps;
        private Double weight;
        private LocalDate date;
    }
}
