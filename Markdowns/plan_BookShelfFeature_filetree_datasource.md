# plan_BookShelfFeature_filetree_datasource.md

## 문제

현재 `BookShelfViewModel.load()`는 `fetchAll()` / `fetchNowReading()` / `fetchRead()` — 즉 **DB에 등록된 ReadInfo만** 데이터 소스로 사용한다.
한 번도 열지 않은 파일은 DB에 없으므로 서재에 노출되지 않는다.

---

## 요구사항

1. **파일 트리 조회** (FinderDomain 이용) → Documents 디렉토리의 실제 파일/폴더 목록
2. **DB 데이터(ReadInfo)를 파일 트리 각 아이템에 매핑** → 읽기 상태 enrichment
3. DB에 데이터가 없어도 파일이 존재하면 노출

---

## 변경 대상

| 파일 | 변경 내용 |
|------|------|
| `Project.swift` | `FinderDomainInterface` 의존성 추가 |
| `Sources/Assembly/BookShelfFeatureAssembly.swift` | `FinderDomainInterface` resolve + 주입 |
| `Sources/Factory/BookShelfFeatureFactoryImpl.swift` | `FinderDomainInterface` 프로퍼티 추가 + UseCase 생성 시 전달 |
| `Sources/UseCase/BookShelfUseCase.swift` | `FinderDomainInterface` 주입, 파일트리 fetch 메서드 추가 |
| `Sources/Scene/BookShelf/BookShelfViewState.swift` | `BookShelfItem` 신규 모델, State 타입 변경 |
| `Sources/Scene/BookShelf/BookShelfViewModel.swift` | `load()` 재설계, `buildState()` 재설계 |
| `Sources/Scene/BookShelf/BookShelfViewController+CollectionView.swift` | `BookShelfItem` 기반으로 변경 |
| `Sources/Scene/BookShelf/BookShelfViewController+ContextMenu.swift` | `BookShelfItem` 기반으로 변경 |
| `Sources/Scene/Components/BookShelfCell.swift` | `ReadInfo` → `BookShelfItem` 수신 |

---

## 핵심 설계 결정

### 1. 새 모델 `BookShelfItem`

파일 트리가 source of truth. ReadInfo는 enrichment.

```swift
struct BookShelfItem: Identifiable, Hashable, Sendable {
  let fileItem: FileItem     // 항상 존재 (파일 시스템 기반)
  let readInfo: ReadInfo?    // DB에 기록이 있으면 존재

  var id: String { fileItem.path }  // DiffableDataSource identifier = 파일 경로
}
```

### 2. DiffableDataSource identifier 변경

| Before | After |
|--------|-------|
| `ReadInfo.id` (UUID String) | `fileItem.path` (파일 경로) |

- 경로는 파일 시스템에서 유일 → ReadInfo 없이도 식별 가능

### 3. 섹션 구조 (변경 없음)

```
[nowReading]   읽는 중 (readInfo.isRead == false && readIndex > 0)
[read]         다 읽음 (readInfo.isRead == true)
[root]         Documents 루트 파일 (파일 트리 기반)
[folder A]     1뎁스 하위 디렉토리 (파일 트리 기반)
[folder B]
...
```

### 4. 중복 노출 방지 (DiffableDataSource 제약)

동일 path가 여러 섹션에 등장하면 DiffableDataSource 크래시.
→ `nowReading` / `read`에 이미 추가된 path는 `root` / `folder` 섹션에서 제외.

```
shownPaths: Set<String>
nowReading 추가 → shownPaths에 path 등록
read 추가 → shownPaths에 path 등록
root/folder 빌드 시 → shownPaths에 없는 것만 추가
```

### 5. 파일 트리 조회 전략 (1뎁스)

```
finderDomain.listFiles(at: documentsPath)  → 루트 레벨 [FileItem]
  ├── 파일 → root 섹션 후보
  └── 디렉토리 → finderDomain.listFiles(at: dir.path) → 해당 folder 섹션 후보
```

더 깊은 뎁스(디렉토리 안의 디렉토리)는 현재 설계에서 별도 섹션 미생성.

### 6. Context Menu - ReadInfo 없는 경우

| 액션 | ReadInfo 없음 | ReadInfo 있음 |
|------|------|------|
| 열기 | 표시 | 표시 |
| 다 읽음으로 표시 | **표시** (선택 시 DB 생성 + 읽음 처리) | 표시 |
| 읽기 진행 초기화 | 숨김 (초기화 대상 없음) | 표시 |

