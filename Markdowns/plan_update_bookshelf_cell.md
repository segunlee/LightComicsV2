# Plan: BookShelfCell 기간 표시 — 분 단위 계산으로 개선

> 작성일: 2026-03-05
> 대상 파일: `Projects/Feature/BookShelfFeature/Sources/Scene/Components/BookShelfCell.swift`

---

## 1. 현재 코드 분석

### 문제 위치

`BookShelfCell.swift` **line 56–62**, `durationText` computed property:

```swift
// BookShelfCell.swift:56-62 (현재 코드)
private var durationText: String {
  guard let endDate = readInfo.readDate else { return "읽는 중" }
  let days = Calendar.current.dateComponents([.day], from: readInfo.createDate, to: endDate).day ?? 0
  if days == 0 { return "당일" }
  if days < 30 { return "\(days)일" }
  return "\(days / 30)개월"
}
```

### 현재 로직 흐름

```
readDate == nil  → "읽는 중"
days == 0        → "당일"   ← 같은 날이면 무조건 "당일" (시간/분 무시)
days < 30        → "N일"
days >= 30       → "N개월"
```

### 데이터 모델 확인

```
// BookDomainInterface.swift:62-63
public var readDate: Date?     // 마지막으로 읽은 시각
public var createDate: Date    // 최초 생성(첫 읽기 시작) 시각
```

`readDate`는 마지막으로 읽은 시각이므로 "얼마 전에 읽었는지" (readDate → 현재) 를 표시하는 것이 의미상 올바르다.

---

## 2. 문제점

| 상황 | 현재 출력 | 기대 출력 |
|---|---|---|
| 59초 전에 읽음 | "당일" | "1분 전에 읽음" |
| 30분 전에 읽음 | "당일" | "30분 전에 읽음" |
| 1시간 5분 전에 읽음 | "당일" | "1시간 5분 전에 읽음" |
| 23시간 전에 읽음 | "당일" | "23시간 전에 읽음" |
| 3일 전에 읽음 | "3일" | "3일 전에 읽음" |
| 2개월 전에 읽음 | "2개월" | "2개월 전에 읽음" |

문제 1: `[.day]` 단위만 사용해 하루 미만은 모두 `"당일"` 로 뭉개짐.
문제 2: `createDate → readDate` 차이(독서 소요 시간)를 계산했으나, `readDate`는 마지막 읽은 시각이므로 `readDate → now` 경과 시간을 표시해야 의미가 맞음.

---

## 3. 변경 범위

**변경 파일 1개**, **변경 라인 7줄 → 13줄**:

| 파일 | 변경 내용 |
|---|---|
| `BookShelfCell.swift` (line 56–68) | `durationText` 로직 교체 |

도메인 모델(`ReadInfo`), UseCase, ViewModel, ViewController — **변경 없음**.

---

## 4. 새 로직 설계

### 계산 방식

기준점을 `createDate → readDate` 에서 `readDate → Date.now` 로 변경. `timeIntervalSince(_:)` 로 경과 초를 구한 뒤 분으로 환산.

```
totalSeconds = Date.now.timeIntervalSince(readDate)
totalMinutes = max(1, Int(totalSeconds / 60))   ← 최솟값 1분 보장
```

### 표시 계층

모든 완독 항목에 `"전에 읽음"` 접미사 적용. 시간대는 시간+분 복합 표시.

```
60초 미만           → "1분 전에 읽음"              (max(1,...) 로 올림, 최솟값 1분)
totalMinutes < 60   → "N분 전에 읽음"
totalMinutes < 1440 → "Nh Mm 전에 읽음"            (나머지 분이 0이면 "Nh 전에 읽음")
totalMinutes < 43200→ "N일 전에 읽음"
else                → "N개월 전에 읽음"
```

| 입력 | 출력 |
|---|---|
| 59초 전 | "1분 전에 읽음" |
| 30분 전 | "30분 전에 읽음" |
| 60분 전 | "1시간 전에 읽음" |
| 65분 전 | "1시간 5분 전에 읽음" |

### 새 코드 스니펫

```swift
// BookShelfCell.swift:56-68 (변경 후)
private var durationText: String {
  guard let readDate = readInfo.readDate else { return "읽는 중" }
  let totalMinutes = max(1, Int(Date.now.timeIntervalSince(readDate) / 60))
  if totalMinutes < 60 {
    return "\(totalMinutes)분 전에 읽음"
  }
  let hours = totalMinutes / 60
  let remainingMinutes = totalMinutes % 60
  if hours < 24 {
    return remainingMinutes == 0
      ? "\(hours)시간 전에 읽음"
      : "\(hours)시간 \(remainingMinutes)분 전에 읽음"
  }
  let days = totalMinutes / 1440
  if days < 30 { return "\(days)일 전에 읽음" }
  return "\(days / 30)개월 전에 읽음"
}
```

### Before / After 비교

