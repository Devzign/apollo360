import CoreText
import Foundation

@MainActor enum FontRegistrar {
    private static let fontFolders = [
        "font/SpaceGrotesk",
        "font/Inter-font"
    ]


    static func registerFonts() {
        fontFolders.forEach(registerFonts(in:))
    }

    private static func registerFonts(in subdirectory: String) {
        guard let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: subdirectory) else {
            return
        }

        fontURLs.forEach(registerFont(at:))
    }

    private static func registerFont(at url: URL) {
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }
}