**`markAsRead` 흐름 (ReadInfo 없는 경우):**
```
1. item.readInfo?.id ?? UUID().uuidString → identifier 결정
2. bookDomain.fetchReadInfoOrCreate(identifier:pathString:pathExtension:) → DB에 ReadInfo 생성
3. bookDomain.markAsRead(identifier:) → 읽음 상태로 업데이트
4. 로드 재실행 → 해당 파일이 read 섹션으로 이동
```

이 로직은 UseCase에 캡슐화: `markAsRead(item: BookShelfItem) throws`

---

## Before / After 상세

### `Project.swift`

**Before:**
```swift
.implements(module: .feature(.BookShelfFeature), product: .framework, dependencies: [
  .feature(target: .BookShelfFeature, type: .interface),
  .feature(target: .ReaderFeature, type: .interface),
  .domain(target: .BookDomain, type: .interface),
  .core(target: .ArchiveFileCore, type: .interface),
  ...
])
```

**After:**
```swift
.implements(module: .feature(.BookShelfFeature), product: .framework, dependencies: [
  .feature(target: .BookShelfFeature, type: .interface),
  .feature(target: .ReaderFeature, type: .interface),
  .domain(target: .BookDomain, type: .interface),
  .domain(target: .FinderDomain, type: .interface),   // 추가
  .core(target: .ArchiveFileCore, type: .interface),
  ...
])
```

---

### `BookShelfFeatureAssembly.swift`

**After:**
```swift
guard let finderDomain = resolver.resolve(FinderDomainInterface.self) else {
  fatalError("FinderDomainInterface not registered")
}
return BookShelfFeatureFactoryImpl(bookDomain: bookDomain, finderDomain: finderDomain, readerFactory: readerFactory)
```

---

### `BookShelfFeatureFactoryImpl.swift`

**After:**
```swift
final class BookShelfFeatureFactoryImpl: BookShelfFeatureFactory {
  private let bookDomain: BookDomainInterface
  private let finderDomain: FinderDomainInterface  // 추가
  private let readerFactory: ReaderFeatureFactory
  ...
  nonisolated init(bookDomain: BookDomainInterface, finderDomain: FinderDomainInterface, readerFactory: ReaderFeatureFactory) { ... }

  @MainActor
  func makeBookShelfNavigationController() -> UINavigationController {
    let useCase = BookShelfUseCaseImpl(bookDomain: bookDomain, finderDomain: finderDomain)  // finderDomain 전달
    ...
  }
}
```

---

### `BookShelfUseCase.swift`

**After:**
```swift
protocol BookShelfUseCase: Sendable {
  func fetchRootFileItems() throws -> [FileItem]
  func fetchFileItems(in directoryPath: String) throws -> [FileItem]
  func fetchAllReadInfos() throws -> [ReadInfo]
  func fetchNowReadingReadInfos() throws -> [ReadInfo]
  func fetchReadReadInfos() throws -> [ReadInfo]
  func markAsRead(item: BookShelfItem) throws   // ReadInfo 유무 무관하게 처리
  func resetProgress(identifier: String) throws
}

final class BookShelfUseCaseImpl: BookShelfUseCase {
  private let bookDomain: BookDomainInterface
  private let finderDomain: FinderDomainInterface
  private let documentsPath: String

  init(bookDomain: BookDomainInterface, finderDomain: FinderDomainInterface) {
    self.bookDomain = bookDomain
    self.finderDomain = finderDomain
    self.documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first?.path ?? ""
  }

  func fetchRootFileItems() throws -> [FileItem] {
    try finderDomain.listFiles(at: documentsPath)
  }

  func fetchFileItems(in directoryPath: String) throws -> [FileItem] {
    try finderDomain.listFiles(at: directoryPath)
  }

  func fetchAllReadInfos() throws -> [ReadInfo] { try bookDomain.fetchAllReadInfos() }
  func fetchNowReadingReadInfos() throws -> [ReadInfo] { try bookDomain.fetchUnfinishedReadInfos() }
  func fetchReadReadInfos() throws -> [ReadInfo] { try bookDomain.fetchFinishedReadInfos() }

  func markAsRead(item: BookShelfItem) throws {
    // ReadInfo가 없으면 먼저 DB에 생성 후 읽음 처리
    let path = item.fileItem.path
    let ext = (path as NSString).pathExtension
    let identifier = item.readInfo?.id ?? UUID().uuidString
    _ = try bookDomain.fetchReadInfoOrCreate(identifier: identifier, pathString: path, pathExtension: ext)
    try bookDomain.markAsRead(identifier: identifier)
  }

  func resetProgress(identifier: String) throws {
    try bookDomain.updateReadProgress(identifier: identifier, readIndex: 0)
  }
}
```

