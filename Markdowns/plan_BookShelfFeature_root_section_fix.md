# plan_BookShelfFeature_root_section_fix.md

## 문제

`BookShelfViewModel.buildState()`에서 폴더 섹션을 구성할 때:

```swift
guard parent != documentsPath, parent.hasPrefix(documentsPath + "/") else { continue }
```

`parent == documentsPath`인 경우를 **명시적으로 skip** 함. 이 조건에 해당하는 케이스가 두 가지:

1. **루트 레벨 파일** (예: `/Documents/book.cbz`) → `parent == documentsPath` → skip
2. **루트 레벨 디렉토리 책** (예: `/Documents/ComicFolder/`) → `path` 자체가 디렉토리이고 `parent == documentsPath` → skip

`nowReading`/`read` 섹션은 읽기 상태 기준이므로, 두 케이스 모두 한 번도 열지 않은 경우 어느 섹션에도 표시되지 않음.

---

## 변경 대상

| 파일 | 변경 내용 |
|------|------|
| `Sources/Scene/BookShelf/BookShelfViewState.swift` | `BookShelfSectionType`에 `.root` case 추가 |
| `Sources/Scene/BookShelf/BookShelfViewModel.swift` | `buildState`에서 루트 파일은 `.root` 섹션, 루트 디렉토리 책은 각자 `.folder` 섹션으로 수집 |

---

## 접근 방식

두 케이스를 분리 처리:

- **루트 레벨 파일** → `BookShelfSectionType.root` 신규 케이스 (title: "전체")
- **루트 레벨 디렉토리 책** → 기존 `subfolderGroups`에 해당 path를 key로 그대로 추가
  - 이미 존재하는 folder section 생성 루프가 `(folderPath as NSString).lastPathComponent`로 이름을 만들기 때문에 추가 코드 없이 동작

판별 방법: `parent == documentsPath`일 때 `FileManager.fileExists(atPath: path, isDirectory:)`로 디렉토리 여부 확인.

**1뎁스 노출 제한:**
루트 레벨 디렉토리의 하위 디렉토리(예: `/Documents/FolderA/SubB`)는 독립 섹션이 되어서는 안 됨.
- 해당 아이템의 `parent = /Documents/FolderA` → `parent.hasPrefix(documentsPath + "/")` 브랜치 진입
- `firstComponent = FolderA` → `subfolderGroups["/Documents/FolderA"]`에 포함
- 기존 로직이 이미 1뎁스를 보장하므로 추가 코드 불필요

---

## Before / After

### `BookShelfViewState.swift`

**Before:**
```swift
enum BookShelfSectionType: Hashable {
  case nowReading
  case read
  case folder(path: String, name: String)

  var title: String {
    switch self {
    case .nowReading: return "읽는 중"
    case .read: return "다 읽음"
    case let .folder(_, name): return name
    }
  }
}
```

**After:**
```swift
enum BookShelfSectionType: Hashable {
  case nowReading
  case read
  case root
  case folder(path: String, name: String)

  var title: String {
    switch self {
    case .nowReading: return "읽는 중"
    case .read: return "다 읽음"
    case .root: return "Documents"
    case let .folder(_, name): return name
    }
  }
}
```

---

### `BookShelfViewModel.swift` — `buildState` 메서드

**Before:**
```swift
var subfolderGroups: [String: [ReadInfo]] = [:]
for readInfo in all {
  guard let path = readInfo.pathString else { continue }
  let parent = (path as NSString).deletingLastPathComponent
  guard parent != documentsPath, parent.hasPrefix(documentsPath + "/") else { continue }
  let relative = String(parent.dropFirst(documentsPath.count + 1))
  let firstComponent = relative.split(separator: "/").first.map(String.init) ?? relative
  let subfolderPath = documentsPath + "/" + firstComponent
  subfolderGroups[subfolderPath, default: []].append(readInfo)
}

let sortedFolders = subfolderGroups.keys
  .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

for folderPath in sortedFolders {
  let folderName = (folderPath as NSString).lastPathComponent
  let section = BookShelfSectionType.folder(path: folderPath, name: folderName)
  let items = subfolderGroups[folderPath] ?? []
  sections.append(section)
  itemsBySection[section] = items
  items.forEach { allItems[$0.id] = $0 }
}
```

