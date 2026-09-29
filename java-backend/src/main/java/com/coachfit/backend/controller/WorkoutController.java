package com.coachfit.backend.controller;

import com.coachfit.backend.dto.WorkoutRequest;
import com.coachfit.backend.dto.WorkoutResponse;
import com.coachfit.backend.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/workouts")
@RequiredArgsConstructor
public class WorkoutController {

    private final WorkoutService workoutService;

    /**
     * 운동 기록 등록 API (임시 로그인 없이 바로 사용 가능)
     * POST /api/workouts
     */
    @PostMapping
    public ResponseEntity<WorkoutResponse> createWorkout(@RequestBody WorkoutRequest request) {
        log.info("Received workout creation request: {}", request.getExerciseName());
        WorkoutResponse response = workoutService.saveWorkout(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 운동 기록 전체 목록 조회 API
     * GET /api/workouts
     */
    @GetMapping
    public ResponseEntity<List<WorkoutResponse>> getAllWorkouts(
            @RequestParam(required = false, defaultValue = "user_01") String userId
    ) {
        log.info("Fetching workouts for user: {}", userId);
        List<WorkoutResponse> workouts = workoutService.getWorkoutsByUser(userId);
        return ResponseEntity.ok(workouts);
    }

    /**
     * 프론트엔드 Chart.js 시각화용 주간 요약 통계 API
     * GET /api/workouts/weekly-stats
     */
    @GetMapping("/weekly-stats")
    public ResponseEntity<Map<String, Object>> getWeeklyStats(
            @RequestParam(required = false, defaultValue = "user_01") String userId
    ) {
        List<WorkoutResponse> list = workoutService.getWorkoutsByUser(userId);

        // 요일별 총 볼륨 (Weight * Sets * Reps) 계산 더미 가공
        Map<String, Double> dayVolumeMap = new HashMap<>();
        for (WorkoutResponse item : list) {
            String day = item.getWorkoutDate().getDayOfWeek().name().substring(0, 3); // MON, TUE, etc.
            double volume = (item.getWeight() != null ? item.getWeight() : 0.0)
                    * (item.getSets() != null ? item.getSets() : 1)
                    * (item.getReps() != null ? item.getReps() : 1);
            dayVolumeMap.put(day, dayVolumeMap.getOrDefault(day, 0.0) + volume);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("userId", userId);
        result.put("totalRecords", list.size());
        result.put("weeklyVolumeByDay", dayVolumeMap);

        return ResponseEntity.ok(result);
    }
}
