import XCTest
import UIKit

@MainActor
private enum SnapshotHelper {
    static var app: XCUIApplication?
    static var cacheDirectory: URL?

    static var screenshotsDirectory: URL? {
        cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    static func setup(_ app: XCUIApplication) {
        self.app = app
        cacheDirectory = makeCacheDirectory()
        configureLanguage(for: app)
        configureLocale(for: app)
        configureLaunchArguments(for: app)
    }

    static func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval) {
        if timeout > 0 {
            waitForNetworkActivityToSettle(timeout: timeout)
        }

        NSLog("snapshot: \(name)")
        sleep(1)

        guard let screenshotsDirectory else {
            XCTFail("Screenshot output directory is unavailable")
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: screenshotsDirectory,
                withIntermediateDirectories: true
            )
            let screenshot = XCUIScreen.main.screenshot()
            let image = normalizedImage(screenshot.image)
            let simulatorName = normalizedSimulatorName()
            let url = screenshotsDirectory.appendingPathComponent("\(simulatorName)-\(name).png")
            guard !FileManager.default.fileExists(atPath: url.path) else {
                XCTFail("Refusing to overwrite duplicate screenshot output: \(url.lastPathComponent)")
                return
            }
            guard let data = image.pngData() else {
                XCTFail("Could not encode screenshot \(name) as PNG")
                return
            }
            try data.write(to: url, options: .atomic)
        } catch {
            XCTFail("Could not write screenshot \(name): \(error.localizedDescription)")
        }
    }

    private static func makeCacheDirectory() -> URL? {
        guard let simulatorHostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else {
            return nil
        }
        return URL(fileURLWithPath: simulatorHostHome)
            .appendingPathComponent("Library/Caches/tools.fastlane", isDirectory: true)
    }

    private static func configureLanguage(for app: XCUIApplication) {
        guard let language = readCacheValue("language.txt"), !language.isEmpty else { return }
        app.launchArguments += ["-AppleLanguages", "(\(language))"]
    }

    private static func configureLocale(for app: XCUIApplication) {
        guard let locale = readCacheValue("locale.txt"), !locale.isEmpty else { return }
        app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
    }

    private static func configureLaunchArguments(for app: XCUIApplication) {
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]
        guard let rawArguments = readCacheValue("snapshot-launch_arguments.txt"), !rawArguments.isEmpty else {
            return
        }

        do {
            let expression = try NSRegularExpression(pattern: #"(".+?"|\S+)"#)
            let range = NSRange(rawArguments.startIndex..., in: rawArguments)
            app.launchArguments += expression.matches(in: rawArguments, range: range).compactMap { match in
                Range(match.range, in: rawArguments).map { String(rawArguments[$0]) }
            }
        } catch {
            XCTFail("Could not parse Fastlane snapshot launch arguments: \(error.localizedDescription)")
        }
    }

    private static func readCacheValue(_ fileName: String) -> String? {
        guard let cacheDirectory else { return nil }
        let url = cacheDirectory.appendingPathComponent(fileName)
        return try? String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func waitForNetworkActivityToSettle(timeout: TimeInterval) {
        guard let app else { return }
        let spinner = app.activityIndicators.firstMatch
        if spinner.exists {
            XCTAssertTrue(
                spinner.waitForNonExistence(timeout: timeout),
                "Timed out waiting for the screenshot loading indicator to disappear"
            )
        }
    }

    private static func normalizedImage(_ image: UIImage) -> UIImage {
        guard XCUIDevice.shared.orientation.isLandscape else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func normalizedSimulatorName() -> String {
        let rawName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Simulator"
        return rawName.replacingOccurrences(
            of: #"Clone [0-9]+ of "#,
            with: "",
            options: .regularExpression
        )
    }
}

@MainActor
func setupSnapshot(_ app: XCUIApplication) {
    SnapshotHelper.setup(app)
}

@MainActor
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    SnapshotHelper.snapshot(name, timeWaitingForIdle: timeout)
}

// HackersSnapshotHelperVersion [1.0, based on Fastlane SnapshotHelper 1.30]
// SnapshotHelperVersion [1.30]
