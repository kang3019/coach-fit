package com.coachfit.backend.controller;

import com.coachfit.backend.dto.CoachingResponseDto;
import com.coachfit.backend.service.AiCoachingClientService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/coaching")
@RequiredArgsConstructor
public class CoachingController {

    private final AiCoachingClientService aiCoachingClientService;

    /**
     * 프론트엔드 -> Java 서버 -> Python AI 서버 코칭 요청 중계 API
     * POST /api/coaching/generate
     */
    @PostMapping("/generate")
    public ResponseEntity<CoachingResponseDto> generateCoaching(
            @RequestBody(required = false) Map<String, String> requestBody
    ) {
        String userId = (requestBody != null && requestBody.containsKey("userId"))
                ? requestBody.get("userId") : "user_01";
        String goal = (requestBody != null && requestBody.containsKey("goal"))
                ? requestBody.get("goal") : "상체 근력 향상 및 체지방 감량";

        log.info("Requesting AI coaching for user: {}, goal: {}", userId, goal);
        CoachingResponseDto response = aiCoachingClientService.requestCoaching(userId, goal);
        return ResponseEntity.ok(response);
    }
}
