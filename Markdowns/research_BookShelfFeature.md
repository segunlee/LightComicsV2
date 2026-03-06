# research_BookShelfFeature.md

> 분석일: 2026-03-05
> 대상: `Projects/Feature/BookShelfFeature/`
> Swift 6, UIKit + SwiftUI 혼합, MVVM + Coordinator

---

## 1. 디렉토리 구조

```
BookShelfFeature/
├── Project.swift                          # Tuist 모듈 정의
├── Interface/
│   └── BookShelfFeatureFactory.swift      # 공개 팩토리 프로토콜 (Interface target)
└── Sources/
    ├── Assembly/
    │   └── BookShelfFeatureAssembly.swift # Swinject 등록
    ├── Cache/
    │   ├── CoverImageProvider.swift       # PDF/아카이브/폴더 커버 이미지 로더 (actor)
    │   └── ThumbnailCache.swift           # QuickLook 썸네일 캐시 (actor)
    ├── Coordinator/
    │   └── BookShelfCoordinator.swift     # 화면 전환 담당
    ├── Factory/
    │   └── BookShelfFeatureFactoryImpl.swift # 팩토리 구현체
    ├── UseCase/
    │   └── BookShelfUseCase.swift         # UseCase 프로토콜 + 구현체
    └── Scene/
        ├── BookShelf/
        │   ├── BookShelfViewController.swift           # 메인 VC
        │   ├── BookShelfViewController+CollectionView.swift  # 레이아웃 + DataSource + Delegate
        │   ├── BookShelfViewController+ContextMenu.swift     # 컨텍스트 메뉴
        │   ├── BookShelfViewModel.swift                # @MainActor ViewModel
        │   └── BookShelfViewState.swift                # State/Action/SectionType 정의
        └── Components/
            ├── BookShelfCell.swift         # SwiftUI 카드 셀
            ├── BookShelfSectionHeaderView.swift # SwiftUI 섹션 헤더
            └── BookTextCoverView.swift     # 텍스트 파일용 커버 뷰
```

---

## 2. 의존 관계

```
BookShelfFeature (Sources)
  ├── BookShelfFeatureInterface (Interface target)
  ├── ReaderFeatureInterface
  ├── BookDomainInterface          <- ReadInfo, BookDomainInterface
  ├── ArchiveFileCoreInterface     <- CoverImageProvider에서 사용
  ├── SharedUIComponents           <- ViewControllerLifecycle, Toast
  ├── Logger
  └── Swinject
```

---

## 3. 인터페이스 / 공개 계약

### `BookShelfFeatureFactory` (Interface)
```swift
public protocol BookShelfFeatureFactory {
  @MainActor
  func makeBookShelfNavigationController() -> UINavigationController
}
```
- 외부에서 BookShelf 화면을 얻는 유일한 진입점

### 연관 타입 (`BookDomainInterface`)
| 타입 | 역할 |
|------|------|
| `ReadInfo` | 책 한 권의 읽기 상태 모델 (id, pathString, readIndex, totalPage, readDate, createDate, isRead, ...) |
| `BookDomainInterface` | DB CRUD 프로토콜. `fetchAllReadInfos`, `fetchUnfinishedReadInfos`, `fetchFinishedReadInfos`, `markAsRead`, `updateReadProgress` 등 |

---

## 4. 각 파일 상세 분석

### 4-1. `BookShelfFeatureAssembly`

```swift
public func assemble(container: Container) {
  container.register(BookShelfFeatureFactory.self) { resolver in
    // BookDomainInterface, ReaderFeatureFactory 필수 resolve (없으면 fatalError)
    // ArchiveFileCoreInterface: 선택적(optional), 있으면 CoverImageProvider.shared.configure 호출
    Task { await CoverImageProvider.shared.configure(archiveCore: archiveCore) }
    return BookShelfFeatureFactoryImpl(bookDomain: bookDomain, readerFactory: readerFactory)
  }.inObjectScope(.container)
}
```
- `.container` 스코프 → 싱글톤 등록
- `CoverImageProvider` 설정은 `Task { }` 안에서 비동기로 actor에 접근

