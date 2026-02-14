import AVFoundation
import Combine
import Logger
import MediaPlayer
import UIKit

// MARK: - ReaderViewController + SpeechKey

@MainActor private var speechSynthesizerKey: UInt8 = 0
@MainActor private var speechDelegateKey: UInt8 = 0
@MainActor private var speechCancellablesKey: UInt8 = 0

// MARK: - ReaderSpeechDelegate

final class ReaderSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
  var onFinished: (() -> Void)?
  var onSpeakRange: ((NSRange) -> Void)?

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    onFinished?()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    onSpeakRange?(characterRange)
  }
}

// MARK: - ReaderViewController + Speech

extension ReaderViewController {
  // MARK: - Associated Properties

  private var speechSynthesizer: AVSpeechSynthesizer {
    get {
      if let existing = objc_getAssociatedObject(self, &speechSynthesizerKey) as? AVSpeechSynthesizer {
        return existing
      }
      let synthesizer = AVSpeechSynthesizer()
      objc_setAssociatedObject(self, &speechSynthesizerKey, synthesizer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return synthesizer
    }
    set { objc_setAssociatedObject(self, &speechSynthesizerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  private var speechDelegate: ReaderSpeechDelegate {
    get {
      if let existing = objc_getAssociatedObject(self, &speechDelegateKey) as? ReaderSpeechDelegate {
        return existing
      }
      let delegate = ReaderSpeechDelegate()
      objc_setAssociatedObject(self, &speechDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return delegate
    }
    set { objc_setAssociatedObject(self, &speechDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  // MARK: - Setup

  func setupSpeech() {
    let delegate = speechDelegate
    speechSynthesizer.delegate = delegate

    delegate.onFinished = { [weak self] in
      guard let self else { return }
      guard viewModel.state.speechState == .speak else { return }
      guard viewModel.canScroll(command: .next) else {
        viewModel.send(.changeSpeechState(.stop))
        return
      }

      viewModel.send(.changeSpeechState(.stop))
      let oldIndex = viewModel.state.currentIndex
      scroll(command: .next, animated: false) { [weak self] in
        guard let self else { return }
        if oldIndex == viewModel.state.currentIndex {
          viewModel.send(.changeSpeechState(.stop))
        } else {
          viewModel.send(.changeSpeechState(.speak))
        }
      }
    }

    delegate.onSpeakRange = { [weak self] range in
      self?.highlightSpeechRange(range)
    }

    setupAudioInterruptionObserver()
    setupSpeechStateBinding()
  }

  // MARK: - Speech State Handling

  private func setupSpeechStateBinding() {
    viewModel.$state
      .map(\.speechState)
      .removeDuplicates()
      .receive(on: RunLoop.main)
      .sink { [weak self] state in
        self?.handleSpeechStateChange(state)
      }
      .store(in: &cancellable)
  }

  private func handleSpeechStateChange(_ state: ReaderSpeechState) {
    switch state {
    case .speak:
      guard !speechSynthesizer.isPaused else {
        try? AVAudioSession.sharedInstance().setActive(true)
        speechSynthesizer.continueSpeaking()
        return
      }
      guard viewModel.canScroll(at: viewModel.state.currentIndex) else { return }
      speakCurrentPage()

    case .pause:
      speechSynthesizer.pauseSpeaking(at: .immediate)
      try? AVAudioSession.sharedInstance().setActive(false)

    case .stop:
      speechSynthesizer.stopSpeaking(at: .immediate)
      try? AVAudioSession.sharedInstance().setActive(false)
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
  }

  private func speakCurrentPage() {
    // Subclasses or delegates should provide the attributed string to speak
    // For now, this is a placeholder for the text content
    guard viewModel.state.options.contentType == .text else { return }
    guard let contentView = currentDisplayContentView() else { return }
    guard let attributedString = contentView.getTextView().attributedString else {
      Log.error("No text to speak")
      return
    }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      Log.error("AVAudioSession error: \(error)")
      return
    }

    let utterance = AVSpeechUtterance(attributedString: attributedString)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    speechSynthesizer.speak(utterance)
    setupRemoteCommandCenter()
  }

  // MARK: - Remote Command Center

  private func setupRemoteCommandCenter() {
    let command = MPRemoteCommandCenter.shared()
    command.playCommand.isEnabled = true
    command.pauseCommand.isEnabled = true
    command.togglePlayPauseCommand.isEnabled = true

    command.playCommand.addTarget { [weak self] _ in
      self?.viewModel.send(.changeSpeechState(.speak))
      return .success
    }

    command.pauseCommand.addTarget { [weak self] _ in
      self?.viewModel.send(.changeSpeechState(.pause))
      return .success
    }

    command.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      if viewModel.state.speechState != .speak {
        viewModel.send(.changeSpeechState(.speak))
      } else {
        viewModel.send(.changeSpeechState(.pause))
      }
      return .success
    }
  }

  // MARK: - Audio Interruption

  private func setupAudioInterruptionObserver() {
    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
      .receive(on: RunLoop.main)
      .sink { [weak self] notification in
        guard let self else { return }
        guard speechSynthesizer.isSpeaking else { return }
        guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: rawValue) else { return }

        switch interruptionType {
        case .began:
          speechSynthesizer.pauseSpeaking(at: .immediate)
          try? AVAudioSession.sharedInstance().setActive(false)
        default:
          speechSynthesizer.continueSpeaking()
          try? AVAudioSession.sharedInstance().setActive(true)
        }
      }
      .store(in: &cancellable)
  }

  // MARK: - Highlight

  private func highlightSpeechRange(_ range: NSRange) {
    guard let contentView = currentDisplayContentView() else { return }
    guard viewModel.state.options.contentType == .text else { return }

    guard let attributedString = contentView.getTextView().attributedString else { return }
    let mString = NSMutableAttributedString(attributedString: attributedString)
    let originalRange = NSRange(location: 0, length: mString.length)

    if NSIntersectionRange(originalRange, range).length > 0,
       mString.length > (range.location + range.length) {
      mString.addAttributes(
        [.underlineStyle: NSUnderlineStyle.single.rawValue],
        range: range
      )
      contentView.getTextView().attributedString = mString
    }
  }

  // MARK: - Helper

  func currentDisplayContentView() -> ReaderContentView? {
    let collectionView = collectionView
    let cell = collectionView.cellForItem(at: IndexPath(row: viewModel.state.currentIndex, section: 0)) as? ReaderPageCell
    return cell?.readerContentView
  }

  func stopSpeech() {
    if speechSynthesizer.isSpeaking {
      speechSynthesizer.stopSpeaking(at: .immediate)
    }
  }
}
