package com.coachfit.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "workout_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkoutRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 인증/인가 도입 전 테스트용 기본 사용자 ID
    @Column(nullable = false)
    @Builder.Default
    private String userId = "user_01";

    @Column(nullable = false)
    private String exerciseName;

    @Column(nullable = false)
    private Integer sets;

    @Column(nullable = false)
    private Integer reps;

    @Column(nullable = false)
    private Double weight;

    @Column(nullable = false)
    private LocalDate workoutDate;

    private String memo;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.workoutDate == null) {
            this.workoutDate = LocalDate.now();
        }
        if (this.userId == null) {
            this.userId = "user_01";
        }
    }
}
