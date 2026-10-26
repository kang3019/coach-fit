"""
AI(LLM) 호출 비용 보호 장치.

- AiRateLimiter: 사용자별 분당/일일 호출 횟수 + 서버 전체 일일 호출 횟수 제한
- CoachingCache: 같은 날 입력 데이터(목표/프로필/운동 기록)가 그대로면 이전 코칭 결과 재사용

둘 다 프로세스 메모리에 저장하므로 서버 재시작 시 초기화되며, 단일 uvicorn 워커 기준으로 동작합니다.
"""
import hashlib
import os
import threading
import time
from collections import defaultdict, deque
from datetime import date
from typing import Deque, Dict, Optional, Tuple

from app.models.schemas import CoachingRequest, CoachingResponse


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, default))
    except (TypeError, ValueError):
        return default


class AiRateLimiter:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._minute_calls: Dict[str, Deque[float]] = defaultdict(deque)
        self._day = date.today()
        self._daily_calls: Dict[str, int] = defaultdict(int)
        self._global_daily_calls = 0

    def reset(self) -> None:
        with self._lock:
            self._minute_calls.clear()
            self._daily_calls.clear()
            self._global_daily_calls = 0
            self._day = date.today()

    def check(self, user_id: str) -> Optional[str]:
        """호출 허용 시 사용량을 기록하고 None 반환, 한도 초과 시 사용자에게 보여줄 메시지 반환."""
        per_minute = _env_int("AI_RATE_LIMIT_PER_MINUTE", 10)
        per_day = _env_int("AI_RATE_LIMIT_PER_DAY", 100)
        global_per_day = _env_int("AI_GLOBAL_LIMIT_PER_DAY", 300)

        now = time.monotonic()
        with self._lock:
            today = date.today()
            if today != self._day:
                self._day = today
                self._daily_calls.clear()
                self._global_daily_calls = 0

            if self._global_daily_calls >= global_per_day:
                return "오늘 AI 코치 사용량이 서버 한도에 도달했습니다. 내일 다시 이용해 주세요."
            if self._daily_calls[user_id] >= per_day:
                return f"오늘 AI 코치 사용 한도({per_day}회)를 모두 사용했습니다. 내일 다시 이용해 주세요."

            window = self._minute_calls[user_id]
            while window and now - window[0] >= 60:
                window.popleft()
            if len(window) >= per_minute:
                return "AI 코치 요청이 너무 잦습니다. 잠시 후 다시 시도해 주세요."

            window.append(now)
            self._daily_calls[user_id] += 1
            self._global_daily_calls += 1
            return None


class CoachingCache:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._entries: Dict[str, Tuple[str, CoachingResponse]] = {}

    @staticmethod
    def fingerprint(request: CoachingRequest) -> str:
        raw = f"{date.today().isoformat()}|{request.model_dump_json()}"
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    def get(self, user_id: str, fingerprint: str) -> Optional[CoachingResponse]:
        with self._lock:
            entry = self._entries.get(user_id)
        if entry and entry[0] == fingerprint:
            return entry[1]
        return None

    def put(self, user_id: str, fingerprint: str, response: CoachingResponse) -> None:
        with self._lock:
            self._entries[user_id] = (fingerprint, response)

    def clear(self) -> None:
        with self._lock:
            self._entries.clear()


ai_rate_limiter = AiRateLimiter()
coaching_cache = CoachingCache()