**After:**
```swift
var rootItems: [ReadInfo] = []
var subfolderGroups: [String: [ReadInfo]] = [:]
for readInfo in all {
  guard let path = readInfo.pathString else { continue }
  let parent = (path as NSString).deletingLastPathComponent
  if parent == documentsPath {
    // 루트 레벨 디렉토리 책: path 자체를 folder key로 사용
    // 루트 레벨 파일: rootItems에 추가
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
      subfolderGroups[path, default: []].append(readInfo)
    } else {
      rootItems.append(readInfo)
    }
  } else if parent.hasPrefix(documentsPath + "/") {
    let relative = String(parent.dropFirst(documentsPath.count + 1))
    let firstComponent = relative.split(separator: "/").first.map(String.init) ?? relative
    let subfolderPath = documentsPath + "/" + firstComponent
    subfolderGroups[subfolderPath, default: []].append(readInfo)
  }
}

if !rootItems.isEmpty {
  sections.append(.root)
  itemsBySection[.root] = rootItems
  rootItems.forEach { allItems[$0.id] = $0 }
}

let sortedFolders = subfolderGroups.keys
  .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

for folderPath in sortedFolders {
  let folderName = (folderPath as NSString).lastPathComponent
  let section = BookShelfSectionType.folder(path: folderPath, name: folderName)
  let items = subfolderGroups[folderPath] ?? []
  sections.append(section)
  itemsBySection[section] = items
  items.forEach { allItems[$0.id] = $0 }
}
```

---

## 섹션 순서

```
[nowReading]          <- 읽는 중 (읽기 상태 기준)
[read]                <- 다 읽음 (읽기 상태 기준)
[root]                <- "Documents" (루트 파일, 있을 때만)
[folder ComicA]       <- 루트 디렉토리 책 + 하위 폴더들 (알파벳순으로 함께 정렬)
[folder ComicB]
[folder SubFolder]
...
```

> 루트 디렉토리 책과 하위 폴더 섹션은 `subfolderGroups`에 함께 들어가므로 알파벳순 정렬이 자동 적용됨.

---

## TODO List

### 구현
- [x] `BookShelfViewState.swift`: `BookShelfSectionType`에 `.root` case 추가 + `title` 분기 추가
- [x] `BookShelfViewModel.swift`: `buildState` 수정
  - `parent == documentsPath`일 때 디렉토리 여부 판별
  - 디렉토리 → `subfolderGroups[path]`에 추가
  - 파일 → `rootItems`에 추가
  - `rootItems`가 있으면 `.root` 섹션 추가

### 검증
- [x] 빌드 확인 (switch exhaustiveness 포함) — 성공 (9.3s)
- [x] `BookShelfSectionType`을 switch하는 곳 Grep으로 확인 — `title` 외 switch 없음

---

## 영향 범위

**변경되는 것:**
- `BookShelfSectionType` enum — `.root` case 추가
- `buildState` 내 폴더 수집 로직

**변경 없는 것:**
- `nowReading` / `read` 섹션 로직
- CollectionView 레이아웃 (모든 섹션이 동일 레이아웃)
- `BookShelfSectionHeaderView` (`.root`의 `title`이 "Documents"로 자동 적용)
- 컨텍스트 메뉴, 셀, 썸네일 로직

---

## 주의사항

- `BookShelfSectionType`을 switch하는 곳이 `title` 외에 있으면 컴파일 에러 발생 → 구현 전 Grep으로 확인
- `.root` 섹션은 `allItems`에도 추가되므로 컨텍스트 메뉴/탭 동작은 자동으로 동작