---

### `BookShelfViewState.swift`

**After:**
```swift
// 신규 모델
struct BookShelfItem: Identifiable, Hashable, Sendable {
  let fileItem: FileItem
  let readInfo: ReadInfo?
  var id: String { fileItem.path }
}

enum BookShelfSectionType: Hashable {
  case nowReading
  case read
  case root
  case folder(path: String, name: String)

  var title: String { ... }  // 기존과 동일
}

struct BookShelfViewState {
  var sections: [BookShelfSectionType] = []
  var itemsBySection: [BookShelfSectionType: [BookShelfItem]] = [:]
  var allItems: [String: BookShelfItem] = [:]  // path → BookShelfItem
  var isLoading: Bool = false
  var errorMessage: String? = nil

  var allBookShelfItems: [BookShelfItem] {
    sections.flatMap { itemsBySection[$0] ?? [] }
  }
}

enum BookShelfViewAction {
  case load
  case refresh
  case openItem(BookShelfItem)
  case markAsRead(BookShelfItem)
  case resetProgress(BookShelfItem)
}
```

---

### `BookShelfViewModel.swift` — `load()` / `buildState()`

**After `load()`:**
```swift
private func load() {
  loadTask?.cancel()
  let useCase = self.useCase
  loadTask = Task {
    var next = state
    next.isLoading = true
    next.errorMessage = nil
    state = next

    do {
      let (rootItems, nowReading, read, allReadInfos) = try await Task.detached {
        (
          try useCase.fetchRootFileItems(),
          try useCase.fetchNowReadingReadInfos(),
          try useCase.fetchReadReadInfos(),
          try useCase.fetchAllReadInfos()
        )
      }.value

      guard !Task.isCancelled else { return }

      // 디렉토리의 자식 아이템 조회 (1뎁스)
      let directoryItems = rootItems.filter { $0.isDirectory }
      var folderChildren: [String: [FileItem]] = [:]
      for dir in directoryItems {
        let children = (try? await Task.detached { try useCase.fetchFileItems(in: dir.path) }.value) ?? []
        folderChildren[dir.path] = children
      }

      guard !Task.isCancelled else { return }

      state = buildState(
        rootItems: rootItems,
        folderChildren: folderChildren,
        nowReadingInfos: nowReading,
        readInfos: read,
        allReadInfos: allReadInfos
      )
    } catch {
      guard !Task.isCancelled else { return }
      var updated = state
      updated.isLoading = false
      updated.errorMessage = error.localizedDescription
      state = updated
    }
  }
}
```