---

### 4-2. `BookShelfFeatureFactoryImpl`

```swift
@MainActor
func makeBookShelfNavigationController() -> UINavigationController {
  let useCase = BookShelfUseCaseImpl(bookDomain: bookDomain)
  let nav = UINavigationController()
  nav.navigationBar.prefersLargeTitles = true
  let coordinator = BookShelfCoordinator(navigationController: nav, useCase: useCase, readerFactory: readerFactory)
  coordinator.start()
  self.coordinator = coordinator  // strong reference 유지
  return nav
}
```
- Factory가 Coordinator를 소유 → Coordinator가 VC를 소유하지 않고 nav에 push

---

### 4-3. `BookShelfCoordinator`

**Properties:**
- `weak var navigationController: UINavigationController?` — weak, 순환참조 방지
- `useCase: BookShelfUseCase` — ViewModel 생성에 전달
- `readerFactory: ReaderFeatureFactory` — 리더 화면 생성

**`start()` 흐름:**
```
start()
  -> BookShelfViewModel(useCase:)
  -> BookShelfViewController(viewModel:)
  -> vc.onSelectItem = { [weak self] readInfo in self?.showReader(readInfo:) }
  -> nav.setViewControllers([vc], animated: false)
```

**`showReader(readInfo:)` 흐름:**
```
readInfo.pathString  ->  nil이면 Log.debug + return
readerFactory.canOpenReader(path)  ->  false면 return
readerFactory.makeReaderViewController(filePath: path)
  -> UINavigationController(rootViewController: vc)
  -> modalPresentationStyle = .fullScreen
  -> nav.topViewController?.present(nav, animated: true)
```
- fullScreen Modal로 리더를 표시

---

### 4-4. `BookShelfUseCase`

```swift
protocol BookShelfUseCase: Sendable {
  func fetchNowReading() throws -> [ReadInfo]  // fetchUnfinishedReadInfos
  func fetchRead() throws -> [ReadInfo]         // fetchFinishedReadInfos
  func fetchAll() throws -> [ReadInfo]          // fetchAllReadInfos
  func markAsRead(identifier: String) throws
  func resetProgress(identifier: String) throws // updateReadProgress(..., readIndex: 0)
}
```
- 동기 throws 인터페이스 → ViewModel이 `Task.detached`로 감쌈

---

### 4-5. `BookShelfViewState` / `BookShelfViewAction` / `BookShelfSectionType`

```swift
enum BookShelfSectionType: Hashable {
  case nowReading          // "읽는 중"
  case read                // "다 읽음"
  case folder(path: String, name: String)  // Documents 하위 폴더
}

struct BookShelfViewState {
  var sections: [BookShelfSectionType] = []
  var itemsBySection: [BookShelfSectionType: [ReadInfo]] = [:]
  var allItems: [String: ReadInfo] = [:]  // id -> ReadInfo 조회용
  var isLoading: Bool = false
  var errorMessage: String? = nil
}

enum BookShelfViewAction {
  case load
  case refresh
  case openItem(ReadInfo)      // 현재 ViewModel에서 로그만 찍음 (미구현)
  case markAsRead(ReadInfo)
  case resetProgress(ReadInfo)
}
```

---

### 4-6. `BookShelfViewModel`

**타입:** `@MainActor final class`, `ObservableObject`

**Properties:**
| 이름 | 타입 | 역할 |
|------|------|------|
| `state` | `@Published BookShelfViewState` | UI 상태 전체 |
| `toastEvent` | `PassthroughSubject<ToastConfiguration, Never>` | 에러 토스트 발행 |
| `useCase` | `BookShelfUseCase` | 데이터 fetch/mutation |
| `loadTask` | `Task<Void, Never>?` | 중복 로드 취소용 |

