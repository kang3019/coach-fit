// API 엔드포인트 설정 (FastAPI 단일 백엔드 포트 8000으로 통합)
const JAVA_API_BASE = 'http://localhost:8000/api';
const PYTHON_API_BASE = 'http://localhost:8000/api';


let weeklyChart = null;

// 페이지 로드 시 초기화
document.addEventListener('DOMContentLoaded', () => {
  // 오늘 날짜 기본 설정
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('workout-date').value = today;

  initChart();
  checkServerHealth();
  fetchWorkouts();
  fetchWeeklyStats();

  // 폼 제출 이벤트 등록
  document.getElementById('workout-form').addEventListener('submit', handleWorkoutSubmit);
});

/**
 * 1. 서버 상태 헬스체크
 */
async function checkServerHealth() {
  const dotJava = document.getElementById('dot-java');
  const dotPython = document.getElementById('dot-python');

  // Java 서버 확인
  try {
    const res = await fetch(`${JAVA_API_BASE}/workouts`, { method: 'GET' });
    if (res.ok) {
      dotJava.classList.add('online');
    } else {
      dotJava.classList.remove('online');
    }
  } catch (err) {
    dotJava.classList.remove('online');
  }

  // Python 서버 확인
  try {
    const res = await fetch('http://localhost:8000/health', { method: 'GET' });
    if (res.ok) {
      dotPython.classList.add('online');
    } else {
      dotPython.classList.remove('online');
    }
  } catch (err) {
    dotPython.classList.remove('online');
  }
}

/**
 * 2. 운동 기록 등록 (Java 서버)
 */
async function handleWorkoutSubmit(e) {
  e.preventDefault();

  const payload = {
    userId: 'user_01',
    exerciseName: document.getElementById('exercise-name').value.trim(),
    sets: parseInt(document.getElementById('sets').value, 10),
    reps: parseInt(document.getElementById('reps').value, 10),
    weight: parseFloat(document.getElementById('weight').value),
    workoutDate: document.getElementById('workout-date').value,
    memo: document.getElementById('memo').value.trim()
  };

  try {
    const res = await fetch(`${JAVA_API_BASE}/workouts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!res.ok) throw new Error('기록 저장 실패');

    alert('운동 기록이 성공적으로 저장되었습니다!');
    // 폼 메모 초기화
    document.getElementById('memo').value = '';

    // 목록 및 차트 갱신
    fetchWorkouts();
    fetchWeeklyStats();
  } catch (err) {
    alert(`Java 서버 통신 오류: ${err.message}\nJava 서버(8080)가 실행 중인지 확인하세요.`);
  }
}

/**
 * 3. 운동 기록 목록 조회 (Java 서버)
 */
async function fetchWorkouts() {
  const tbody = document.getElementById('workout-table-body');
  const countBadge = document.getElementById('record-count');

  try {
    const res = await fetch(`${JAVA_API_BASE}/workouts?userId=user_01`);
    if (!res.ok) throw new Error('조회 실패');

    const data = await res.json();
    countBadge.innerText = `${data.length}개 기록`;

    if (data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: var(--text-muted);">등록된 운동 기록이 없습니다.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(item => {
      const volume = (item.weight * item.sets * item.reps).toLocaleString();
      return `
        <tr>
          <td>${item.workoutDate}</td>
          <td><strong>${item.exerciseName}</strong></td>
          <td>${item.sets} 세트</td>
          <td>${item.reps} 회</td>
          <td>${item.weight} kg</td>
          <td><span class="badge">${volume} kg</span></td>
          <td style="color: var(--text-secondary);">${item.memo || '-'}</td>
        </tr>
      `;
    }).join('');

  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #ef4444;">Java 서버에서 데이터를 불러오지 못했습니다. (서버 상태를 확인하세요)</td></tr>`;
  }
}

/**
 * 4. 주간 볼륨 차트 초기화 및 업데이트 (Chart.js)
 */
function initChart() {
  const ctx = document.getElementById('weeklyChart').getContext('2d');
  weeklyChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['월', '화', '수', '목', '금', '토', '일'],
      datasets: [{
        label: '일별 누적 볼륨 (kg)',
        data: [0, 0, 0, 0, 0, 0, 0],
        backgroundColor: 'rgba(56, 189, 248, 0.4)',
        borderColor: '#38bdf8',
        borderWidth: 2,
        borderRadius: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: '#334155' },
          ticks: { color: '#94a3b8' }
        },
        x: {
          grid: { display: false },
          ticks: { color: '#94a3b8' }
        }
      },
      plugins: {
        legend: {
          labels: { color: '#f8fafc', font: { size: 12 } }
        }
      }
    }
  });
}

