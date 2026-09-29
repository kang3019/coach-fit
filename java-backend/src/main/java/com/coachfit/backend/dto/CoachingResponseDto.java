package com.coachfit.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CoachingResponseDto {

    private String summary;

    @JsonProperty("coaching_advice")
    private String coachingAdvice;

    @JsonProperty("recommended_routine")
    private List<RoutineItemDto> recommendedRoutine;

    @JsonProperty("generated_at")
    private String generatedAt;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class RoutineItemDto {
        @JsonProperty("exercise_name")
        private String exerciseName;
        private Integer sets;
        private Integer reps;
        private String focus;
        private String tip;
    }
}