**`send(_ action:)` 분기:**
```
.load / .refresh   ->  load()
.openItem          ->  Log.debug (화면 전환은 Coordinator가 직접 수행)
.markAsRead        ->  performMutation { useCase.markAsRead(id) }
.resetProgress     ->  performMutation { useCase.resetProgress(id) }
```

**`load()` 상세 흐름:**
```
1. loadTask?.cancel()
2. state.isLoading = true, errorMessage = nil
3. Task {
     Task.detached { fetchNowReading, fetchRead, fetchAll } -> 동기 DB를 백그라운드 격리
     guard !Task.isCancelled
     state = buildState(nowReading:read:all:)
   } catch {
     state.isLoading = false
     state.errorMessage = error.localizedDescription
   }
```

**`performMutation(_:errorContext:)` 상세 흐름:**
```
1. loadTask?.cancel()
2. Task {
     Task.detached { operation() }       // mutation (동기 DB)
     Task.detached { fetch all three }   // 재조회
     state = buildState(...)
   } catch {
     toastEvent.send(.init(type: .error, message: ...))
   }
```

**`buildState(nowReading:read:all:)` 로직:**
```
sections 순서: [.nowReading?] + [.read?] + [.folder(path:name:)...]

폴더 그룹 계산:
  for readInfo in all:
    path의 parent가 documentsPath이면 스킵 (루트 레벨은 섹션 안 만듦)
    parent.hasPrefix(documentsPath + "/")이면 relative path의 첫 컴포넌트를 folder key로 사용
  폴더명 기준 localizedCaseInsensitiveCompare 오름차순 정렬

allItems는 id -> ReadInfo dict (CollectionView diffable 조회용)
```

**중요 엣지케이스:** Documents 루트에 있는 파일(parent == documentsPath)은 어떤 섹션에도 포함되지 않음 → `nowReading` / `read`에도 없으면 화면에 표시되지 않는 책이 생길 수 있음.

---

### 4-7. `BookShelfViewController`

**Properties:**
| 이름 | 타입 | 접근 | 역할 |
|------|------|------|------|
| `viewModel` | `BookShelfViewModel` | internal | VM |
| `collectionView` | `UICollectionView` | internal | 메인 리스트 |
| `refreshControl` | `UIRefreshControl` | internal | 당겨서 새로고침 |
| `activityIndicator` | `UIActivityIndicatorView(.large)` | internal | 초기 로딩 스피너 |
| `diffableDataSource` | `BookShelfDataSource?` | internal | DiffableDataSource |
| `cancellable` | `Set<AnyCancellable>` | internal | Combine 구독 |
| `onSelectItem` | `((ReadInfo) -> Void)?` | internal | Coordinator 콜백 |
| `needsRefreshOnAppear` | `Bool` | private | 뷰 복귀 시 새로고침 트리거 |

**`viewDidLoad` 순서:**
```
setupUI() -> setupCollectionView() -> configureDataSource() -> bindViewModel() -> loadInitialData()
```

**`setupUI` 레이아웃:**
- `view.backgroundColor = .systemGroupedBackground`
- `activityIndicator`: centerX/centerY에 고정
- `title = "서재"`

**`setupCollectionView` 레이아웃:**
- collectionView: safeAreaLayoutGuide.top ~ view.bottom, leading/trailing = 0
- refreshControl 연결, `handleRefresh` -> `.refresh` action

**뷰 생명주기 패턴:**
```
viewDidDisappear -> needsRefreshOnAppear = true
viewWillAppear  -> needsRefreshOnAppear가 true이면 .refresh 전송 후 false로 초기화
```
- 리더에서 돌아올 때 자동 새로고침

**`bindViewModel` 구독 3개:**
1. `viewModel.$state` (dropFirst) -> `applySnapshot` + emptyView 처리
   - `state.allItems.isEmpty && !isLoading` -> error면 `.error(description:)`, 아니면 `.noData`