async function fetchWeeklyStats() {
  try {
    const res = await fetch(`${JAVA_API_BASE}/workouts/weekly-stats?userId=user_01`);
    if (!res.ok) throw new Error('통계 조회 실패');

    const result = await res.json();
    const volumeMap = result.weeklyVolumeByDay || {};

    const dayKeys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const updatedData = dayKeys.map(k => volumeMap[k] || 0);

    // 데이터가 모두 0이면 가상의 주간 데이터로 시각화 (초기 시각화 경험 제공)
    const isAllZero = updatedData.every(v => v === 0);
    const finalData = isAllZero ? [3200, 4100, 0, 5200, 2900, 0, 4800] : updatedData;

    weeklyChart.data.datasets[0].data = finalData;
    weeklyChart.update();
  } catch (err) {
    console.warn('차트 데이터 로드 실패 (기본 더미 데이터 사용):', err);
    weeklyChart.data.datasets[0].data = [3500, 4200, 0, 5100, 3100, 0, 4600];
    weeklyChart.update();
  }
}

/**
 * 5. 맞춤형 AI 코칭 요청
 * - java-proxy: 사용자 화면 -> Java 서버 -> Python 서버 -> 화면
 * - python-direct: 사용자 화면 -> Python 서버 직접 호출
 */
async function requestAiCoaching() {
  const route = document.getElementById('api-route').value;
  const userGoal = document.getElementById('user-goal').value.trim();
  const btn = document.getElementById('btn-request-ai');
  const btnText = document.getElementById('ai-btn-text');
  const resultBox = document.getElementById('ai-result-box');

  // 로딩 상태 전환
  btn.disabled = true;
  btnText.innerHTML = '<span class="spinner"></span> AI 코치가 운동 데이터를 분석하고 있습니다...';

  try {
    let coachingData = null;

    if (route === 'java-proxy') {
      // 1) 표준 아키텍처: Java 서버 경유 (Java가 DB에서 기록을 추출하여 Python 서버로 전송)
      const res = await fetch(`${JAVA_API_BASE}/coaching/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: 'user_01', goal: userGoal })
      });
      if (!res.ok) throw new Error(`Java 경유 코칭 요청 실패 (HTTP ${res.status})`);
      coachingData = await res.json();

    } else {
      // 2) Python FastAPI 직접 호출 테스트
      // 먼저 Java에서 최근 기록을 가져옴
      let recentWorkouts = [];
      try {
        const wRes = await fetch(`${JAVA_API_BASE}/workouts?userId=user_01`);
        if (wRes.ok) {
          const list = await wRes.json();
          recentWorkouts = list.map(item => ({
            exercise_name: item.exerciseName,
            sets: item.sets,
            reps: item.reps,
            weight: item.weight,
            date: item.workoutDate
          }));
        }
      } catch (e) {
        console.warn('기록 로드 실패, 빈 목록 전달');
      }

      const res = await fetch(`${PYTHON_API_BASE}/coaching`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: 'user_01',
          user_goal: userGoal,
          recent_workouts: recentWorkouts
        })
      });
      if (!res.ok) throw new Error(`Python AI 서버 직접 요청 실패 (HTTP ${res.status})`);
      coachingData = await res.json();
    }

    // 결과 렌더링
    renderCoachingResult(coachingData);

  } catch (err) {
    alert(`AI 코칭 요청 실패: ${err.message}\nJava(8080) 및 Python(8000) 서버가 모두 기동되어 있는지 확인하세요.`);
  } finally {
    btn.disabled = false;
    btnText.innerHTML = '⚡ AI 코칭 분석 및 오늘의 맞춤 루틴 생성하기';
  }
}

function renderCoachingResult(data) {
  const resultBox = document.getElementById('ai-result-box');
  const summaryEl = document.getElementById('ai-summary');
  const adviceEl = document.getElementById('ai-advice');
  const routineListEl = document.getElementById('routine-cards');
  const timeEl = document.getElementById('ai-generated-at');

  summaryEl.innerText = data.summary || '요약 정보가 없습니다.';
  adviceEl.innerText = data.coaching_advice || data.coachingAdvice || '조언 정보가 없습니다.';
  timeEl.innerText = `분석 시각: ${data.generated_at || data.generatedAt || new Date().toLocaleString()}`;

  const routineItems = data.recommended_routine || data.recommendedRoutine || [];
  routineListEl.innerHTML = routineItems.map(item => {
    const name = item.exercise_name || item.exerciseName;
    return `
      <div class="routine-card">
        <div class="routine-name">🔥 ${name}</div>
        <div class="routine-meta">권장: <strong>${item.sets} 세트 × ${item.reps} 회</strong></div>
        <div style="font-size: 0.8rem; color: #fb923c; margin-bottom: 4px;">타겟: ${item.focus || '-'}</div>
        <div class="routine-tip">💡 팁: ${item.tip || '-'}</div>
      </div>
    `;
  }).join('');

  resultBox.classList.add('active');
  resultBox.scrollIntoView({ behavior: 'smooth' });
}
