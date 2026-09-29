package com.coachfit.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkoutRequest {
    private String userId;
    private String exerciseName;
    private Integer sets;
    private Integer reps;
    private Double weight;
    private LocalDate workoutDate;
    private String memo;
}