2. `viewModel.$state.map(\.isLoading).removeDuplicates()` -> activityIndicator 제어
3. `viewModel.toastEvent` -> `Toast.show($0)`

---

### 4-8. `BookShelfViewController+CollectionView`

**타입 별칭:**
```swift
typealias BookShelfDataSource = UICollectionViewDiffableDataSource<BookShelfSectionType, String>
typealias BookShelfSnapshot = NSDiffableDataSourceSnapshot<BookShelfSectionType, String>
```
- item identifier = `ReadInfo.id` (String)

**CompositionalLayout 섹션 구조 (모든 섹션 동일):**
```
item:  width=.absolute(220), height=.absolute(320)
group: width=.absolute(220), height=.absolute(320), horizontal
section:
  orthogonalScrollingBehavior = .groupPagingCentered
  interGroupSpacing = 16
  contentInsets = top:12, leading:20, bottom:28, trailing:20
header:
  width=.fractionalWidth(1.0), height=.estimated(56)
  elementKind = elementKindSectionHeader, alignment = .top
```
- 모든 섹션이 가로 스크롤 카드 레이아웃

**Cell 등록 (`UIHostingConfiguration`):**
```swift
cell.contentConfiguration = UIHostingConfiguration {
  BookShelfCell(readInfo: readInfo, onOpen: { self?.onSelectItem?(readInfo) })
}.margins(.all, 0)
```

**Header 등록:**
```swift
header.contentConfiguration = UIHostingConfiguration {
  BookShelfSectionHeaderView(title: section.title, itemCount: count)
}.margins(.all, 0)
```

**`applySnapshot`:**
```swift
snapshot.appendSections(sections)
for section in sections { snapshot.appendItems(ids, toSection: section) }
diffableDataSource?.apply(snapshot, animatingDifferences: true)
```

**`UICollectionViewDelegate.didSelectItemAt`:**
```swift
collectionView.deselectItem(at: indexPath, animated: true)
-> diffableDataSource?.itemIdentifier -> viewModel.state.allItems[itemID]
-> onSelectItem?(readInfo)
```

---

### 4-9. `BookShelfViewController+ContextMenu`

**`contextMenuConfigurationForItemAt`:**
```swift
UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
  self?.makeContextMenu(for: readInfo) ?? UIMenu(children: [])
}
```

**`makeContextMenu(for:)` 구조:**
```
UIMenu(title: fileName, children: [
  UIMenu(title: "", options: .displayInline, children: [openAction]),
  UIMenu(title: "", options: .displayInline, children: [markAsReadAction, resetProgressAction])
])
```
| 액션 | 시스템 이미지 | attributes | 동작 |
|------|------|------|------|
| 열기 | `book` | - | `onSelectItem?(readInfo)` |
| 다 읽음으로 표시 | `checkmark.circle` | - | `viewModel.send(.markAsRead(readInfo))` |
| 읽기 진행 초기화 | `arrow.counterclockwise` | `.destructive` | `viewModel.send(.resetProgress(readInfo))` |

---

### 4-10. `BookShelfCell` (SwiftUI)

**크기:** 220 x 320 pt 고정 (`frame(width: 220, height: 320)`)

**구조:**
```
ZStack(topTrailing) {
  VStack(spacing: 0) {
    thumbnailView   // 220 x 192
    infoView        // 220 x 128
  }
  openButton       // 우상단, padding(10)
}
.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
.shadow(accentColor.opacity(0.45), radius: 20, x: 0, y: 10)
.shadow(.black.opacity(0.2), radius: 6, x: 0, y: 3)
```

**`fileKind` 판별:**
```
FileManager.fileExists(isDirectory:) -> .directory
ext -> .text: txt/text/rtf
       .pdf: pdf
       .archive: zip/cbz/rar/cbr/7z/cb7/tar/cbt/gz/bz2/xz
       else: .other
```

