package com.coachfit.backend.service;

import com.coachfit.backend.dto.WorkoutRequest;
import com.coachfit.backend.dto.WorkoutResponse;
import com.coachfit.backend.entity.WorkoutRecord;
import com.coachfit.backend.repository.WorkoutRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WorkoutService {

    private final WorkoutRepository workoutRepository;

    /**
     * 서버 기동 시 빠른 테스트를 위한 초기 더미 운동 데이터 생성
     */
    @PostConstruct
    @Transactional
    public void initDummyData() {
        if (workoutRepository.count() == 0) {
            LocalDate today = LocalDate.now();

            workoutRepository.save(WorkoutRecord.builder()
                    .userId("user_01")
                    .exerciseName("벤치프레스")
                    .sets(5)
                    .reps(10)
                    .weight(70.0)
                    .workoutDate(today.minusDays(5))
                    .memo("가슴 자극 집중")
                    .build());

            workoutRepository.save(WorkoutRecord.builder()
                    .userId("user_01")
                    .exerciseName("인클라인 덤벨프레스")
                    .sets(4)
                    .reps(12)
                    .weight(22.0)
                    .workoutDate(today.minusDays(5))
                    .memo("상부 타겟")
                    .build());

            workoutRepository.save(WorkoutRecord.builder()
                    .userId("user_01")
                    .exerciseName("스쿼트")
                    .sets(5)
                    .reps(8)
                    .weight(100.0)
                    .workoutDate(today.minusDays(3))
                    .memo("하체 메인 운동, 자세 안정적")
                    .build());

            workoutRepository.save(WorkoutRecord.builder()
                    .userId("user_01")
                    .exerciseName("레그 익스텐션")
                    .sets(4)
                    .reps(15)
                    .weight(45.0)
                    .workoutDate(today.minusDays(3))
                    .memo("대퇴사두 펌핑")
                    .build());

            workoutRepository.save(WorkoutRecord.builder()
                    .userId("user_01")
                    .exerciseName("바벨 로우")
                    .sets(5)
                    .reps(10)
                    .weight(60.0)
                    .workoutDate(today.minusDays(1))
                    .memo("등 자극 양호")
                    .build());

            log.info("Initialized 5 dummy workout records for quick testing.");
        }
    }

    @Transactional
    public WorkoutResponse saveWorkout(WorkoutRequest request) {
        String userId = (request.getUserId() != null && !request.getUserId().isBlank())
                ? request.getUserId()
                : "user_01";

        WorkoutRecord record = WorkoutRecord.builder()
                .userId(userId)
                .exerciseName(request.getExerciseName())
                .sets(request.getSets())
                .reps(request.getReps())
                .weight(request.getWeight())
                .workoutDate(request.getWorkoutDate() != null ? request.getWorkoutDate() : LocalDate.now())
                .memo(request.getMemo())
                .build();

        WorkoutRecord saved = workoutRepository.save(record);
        return WorkoutResponse.fromEntity(saved);
    }

    public List<WorkoutResponse> getAllWorkouts() {
        return workoutRepository.findAllByOrderByWorkoutDateDescCreatedAtDesc().stream()
                .map(WorkoutResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<WorkoutResponse> getWorkoutsByUser(String userId) {
        return workoutRepository.findByUserIdOrderByWorkoutDateDescCreatedAtDesc(userId).stream()
                .map(WorkoutResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<WorkoutRecord> getRecentRecords(String userId, int limit) {
        return workoutRepository.findTop10ByUserIdOrderByWorkoutDateDescCreatedAtDesc(userId);
    }
}