**After `buildState()`:**
```swift
private func buildState(
  rootItems: [FileItem],
  folderChildren: [String: [FileItem]],
  nowReadingInfos: [ReadInfo],
  readInfos: [ReadInfo],
  allReadInfos: [ReadInfo]
) -> BookShelfViewState {
  var sections: [BookShelfSectionType] = []
  var itemsBySection: [BookShelfSectionType: [BookShelfItem]] = [:]
  var allItems: [String: BookShelfItem] = [:]
  var shownPaths: Set<String> = []

  // path → ReadInfo 조회 테이블
  let readInfoByPath: [String: ReadInfo] = Dictionary(
    allReadInfos.compactMap { ri in ri.pathString.map { ($0, ri) } },
    uniquingKeysWith: { first, _ in first }
  )

  // nowReading 섹션
  let nowReadingItems = nowReadingInfos.compactMap { ri -> BookShelfItem? in
    guard let path = ri.pathString else { return nil }
    let fileItem = FileItem(name: (path as NSString).lastPathComponent, path: path, isDirectory: false)
    return BookShelfItem(fileItem: fileItem, readInfo: ri)
  }
  if !nowReadingItems.isEmpty {
    sections.append(.nowReading)
    itemsBySection[.nowReading] = nowReadingItems
    nowReadingItems.forEach { allItems[$0.id] = $0; shownPaths.insert($0.id) }
  }

  // read 섹션
  let readItems = readInfos.compactMap { ri -> BookShelfItem? in
    guard let path = ri.pathString, !shownPaths.contains(path) else { return nil }
    let fileItem = FileItem(name: (path as NSString).lastPathComponent, path: path, isDirectory: false)
    return BookShelfItem(fileItem: fileItem, readInfo: ri)
  }
  if !readItems.isEmpty {
    sections.append(.read)
    itemsBySection[.read] = readItems
    readItems.forEach { allItems[$0.id] = $0; shownPaths.insert($0.id) }
  }

  // root 섹션: 루트의 파일만 (디렉토리 제외, shownPaths 제외)
  let rootFileItems = rootItems
    .filter { !$0.isDirectory && !shownPaths.contains($0.path) }
    .map { BookShelfItem(fileItem: $0, readInfo: readInfoByPath[$0.path]) }
  if !rootFileItems.isEmpty {
    sections.append(.root)
    itemsBySection[.root] = rootFileItems
    rootFileItems.forEach { allItems[$0.id] = $0; shownPaths.insert($0.id) }
  }

  // folder 섹션: 루트의 디렉토리 및 그 자식들
  let sortedDirs = rootItems
    .filter { $0.isDirectory }
    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

  for dir in sortedDirs {
    let children = (folderChildren[dir.path] ?? [])
      .filter { !shownPaths.contains($0.path) }
      .map { BookShelfItem(fileItem: $0, readInfo: readInfoByPath[$0.path]) }

    // 디렉토리 자체도 BookShelfItem으로 (디렉토리 책인 경우)
    // 디렉토리는 자식이 있는 폴더일 수 있으므로, children이 없으면 디렉토리 자체를 아이템으로
    var sectionItems: [BookShelfItem] = []
    if children.isEmpty && !shownPaths.contains(dir.path) {
      let dirItem = BookShelfItem(fileItem: dir, readInfo: readInfoByPath[dir.path])
      sectionItems = [dirItem]
    } else {
      sectionItems = children
    }

    guard !sectionItems.isEmpty else { continue }
    let section = BookShelfSectionType.folder(path: dir.path, name: dir.name)
    sections.append(section)
    itemsBySection[section] = sectionItems
    sectionItems.forEach { allItems[$0.id] = $0; shownPaths.insert($0.id) }
  }

  return BookShelfViewState(
    sections: sections,
    itemsBySection: itemsBySection,
    allItems: allItems,
    isLoading: false,
    errorMessage: nil
  )
}
```

---

### `BookShelfCell.swift`

`ReadInfo` → `BookShelfItem` 수신.
nil-safe 처리 추가.

```swift
struct BookShelfCell: View {
  let item: BookShelfItem   // ReadInfo → BookShelfItem
  var onOpen: (() -> Void)? = nil

  private var readInfo: ReadInfo? { item.readInfo }
  private var fileItem: FileItem { item.fileItem }

  // fileName: fileItem.name 사용
  // progressFraction: readInfo가 nil이면 0
  // startDateText: readInfo?.createDate → 없으면 fileItem.modifiedDate
  // durationText: readInfo?.readDate → 없으면 "미열람"
}
```

**`progressFraction`:**
```swift
private var progressFraction: Double {
  guard let ri = readInfo, ri.totalPage > 1 else {
    return readInfo?.totalPage == 1 ? 1.0 : 0
  }
  return Double(ri.readIndex) / Double(ri.totalPage - 1)
}
```

**`startDateText`:**
```swift
private var startDateText: String {
  let date = readInfo?.createDate ?? item.fileItem.modifiedDate
  guard let date else { return "" }
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "ko_KR")
  formatter.dateStyle = .short
  return formatter.string(from: date)
}
```

**`durationText`:**
```swift
private var durationText: String {
  guard let readDate = readInfo?.readDate else { return "미열람" }
  // 기존 로직 동일
}
```

**`loadThumbnail`:**
```swift
private func loadThumbnail() async {
  let path = item.fileItem.path
  // fileKind는 fileItem 기반으로 계산 (변경 없음)
  ...
}
```

---

### `BookShelfViewController+CollectionView.swift`

```swift
// DataSource 타입 변경
typealias BookShelfDataSource = UICollectionViewDiffableDataSource<BookShelfSectionType, String>
// item identifier = BookShelfItem.id (= fileItem.path)

// cell provider
cell.contentConfiguration = UIHostingConfiguration {
  BookShelfCell(item: item, onOpen: { self?.onSelectItem?(item) })
}.margins(.all, 0)

// applySnapshot
let ids = (itemsBySection[section] ?? []).map(\.id)  // id = fileItem.path
```

---

### `BookShelfViewController+ContextMenu.swift`