**`thumbnailView` 분기:**
```
fileKind == .text  -> BookTextCoverView(title:)
thumbnail != nil   -> Image(uiImage:).resizable().scaledToFill()
isLoading          -> shimmerView (LinearGradient 셔머 애니메이션)
else               -> fallbackCoverView (book.closed 아이콘)
```

**shimmerView 애니메이션:**
- `shimmerOffset`: -1 -> 2 반복, `.linear(duration: 1.2).repeatForever(autoreverses: false)`
- `LinearGradient` startPoint/endPoint를 shimmerOffset 기준으로 이동

**`infoView` 구성 (padding: horizontal 12, vertical 10):**
```
VStack(leading, spacing: 5) {
  Text(fileName)          .font(.subheadline.bold()).lineLimit(2)
  Label(startDateText)    .font(.caption2)  // calendar.badge.clock
  Label(durationText)     .font(.caption2)  // clock
  Spacer(minLength: 4)
  HStack(spacing: 8) {
    GeometryReader -> 진행도 바 (높이 4pt Capsule)
    Text("\(Int(progressFraction * 100))%")  .font(.caption2)
  }
}
.foregroundStyle(.white)
.background(infoBackground)
```

**`infoBackground`:**
```swift
ZStack {
  accentColor.mix(with: Color.black, by: 0.5)
  Rectangle().fill(.ultraThinMaterial.opacity(0.25))
}
```

**`openButton`:**
- `arrow.up.right` 아이콘, `.caption.bold()`
- 28x28, `.background(.ultraThinMaterial, in: Circle())`

**`progressFraction` 계산:**
```swift
guard readInfo.totalPage > 1 else { return readInfo.totalPage == 1 ? 1.0 : 0 }
return Double(readInfo.readIndex) / Double(readInfo.totalPage - 1)
```

**`startDateText`:** `readInfo.createDate`를 `DateFormatter(dateStyle: .short, locale: ko_KR)`로 포맷

**`durationText`:** `readInfo.readDate`가 nil이면 "읽는 중"
```
readDate 있음:
  totalMinutes = max(1, Int(Date.now.timeIntervalSince(readDate) / 60))
  < 60    -> "N분 전에 읽음"
  < 1440  -> "N시간 [M분] 전에 읽음"
  < ?     -> "N일 전에 읽음"  (days = totalMinutes / 1440, 30 미만)
  else    -> "N개월 전에 읽음" (days / 30)
```

**`loadThumbnail()` 흐름:**
```
.text       -> return (BookTextCoverView가 커버 담당)
.pdf/.archive/.directory:
  scale = await MainActor.run { UIScreen.main.scale }
  image = await CoverImageProvider.shared.cover(path, size: 440x384, scale)
  withAnimation(.easeInOut(0.3)) { thumbnail = image; isLoading = false }
  if image -> await extractDominantColor(from: image)
.other:
  image = await ThumbnailCache.shared.thumbnail(path, size: 440x384, scale)
  (동일 패턴)
```

**`extractDominantColor`:**
- `Task.detached(priority: .utility)` 에서 CGContext 1x1 픽셀 다운샘플로 평균색 추출
- `withAnimation(.easeInOut(0.5)) { accentColor = color }`

---

### 4-11. `BookShelfSectionHeaderView` (SwiftUI)

```
HStack(firstTextBaseline, spacing: 8) {
  Text(title)  .font(.title3.bold())
  Text("\(itemCount)")  .font(.caption2.semibold) + Capsule badge
  Spacer()
}
.padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 4)
```

---

### 4-12. `BookTextCoverView` (SwiftUI)

- 5개 팔레트 중 `title.hashValue % 5` 인덱스로 그라디언트 선택
- decorativeLines: 4개 수평선 (opacity 0.12, 교대 padding 12/20)
- 제목 텍스트: `.system(.headline, design: .serif).bold()`, lineLimit 5

---

### 4-13. `CoverImageProvider` (actor)

**캐시 설정:**
- `NSCache`: countLimit=200, totalCostLimit=100MB
- inFlight dedup: `[String: Task<UIImage?, Never>]`

