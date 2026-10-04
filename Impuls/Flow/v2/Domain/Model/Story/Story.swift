//
//  Story.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation

struct Story: Decodable, Identifiable {
    let id: String
    let name: String
    var like: Bool
    var order: Int?
    var pages: [StoryPage]
}

/// One page of a story (accounts docs/mobile-api.md, GET /api/stories,
/// `StoryPageDto`). Story content is stored per language on the backend, so a
/// page answered for a language the admin did not fill in arrives with texts
/// and images missing. Decoding tolerates that - a missing text is empty, a
/// missing or malformed image is nil - because one incomplete page used to
/// fail the whole list and leave home without any stories.
struct StoryPage: Decodable {
    let number: Int
    var content: String
    var options: [String]
    let selectedOptions: [String]
    var title: String
    let type: StoryType
    /// `ImageDto` rather than `ImageObj`: it prefers the backend's direct `url`
    /// when one is sent and falls back to the `node` + `id` repository form.
    var background: ImageDto?
    /// `FileData.type` of the background, as sent. The background can be a
    /// video; see `backgroundKind` in StoryView.swift.
    var backgroundType: String?
    var logo: ImageDto?
    var url: String?
    var urlButtonName: String?

    private enum CodingKeys: String, CodingKey {
        case number, content, options, selectedOptions, title, type, background, logo, url, urlButtonName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        number = (try? c.decodeIfPresent(Int.self, forKey: .number)) ?? 0
        type = (try? c.decodeIfPresent(StoryType.self, forKey: .type)) ?? .link
        content = (try? c.decodeIfPresent(String.self, forKey: .content)) ?? ""
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        options = (try? c.decodeIfPresent([String].self, forKey: .options)) ?? []
        selectedOptions = (try? c.decodeIfPresent([String].self, forKey: .selectedOptions)) ?? []
        background = (try? c.decodeIfPresent(ImageDto.self, forKey: .background))?.usable
        backgroundType = background == nil
            ? nil
            : (try? c.decodeIfPresent(StoryFileType.self, forKey: .background))?.type
        logo = (try? c.decodeIfPresent(ImageDto.self, forKey: .logo))?.usable
        url = try? c.decodeIfPresent(String.self, forKey: .url)
        urlButtonName = try? c.decodeIfPresent(String.self, forKey: .urlButtonName)
    }
}

/// The one field of `FileData` that `ImageDto` does not carry.
private struct StoryFileType: Decodable {
    let type: String?
}

extension ImageDto {
    /// Self when it points at a file (a direct `url`, or `node` + `id`), nil
    /// when the backend sent an empty shell.
    var usable: ImageDto? {
        if url != nil { return self }
        if let id, !id.isEmpty, let node, !node.isEmpty { return self }
        return nil
    }
}

extension Story {

    /// What the screens actually draw: every page's background, and the first
    /// page's logo (the thumbnail on home). Later pages without a logo are
    /// normal and do not count as missing.
    var isMissingImages: Bool {
        pages.contains { $0.background == nil } || (pages.first.map { $0.logo == nil } ?? false)
    }

    /// Fills what this story lacks from the same story answered for another
    /// language, page by page. A page the admin never filled in for the
    /// rider's language arrives as an empty shell - no images, no title, no
    /// text, no link - so the texts and the link are borrowed along with the
    /// images: a story in another language is better than a blank one whose
    /// button goes nowhere. Anything present in the rider's language is kept.
    func fillingMissingImages(from other: Story) -> Story {
        var copy = self

        for index in copy.pages.indices {
            guard let match = other.pages.first(where: { $0.number == copy.pages[index].number }) else { continue }

            if copy.pages[index].background == nil {
                copy.pages[index].background = match.background
                copy.pages[index].backgroundType = match.backgroundType
            }
            if copy.pages[index].logo == nil { copy.pages[index].logo = match.logo }
            if copy.pages[index].title.isEmpty { copy.pages[index].title = match.title }
            if copy.pages[index].content.isEmpty { copy.pages[index].content = match.content }
            if copy.pages[index].options.isEmpty { copy.pages[index].options = match.options }
            if (copy.pages[index].url ?? "").isEmpty { copy.pages[index].url = match.url }
            if (copy.pages[index].urlButtonName ?? "").isEmpty { copy.pages[index].urlButtonName = match.urlButtonName }
        }

        return copy
    }
}

enum StoryType: String, Decodable {
    case link = "LINK"
    case questionnaire = "QUESTIONNAIRE"
}
