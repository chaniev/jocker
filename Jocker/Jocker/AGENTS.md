# Swift / SwiftUI development rules

## Code structure
- You are an expert iOS developer using Swift and SwiftUI.
- Prefer value types (`struct`) over classes; use protocol-oriented programming.
- Use MVVM architecture with SwiftUI.
- Structure code by `Features/`, `Core/`, `UI/`, `Resources/`.
- Follow Apple Human Interface Guidelines.

## Naming
- Use camelCase for variables/functions and PascalCase for types.
- Use verbs for methods (e.g., `fetchData`).
- Boolean names use `is/has/should` prefixes.
- Use clear, descriptive names following Apple style.

## Swift best practices
- Use strong typing and correct optional handling.
- Use async/await for concurrency.
- Use `Result` for error handling.
- Use `@Published` and `@StateObject` for state management.
- Prefer `let` over `var`.
- Use protocol extensions for shared code.

## UI development
- Prefer SwiftUI; use UIKit only when needed.
- Use SF Symbols for icons.
- Support dark mode and Dynamic Type.
- Use Safe Area and `GeometryReader` appropriately.
- Handle all screen sizes and orientations.
- Implement proper keyboard handling.

## Performance
- Profile with Instruments.
- Lazy-load views and images.
- Optimize network requests.
- Handle background tasks properly.
- Use correct state management and memory practices.

## Data & state
- Use Core Data for complex models.
- Use UserDefaults for preferences.
- Use Combine for reactive code.
- Maintain clean data flow.
- Use proper dependency injection.
- Handle state restoration.

## Security
- Encrypt sensitive data.
- Use Keychain securely.
- Use certificate pinning.
- Use biometric auth when needed.
- Enforce App Transport Security.
- Validate inputs.

## Essential features
- Support deep linking, push notifications, background tasks, localization, error handling, and analytics/logging.

## App Store guidelines
- Provide privacy descriptions and app capability disclosures.
- Handle in-app purchases properly.
- Follow review guidelines and app thinning.
- Use proper code signing.

Follow Apple's documentation for detailed implementation guidance.
