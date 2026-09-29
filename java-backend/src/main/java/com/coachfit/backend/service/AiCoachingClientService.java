package com.coachfit.backend.service;

import com.coachfit.backend.dto.CoachingRequestDto;
import com.coachfit.backend.dto.CoachingResponseDto;
import com.coachfit.backend.entity.WorkoutRecord;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiCoachingClientService {

    private final RestTemplate restTemplate;
    private final WorkoutService workoutService;

    @Value("${ai-service.url:http://localhost:8000}")
    private String aiServiceUrl;

    /**
     * 사용자의 최근 운동 기록을 조회하여 Python FastAPI AI 서버로 코칭 요청을 전달
     */
    public CoachingResponseDto requestCoaching(String userId, String goal) {
        String effectiveUserId = (userId != null && !userId.isBlank()) ? userId : "user_01";
        String effectiveGoal = (goal != null && !goal.isBlank()) ? goal : "근비대 및 체력 증진";

        List<WorkoutRecord> recentRecords = workoutService.getRecentRecords(effectiveUserId, 10);

        List<CoachingRequestDto.WorkoutItemDto> workoutItems = recentRecords.stream()
                .map(r -> CoachingRequestDto.WorkoutItemDto.builder()
                        .exerciseName(r.getExerciseName())
                        .sets(r.getSets())
                        .reps(r.getReps())
                        .weight(r.getWeight())
                        .date(r.getWorkoutDate())
                        .build())
                .collect(Collectors.toList());

        CoachingRequestDto requestPayload = CoachingRequestDto.builder()
                .userId(effectiveUserId)
                .userGoal(effectiveGoal)
                .recentWorkouts(workoutItems)
                .build();

        String targetUrl = aiServiceUrl + "/api/coaching";
        log.info("Sending coaching request to Python AI Server: {}", targetUrl);

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<CoachingRequestDto> entity = new HttpEntity<>(requestPayload, headers);

            ResponseEntity<CoachingResponseDto> response = restTemplate.postForEntity(
                    targetUrl,
                    entity,
                    CoachingResponseDto.class
            );

            return response.getBody();
        } catch (Exception e) {
            log.error("Failed to connect to Python AI Server ({}): {}", targetUrl, e.getMessage());
            // Fallback 응답 제공 (Python 서버가 꺼져 있어도 화면 테스트가 가능하도록)
            return CoachingResponseDto.builder()
                    .summary("Python AI 서버 미연동 (Fallback 모드 작동 중)")
                    .coachingAdvice("현재 FastAPI 서버(http://localhost:8000)와의 통신이 원활하지 않습니다. Python 서버를 실행했는지 확인해주세요. 최근 " + recentRecords.size() + "개의 기록을 기반으로 기본 루틴을 유지하는 것을 권장합니다.")
                    .recommendedRoutine(List.of(
                            CoachingResponseDto.RoutineItemDto.builder()
                                    .exerciseName("체스트 프레스 (머신)")
                                    .sets(4)
                                    .reps(12)
                                    .focus("가슴 자극 및 안정적인 고립")
                                    .tip("견갑골을 고정하고 가슴을 열어 수축에 집중하세요.")
                                    .build(),
                            CoachingResponseDto.RoutineItemDto.builder()
                                    .exerciseName("랫 풀 다운")
                                    .sets(4)
                                    .reps(10)
                                    .focus("광배근 타겟")
                                    .tip("팔이 아닌 팔꿈치를 옆구리로 당긴다는 느낌으로 진행하세요.")
                                    .build()
                    ))
                    .generatedAt(LocalDateTime.now().toString())
                    .build();
        }
    }
}