```swift
private func makeContextMenu(for item: BookShelfItem) -> UIMenu {
  let openAction = UIAction(...) { self?.onSelectItem?(item) }

  // markAsRead: ReadInfo 유무 무관하게 항상 표시
  let markAsReadAction = UIAction(
    title: "다 읽음으로 표시",
    image: UIImage(systemName: "checkmark.circle")
  ) { [weak self] _ in
    self?.viewModel.send(.markAsRead(item))
  }

  // resetProgress: ReadInfo가 있을 때만 표시 (초기화 대상 없으면 숨김)
  guard item.readInfo != nil else {
    return UIMenu(title: item.fileItem.name, children: [
      UIMenu(title: "", options: .displayInline, children: [openAction]),
      UIMenu(title: "", options: .displayInline, children: [markAsReadAction])
    ])
  }

  let resetProgressAction = UIAction(
    title: "읽기 진행 초기화",
    image: UIImage(systemName: "arrow.counterclockwise"),
    attributes: .destructive
  ) { [weak self] _ in
    self?.viewModel.send(.resetProgress(item))
  }

  return UIMenu(title: item.fileItem.name, children: [
    UIMenu(title: "", options: .displayInline, children: [openAction]),
    UIMenu(title: "", options: .displayInline, children: [markAsReadAction, resetProgressAction])
  ])
}
```

---

### `BookShelfCoordinator.swift`

```swift
// onSelectItem 타입 변경
viewController.onSelectItem = { [weak self] item in
  self?.showReader(item: item)
}

@MainActor
private func showReader(item: BookShelfItem) {
  let path = item.fileItem.path
  guard readerFactory.canOpenReader(path) else { return }
  ...
}
```

---

## 섹션 순서 최종

```
[nowReading]    읽는 중 (ReadInfo 기반, shownPaths 등록)
[read]          다 읽음 (ReadInfo 기반, shownPaths 등록)
[root]          Documents 루트 파일 (파일트리 기반, shownPaths 미포함만)
[folder A]      루트 하위 디렉토리 (파일트리 기반)
[folder B]
...
```

---

## TODO List

### 구현
- [ ] `Project.swift`: `FinderDomainInterface` 의존성 추가
- [ ] `BookShelfFeatureAssembly.swift`: `FinderDomainInterface` resolve + 주입
- [ ] `BookShelfFeatureFactoryImpl.swift`: `finderDomain` 프로퍼티 추가 + UseCase 생성 시 전달
- [ ] `BookShelfUseCase.swift`: `FinderDomainInterface` 주입, 파일트리 메서드 추가, 기존 fetch 메서드 rename
- [ ] `BookShelfViewState.swift`: `BookShelfItem` 모델 추가, State/Action 타입 변경
- [ ] `BookShelfViewModel.swift`: `load()` / `performMutation()` / `buildState()` 재설계
- [ ] `BookShelfCell.swift`: `ReadInfo` → `BookShelfItem` 수신, nil-safe 처리
- [ ] `BookShelfViewController+CollectionView.swift`: `BookShelfItem` 기반 DataSource 변경
- [ ] `BookShelfViewController+ContextMenu.swift`: `BookShelfItem` 기반, `markAsRead` 항상 표시, `resetProgress`만 ReadInfo 없으면 숨김
- [ ] `BookShelfCoordinator.swift`: `onSelectItem` 콜백 타입 변경

### 검증
- [ ] 빌드 성공
- [ ] `make regenerate` (Project.swift 변경 후)

---

## 영향 범위

**변경되는 것:**
- 데이터 소스: DB → 파일 트리 + DB enrichment
- Item model: `ReadInfo` → `BookShelfItem`
- DiffableDataSource identifier: UUID String → 파일 경로 String
- UseCase 인터페이스: `FinderDomainInterface` 추가

**변경 없는 것:**
- 섹션 타입 구조 (nowReading/read/root/folder)
- CollectionView 레이아웃 (220×320 카드)
- 썸네일 로딩 로직 (CoverImageProvider, ThumbnailCache)
- 컨텍스트 메뉴 구조 (단, resetProgress만 ReadInfo 없으면 숨김 / markAsRead는 항상 표시)

---

## 주의사항

- `make regenerate` 필수 (Project.swift 변경)
- `BookShelfItem.id = fileItem.path` — 경로에 특수문자 있어도 DiffableDataSource는 String identity로 처리하므로 안전
- `nowReading` / `read` 섹션의 FileItem은 실제 파일 존재 여부 미검증 (삭제된 파일의 ReadInfo가 남아있으면 노출될 수 있음) — 현재 범위 밖
- 디렉토리 자식 조회 루프는 루트 디렉토리 수만큼 `listFiles` 호출 → I/O 비용. Task.detached로 이미 격리됨
