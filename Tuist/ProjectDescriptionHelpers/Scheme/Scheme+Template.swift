import ProjectDescription

extension Scheme {
  static func makeScheme(target: ConfigurationName, name: String, includeTests: Bool = true) -> Scheme {
    let testAction: TestAction? = includeTests ? .targets(
      ["\(name)Tests"],
      configuration: target,
      options: .options(coverage: true, codeCoverageTargets: ["\(name)"])
    ) : nil
    return Scheme.scheme(
      name: name,
      shared: true,
      buildAction: .buildAction(targets: ["\(name)"]),
      testAction: testAction,
      runAction: .runAction(configuration: target),
      archiveAction: .archiveAction(configuration: target),
      profileAction: .profileAction(configuration: target),
      analyzeAction: .analyzeAction(configuration: target)
    )
  }

  static func makeDemoScheme(target: ConfigurationName, name: String, includeTests: Bool = true) -> Scheme {
    let testAction: TestAction? = includeTests ? .targets(
      ["\(name)Tests"],
      configuration: target,
      options: .options(coverage: true, codeCoverageTargets: ["\(name)Demo"])
    ) : nil
    return Scheme.scheme(
      name: "\(name)Demo",
      shared: true,
      buildAction: .buildAction(targets: ["\(name)Demo"]),
      testAction: testAction,
      runAction: .runAction(configuration: target),
      archiveAction: .archiveAction(configuration: target),
      profileAction: .profileAction(configuration: target),
      analyzeAction: .analyzeAction(configuration: target)
    )
  }
}
