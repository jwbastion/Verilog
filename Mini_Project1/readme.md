# 🍽️ 전자레인지 구현 프로젝트 (Microwave Controller)

> FPGA 기반 디지털 회로 설계를 통해 실제 전자레인지 동작을 하드웨어로 구현한 프로젝트입니다.

---

## 📆 프로젝트 기간
- 2025.10 ~ 2025.11 (약 2주간 진행)
- 개인 프로젝트 (Vivado + Basys3 보드 활용)

---

## 🛠️ 사용 기술 스택 및 도구
- **언어**: Verilog HDL
- **플랫폼**: Xilinx Vivado
- **보드**: Digilent Basys3 FPGA Board
- **기능 구성 요소**:
  - FSM (Moore 상태머신)
  - Buzzer 멜로디 출력
  - FND(7-Segment) 시간 표시
  - Rotary Encoder로 시간 조절
  - 버튼 디바운싱 회로
  - LED 상태 표시
  - 클럭 분주 및 타이머

---

## 🎯 주요 기능

| 기능 | 설명 |
|------|------|
| ⏲️ 시간 설정 | Rotary 스위치를 돌려 초 단위로 조절 가능 |
| ▶️ 시작/일시정지 | 버튼으로 조작, FSM 상태에 따라 반응 |
| 🔇 멜로디 출력 | 전원 On / 도어 열림 시 각각 다른 음 출력 |
| 🔔 타이머 알람 | 조리 완료 시 Buzzer를 통해 알림 발생 |
| 🔄 디스플레이 | FND에 잔여 시간 실시간 표시 (sec 단위) |
| 🧼 버튼 디바운싱 | 노이즈 제거로 정확한 입력 보장 |

---

## 📐 시스템 구성도

```
[User Input]
┣━━ Rotary Switch (시간 설정)
┣━━ Buttons (시작 / 리셋 / 도어)
↓
[FSM Controller]
┣━━ 타이머 동작 제어
┣━━ LED / FND / Buzzer 컨트롤
↓
[Output Devices]
┣━━ 7-Segment Display
┣━━ Buzzer
┗━━ LEDs
```

※ FSM 상태: `대기 → 조리 → 일시정지 → 완료`

---

## 📸 회로 시뮬레이션 & 테스트 결과

> Vivado 시뮬레이션 파형 + 실보드 결과 캡처 이미지 포함

- `power_on_melody` 모듈: 초기 부팅 멜로디 재생
- `rotary` 모듈: 시계/반시계 방향 판별
- `debouncer` 모듈: 30~40ns 내 신호 안정화 확인

---

## 🧪 주요 모듈 및 역할

| 모듈명 | 설명 |
|--------|------|
| `power_on_melody` | 전원 On 시 멜로디 재생 (FSM 기반 tone 출력) |
| `open_cover_melody` | 도어 열림 감지 시 알림음 출력 |
| `rotary` | Rotary 인코더 신호 처리 (상태 변화 감지) |
| `button_debounce` | 노이즈 제거 (글리치 대응) |
| `microwave_fsm` | 전체 제어 FSM (상태 전이, 타이머 관리 등) |

---

## 👨‍💻 내 역할 및 기여

- 전체 회로 설계 및 Verilog 코드 작성
- FSM 설계 및 각 상태별 동작 로직 구현
- 멜로디 출력 파형/음계 구현 및 조율
- 타이머/분주기/디스플레이 제어 회로 구현
- 디바운서 직접 구현 및 시뮬레이션 검증
- Vivado 테스트벤치 작성 및 시뮬레이션 수행
- 회로 배치(Pin Mapping), 디버깅, 보드 검증

---

## 💡 문제 해결 경험

- ✅ **버튼 노이즈로 인한 오동작** → 디바운서 타이머 방식으로 해결
- ✅ **버저가 꺼지지 않는 문제** → FSM 상태와 Buzzer OR 조건 정리로 해결
- ✅ **Rotary 신호 간섭 문제** → 이전 상태 저장으로 방향 판별 구현

---

## ✍️ 프로젝트를 하며 느낀 점

- 실제 전자레인지 작동 원리를 디지털 회로로 구현하며 FSM의 중요성을 체감
- 회로 설계부터 디버깅까지 하드웨어 개발 전 과정을 경험
- Verilog로 복잡한 상태 동작을 깔끔하게 표현하는 방법을 익힘
- 메타스테빌리티, 글리치, 팬아웃 등의 개념을 직접 체험하며 이론에 대한 이해도 증진

---

## 📂 폴더 구조 예시
```
📦microwave_project
┣ 📂sim
┃ ┣ testbench_melody.v
┃ ┗ testbench_rotary.v
┣ 📂src
┃ ┣ power_on_melody.v
┃ ┣ open_cover_melody.v
┃ ┣ microwave_fsm.v
┃ ┣ rotary.v
┃ ┗ button_debounce.v
┣ README.md
┗ microwave.xpr
```
---

## 🔗 참고 자료 / 외부 링크
- [Verilog FSM Tutorial](https://www.chipverify.com/verilog/verilog-finite-state-machine)
- [Basys3 Pin Mapping Reference](https://reference.digilentinc.com/basys3/refmanual)
- [Buzzer Tone Table](https://eepurl.com/dHzZm5)
