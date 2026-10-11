# CD 자동 배포 · Nginx · HTTPS · 고정 IP

`main`에 머지되면 EC2 백엔드가 자동으로 배포되고, 앱은 고정 IP와 HTTPS 도메인으로 접속하도록 만드는 절차입니다.
적용 순서는 **1 → 2 → 3 → 4** 입니다. 각 단계는 독립적으로 확인할 수 있습니다.

> 이 문서의 명령은 EC2(Ubuntu) 기준입니다. 도메인(`api.example.com`)과 시크릿 값은 예시이므로 실제 값으로 바꾸세요.

---

## 1. Elastic IP (고정 IP)

EC2 인스턴스는 중지 후 재시작하면 퍼블릭 IP가 바뀝니다. 앱(`mobile-app/lib/config/api_constants.dart`)과 CD가 IP를 쓰므로 먼저 고정합니다.

1. AWS 콘솔 → EC2 → 네트워크 및 보안 → **탄력적 IP** → **탄력적 IP 주소 할당**
2. 할당된 IP 선택 → **작업 → 탄력적 IP 주소 연결** → 백엔드 인스턴스 선택
3. 새 IP를 아래 위치에 반영합니다.
   - `mobile-app/lib/config/api_constants.dart`의 `_ec2HostOverride` (도메인을 연결하면 4단계에서 도메인으로 교체)
   - GitHub 시크릿 `EC2_HOST` (2단계)
4. 보안 그룹 인바운드: 22(SSH), 80(HTTP), 443(HTTPS)을 허용합니다. 8000 포트는 Nginx 적용 후 외부 공개를 닫아도 됩니다.

주의: 연결되지 않은 Elastic IP는 요금이 부과됩니다. 인스턴스를 없앨 때는 IP도 **릴리스**하세요.

## 2. CD: main 머지 시 자동 배포

기존 `python-ai-backend/scripts/deploy.sh`(git pull → 의존성 설치 → DB 점검 → systemd 재시작)를 GitHub Actions가 SSH로 실행합니다.

### 2-1. GitHub 시크릿 등록

저장소 → Settings → Secrets and variables → Actions → **New repository secret**

| 이름 | 값 |
| --- | --- |
| `EC2_HOST` | Elastic IP 또는 도메인 |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | 배포용 개인키 전체 내용 (`-----BEGIN ... END-----` 포함) |

배포 전용 키를 따로 만드는 것을 권장합니다. 개인 pem 키를 그대로 넣지 마세요.

```bash
# 로컬에서
ssh-keygen -t ed25519 -f coachfit-deploy -C "github-actions-deploy" -N ""
# 공개키를 EC2 에 등록
ssh-copy-id -i coachfit-deploy.pub ubuntu@<EC2_HOST>   # 또는 ~/.ssh/authorized_keys 에 직접 추가
# coachfit-deploy (개인키) 내용을 EC2_SSH_KEY 시크릿에 붙여넣고, 로컬 파일은 삭제
```

### 2-2. 워크플로 파일 추가

연동 토큰에는 `workflows` 권한이 없어 이 PR에 워크플로 파일을 포함하지 못했습니다.
GitHub 웹에서 **Add file → Create new file** 로 `.github/workflows/deploy.yml` 을 만들고 아래 내용을 붙여넣으세요.

```yaml
name: Deploy

on:
  push:
    branches: [main]
    paths:
      - "python-ai-backend/**"
  workflow_dispatch:

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  deploy:
    name: Deploy backend to EC2
    runs-on: ubuntu-latest
    steps:
      - name: Run deploy.sh on EC2
        uses: appleboy/ssh-action@v1.2.0
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script_stop: true
          script: |
            cd /home/ubuntu/coach-fit/python-ai-backend
            bash scripts/deploy.sh

      - name: Health check
        run: |
          for i in 1 2 3 4 5; do
            if curl -fsS "http://${{ secrets.EC2_HOST }}:8000/docs" -o /dev/null; then
              echo "healthy"; exit 0
            fi
            sleep 5
          done
          echo "health check failed"; exit 1
```

- `paths` 필터 덕분에 앱(`mobile-app`)이나 문서만 바뀐 머지는 배포하지 않습니다. 수동 실행은 Actions 탭의 **Run workflow** 입니다.
- 헬스체크는 8000 포트를 직접 칩니다. 5단계에서 8000 포트를 닫았다면 `https://<도메인>/docs` 로 바꾸세요.
- 보안 그룹의 22번 포트가 GitHub 러너 IP 대역에서 열려 있어야 합니다. GitHub 러너 IP는 고정이 아니므로 SSH를 전체 공개(0.0.0.0/0)로 두게 되는 점이 트레이드오프입니다. 키 인증만 허용하고(`PasswordAuthentication no`), 필요하면 self-hosted runner나 AWS SSM 으로 바꾸는 것을 검토하세요.
- `deploy.sh` 가 서버에서 `git pull origin main` 을 하므로, EC2 의 저장소가 `main` 을 pull 할 수 있는 상태여야 합니다.

## 3. Nginx 리버스 프록시

앱이 80/443 으로 접속하고, Nginx 가 내부 FastAPI(8000)로 전달합니다.

```bash
sudo apt update && sudo apt install -y nginx
sudo cp /home/ubuntu/coach-fit/infra/nginx/coachfit.conf /etc/nginx/sites-available/coachfit
sudo sed -i 's/api.example.com/<실제 도메인>/' /etc/nginx/sites-available/coachfit
sudo ln -s /etc/nginx/sites-available/coachfit /etc/nginx/sites-enabled/coachfit
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

확인: `curl -i http://<도메인>/docs` 가 200 을 반환하면 정상입니다.

## 4. HTTPS (Let's Encrypt)

전제: 도메인의 A 레코드가 Elastic IP 를 가리키고, 보안 그룹 80/443 이 열려 있어야 합니다.
도메인이 없으면 이 단계는 건너뛰세요. IP 에는 Let's Encrypt 인증서를 발급할 수 없습니다.

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d <실제 도메인>
sudo certbot renew --dry-run     # 자동 갱신 점검
```

certbot 이 443 블록을 추가하고 HTTP → HTTPS 리다이렉트를 설정합니다. 인증서는 systemd 타이머가 자동 갱신합니다.

### 앱 연결 변경

HTTPS 가 동작하면 `mobile-app/lib/config/api_constants.dart` 의 접속 주소를 `https://<도메인>` 으로 바꿉니다.
Android 는 기본적으로 평문 HTTP 를 막는 경우가 있으므로, HTTPS 전환 후에는 별도 예외 설정이 필요 없습니다.

## 점검 체크리스트

- [ ] Elastic IP 가 인스턴스에 연결되어 있고, 재부팅 후에도 같은 IP
- [ ] `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY` 시크릿 등록
- [ ] `.github/workflows/deploy.yml` 추가 후 Actions 에서 수동 실행(Run workflow) 성공
- [ ] `sudo nginx -t` 통과, `curl http://<도메인>/docs` 200
- [ ] `https://<도메인>/docs` 200, 브라우저 자물쇠 표시
- [ ] `sudo certbot renew --dry-run` 성공
- [ ] 앱에서 로그인·기록 조회가 새 주소로 동작
- [ ] (선택) 8000 포트 외부 공개 차단