**`cover(for:size:scale:)` 흐름:**
```
1. cache hit -> return
2. inFlight hit -> await task.value
3. 새 task 생성 -> inFlight 등록
4. await loadCover(path:size:scale:)
5. inFlight 제거 -> cache 저장 (cost = bytesPerRow * height)
```

**`loadCover` 분기:**
```
FileManager.fileExists(isDirectory:)
  isDir -> loadDirectoryCover (이미지 파일 목록 정렬, 첫 번째 반환)
  ext == "pdf" -> loadPDFCover (PDFDocument, page 0, thumbnail(of:for:))
  ext in archiveExtensions -> loadArchiveCover (임시 폴더 압축 해제 후 findFirstImage)
  else -> nil
```

**`loadArchiveCover` 주의:**
- 매 호출마다 UUID 폴더 생성 -> 압축 해제 -> findFirstImage -> defer로 임시 폴더 삭제
- 캐시 미스 시 비용 큰 연산

---

### 4-14. `ThumbnailCache` (actor)

- `NSCache`: countLimit=200, totalCostLimit=150MB
- `QLThumbnailGenerator.shared.generateBestRepresentation(for:)` 비동기 사용
- `inFlight` dedup 동일 패턴

---

## 5. 데이터 흐름 (End-to-End)

```
앱 시작
  └─ AppDIContainer.assemble
       └─ BookShelfFeatureAssembly.assemble
            └─ CoverImageProvider.shared.configure(archiveCore:)  [Task 비동기]

탭 진입
  └─ BookShelfFeatureFactoryImpl.makeBookShelfNavigationController()
       └─ BookShelfCoordinator.start()
            └─ BookShelfViewController.viewDidLoad()
                 ├─ setupUI / setupCollectionView / configureDataSource
                 ├─ bindViewModel() -> $state 구독 3개
                 └─ loadInitialData() -> viewModel.send(.load)

.load 처리
  └─ BookShelfViewModel.load()
       ├─ state.isLoading = true  -> activityIndicator 표시
       └─ Task {
            Task.detached { fetchNowReading, fetchRead, fetchAll }
            buildState(...)
            state = newState  -> applySnapshot -> CollectionView 업데이트
          }

셀 표시
  └─ configureDataSource cell provider
       └─ BookShelfCell(readInfo:).task(id:) -> loadThumbnail()
            ├─ CoverImageProvider.cover() (pdf/archive/dir)
            └─ ThumbnailCache.thumbnail() (other)

아이템 탭
  └─ UICollectionViewDelegate.didSelectItemAt
       └─ onSelectItem?(readInfo)
            └─ BookShelfCoordinator.showReader(readInfo:)
                 └─ readerFactory.makeReaderViewController(filePath:)
                      └─ UINavigationController(fullScreen) present

리더 닫기 -> viewWillAppear -> needsRefreshOnAppear 체크 -> .refresh
```

---

## 6. 상태 전이 다이어그램

```
initial (isLoading=false, sections=[], allItems={})
  |
  | .load
  v
loading (isLoading=true)
  |
  +-- 성공 --> loaded (isLoading=false, sections=[...], allItems={...})
  |              |
  |              +-- .markAsRead / .resetProgress --> mutation --> loaded (재조회)
  |              |
  |              +-- .refresh --> loading
  |
  +-- 실패 --> error (isLoading=false, errorMessage=..., allItems={})

allItems가 비어 있을 때:
  isLoading=true  -> activityIndicator 표시 (emptyView 없음)
  isLoading=false, errorMessage=nil  -> emptyView(.noData)
  isLoading=false, errorMessage!=nil -> emptyView(.error(description:))
```

---

## 7. Swift 6 동시성 준수 현황