```swift
// BEFORE
private var durationText: String {
  guard let endDate = readInfo.readDate else { return "읽는 중" }
  let days = Calendar.current.dateComponents([.day], from: readInfo.createDate, to: endDate).day ?? 0
  if days == 0 { return "당일" }
  if days < 30 { return "\(days)일" }
  return "\(days / 30)개월"
}

// AFTER
private var durationText: String {
  guard let readDate = readInfo.readDate else { return "읽는 중" }
  let totalMinutes = max(1, Int(Date.now.timeIntervalSince(readDate) / 60))
  if totalMinutes < 60 {
    return "\(totalMinutes)분 전에 읽음"
  }
  let hours = totalMinutes / 60
  let remainingMinutes = totalMinutes % 60
  if hours < 24 {
    return remainingMinutes == 0
      ? "\(hours)시간 전에 읽음"
      : "\(hours)시간 \(remainingMinutes)분 전에 읽음"
  }
  let days = totalMinutes / 1440
  if days < 30 { return "\(days)일 전에 읽음" }
  return "\(days / 30)개월 전에 읽음"
}
```

---

## 5. 경계값 검증 표

| 마지막 읽은 시점 | 원시 totalMinutes | max(1,...) 적용 후 | 표시 |
|---|---|---|---|
| 59초 전 | 0 | 1 | "1분 전에 읽음" |
| 1분 전 | 1 | 1 | "1분 전에 읽음" |
| 30분 전 | 30 | 30 | "30분 전에 읽음" |
| 59분 전 | 59 | 59 | "59분 전에 읽음" |
| 1시간 전 (60분) | 60 | 60 | "1시간 전에 읽음" |
| 1시간 5분 전 (65분) | 65 | 65 | "1시간 5분 전에 읽음" |
| 23시간 59분 전 | 1439 | 1439 | "23시간 59분 전에 읽음" |
| 24시간 전 (1440분) | 1440 | 1440 | "1일 전에 읽음" |
| 29일 전 | 41760 | 41760 | "29일 전에 읽음" |
| 30일 전 (43200분) | 43200 | 43200 | "1개월 전에 읽음" |
| 60일 전 | 86400 | 86400 | "2개월 전에 읽음" |

---

## 6. 삭제되는 것

| 제거 | 이유 |
|---|---|
| `Calendar.current.dateComponents(...)` 호출 | `timeIntervalSince` 로 대체, Calendar 의존 불필요 |
| `createDate` 참조 | 기준점이 `readDate → now` 로 바뀌어 불필요 |
| `"당일"` 문자열 | `"N분 전에 읽음"` / `"N시간 M분 전에 읽음"` 으로 세분화 |

---

## 7. TODO List

### 구현

- [x] `BookShelfCell.swift` line 56–68 의 `durationText` 로직 교체
  - [x] `Calendar.current.dateComponents([.day], ...)` 제거
  - [x] 기준점 `createDate → readDate` → `readDate → Date.now` 로 변경
  - [x] `"당일"` 제거, 최솟값 `"1분 전에 읽음"` 으로 통일
  - [x] 분 단독 케이스 (`< 60`) → `"N분 전에 읽음"`
  - [x] 시간 케이스 (`< 1440`) → `remainingMinutes % 60` 분기로 `"Nh 전에 읽음"` / `"Nh Mm 전에 읽음"` 구분
  - [x] 일/개월 케이스 모두 `"전에 읽음"` 접미사 적용

### 검증

- [x] `readDate == nil` 일 때 "읽는 중" 반환 확인 (기존 동작 유지)
- [x] 59초 경과 → "1분 전에 읽음" 확인 (`max(1,...)` 클램핑)
- [x] 1분 경과 → "1분 전에 읽음" 확인
- [x] 30분 경과 → "30분 전에 읽음" 확인
- [x] 59분 경과 → "59분 전에 읽음" 확인
- [x] 60분 경과 → "1시간 전에 읽음" 확인 (나머지 분 0)
- [x] 65분 경과 → "1시간 5분 전에 읽음" 확인 (나머지 분 5)
- [x] 1439분 (23시간 59분) → "23시간 59분 전에 읽음" 확인
- [x] 1440분 (24시간) → "1일 전에 읽음" 확인
- [x] 41760분 (29일) → "29일 전에 읽음" 확인
- [x] 43200분 (30일) → "1개월 전에 읽음" 확인
- [x] 86400분 (60일) → "2개월 전에 읽음" 확인
- [x] SwiftLint 경고 없음 확인 (`cd Scripts && swiftlint`)
- [x] 빌드 성공 확인 (`LightComics-DEV` scheme)

---

## 8. 영향 범위

```
BookShelfCell.swift         ← 유일한 변경 대상
  └── durationText (line 56)

변경 없음:
  ReadInfo (BookDomainInterface.swift) — readDate 그대로 사용
  BookShelfViewModel.swift             — 상태 변경 없음
  BookShelfUseCase.swift               — 도메인 호출 변경 없음
  BookShelfViewController.swift        — 바인딩 변경 없음
```

---

## 9. 주의사항

- `readDate`가 미래 시각인 비정상 데이터의 경우 `totalMinutes`가 음수가 될 수 있다.
  `max(1, ...)` 클램핑으로 최솟값 1분이 보장되어 음수 표시는 방지된다.

- `Calendar` import 는 `Foundation` 에 포함되어 있으므로 `timeIntervalSince` 사용 시 추가 import 없음.

- 화면이 열려 있는 동안 시간이 흐르면 표시값이 stale해질 수 있으나, BookShelfViewController는
  `viewWillAppear` 시 `.refresh` 액션을 전송하므로 화면 재진입 시 자동 갱신된다.