| 항목 | 상태 | 비고 |
|------|------|------|
| `BookShelfViewModel` @MainActor | O | 클래스 전체 격리 |
| `CoverImageProvider` actor | O | 캐시/inFlight 격리 |
| `ThumbnailCache` actor | O | 캐시/inFlight 격리 |
| DB 동기 작업 Task.detached 격리 | O | `load()`, `performMutation()` |
| `BookShelfUseCase: Sendable` | O | |
| `ReadInfo: Sendable` | O | |
| `UIScreen.main.scale` MainActor 접근 | O | `await MainActor.run { UIScreen.main.scale }` |
| `extractDominantColor` Task.detached(priority: .utility) | O | UI 무관 연산 격리 |

---

## 8. 에러 처리 전략

| 위치 | 전략 | UX |
|------|------|-----|
| `load()` DB 에러 | catch -> `state.errorMessage` 설정 | emptyView(.error) 표시 |
| `performMutation` 에러 | catch -> `toastEvent.send(.error)` | Toast 표시 |
| `CoverImageProvider.loadArchiveCover` | try/catch -> nil 반환 | fallbackCoverView 표시 |
| `ThumbnailCache` QL 실패 | try? -> nil 반환 | fallbackCoverView 표시 |
| `showReader` pathString nil | Log + return | 조용히 무시 |
| `showReader` canOpenReader false | Log + return | 조용히 무시 |

---

## 9. 잠재적 버그 및 엣지케이스

| # | 위치 | 내용 |
|---|------|------|
| 1 | `buildState` | Documents 루트 레벨 파일은 `nowReading`/`read`가 아닌 경우 어떤 섹션에도 포함 안 됨 (표시 누락 가능) |
| 2 | `durationText` | `days < 30` 체크 없이 `days` 기준 판단 -> 30일 이상이면 개월 표시. 정확한 달력 개월 수 아님 |
| 3 | `CoverImageProvider.loadArchiveCover` | 캐시 미스 시 매번 전체 압축 해제 -> 대용량 아카이브 UX 저하 |
| 4 | `openItem` action | ViewModel의 `.openItem` 케이스가 로그만 출력하고 실제 동작 없음. Coordinator 콜백과 중복 경로 존재 |
| 5 | `BookShelfCell.fileKind` | FileManager.fileExists 호출이 SwiftUI body 계산 시 메인 스레드에서 발생 |

---

## 10. 설계 패턴

| 패턴 | 적용 위치 | 선택 근거 |
|------|------|------|
| MVVM + Coordinator | ViewController / ViewModel / Coordinator | VC를 화면 전환에서 분리, 테스트 가능 ViewModel |
| Factory (Interface-Impl) | BookShelfFeatureFactory | 외부 모듈이 내부 구현에 의존하지 않도록 |
| Assembly (Swinject) | BookShelfFeatureAssembly | DI 등록 로직을 모듈 경계 안에 캡슐화 |
| DiffableDataSource | BookShelfViewController+CollectionView | 자동 diff 애니메이션, 섹션 타입이 Hashable |
| Actor (캐시) | CoverImageProvider, ThumbnailCache | Swift 6 데이터 경합 없는 공유 캐시 |
| UIHostingConfiguration | Cell/Header | UIKit CollectionView에서 SwiftUI 뷰 혼용 |
| inFlight dedup | CoverImageProvider, ThumbnailCache | 동일 path의 중복 요청 방지 |

---

## 11. 코드 스타일 체크리스트

| 항목 | 상태 |
|------|------|
| 2-space indent | O |
| 120 char max | O |
| `// MARK: -` 주요 섹션 | O |
| Protocol conformance separate extension | O (CollectionView, ContextMenu 분리) |
| `@available(*, unavailable) required init?(coder:)` | O |
| ViewControllerLifecycle (setupUI/setupBindings/setupData) | 부분 (setupBindings 대신 bindViewModel 사용) |
| Extension per feature (VC+Menu, VC+CollectionView 등) | O |
| Alphabetical imports | O |
| DI over singleton | 부분 (CoverImageProvider.shared는 싱글톤 actor) |
| `nonisolated init` for non-MainActor factory | O |
