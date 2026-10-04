//
//  StoryWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation
import Combine

class StoryWorker: StoryWorkerProtocol {
    
    private let storyRepository = StoryRepository()
    private let authRepository = AuthRepository()

    /// Used when the language list cannot be read; the ids the locale service
    /// lists for Impulse today, most widely filled first.
    private static let defaultFallbackLocales = ["en", "ru"]

    /// How long the language list may take before the defaults are used; the
    /// stories must not wait on it forever.
    private static let languagesTimeout: TimeInterval = 4
    
    func getStories() -> AnyPublisher<[Story], MimoError> {
        Deferred {
            Future<[Story], MimoError> { promise in
                self.storyRepository.getStories { result in
                    switch result {
                    case .success(let data):
                        let stories = data.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) })

                        guard stories.contains(where: \.isMissingImages) else {
                            return promise(.success(stories))
                        }

                        // The admin uploads a page's logo, background and texts
                        // per language; a story filled in for one language
                        // arrives as an empty shell in every other. The content
                        // is borrowed from a language that has it rather than
                        // showing a blank story.
                        self.fallbackLocales { locales in
                            self.fillMissingContent(in: stories, trying: locales) { promise(.success($0)) }
                        }
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Every language the locale service knows except the rider's, English
    /// first. Falls back to the defaults when the list fails or does not
    /// answer in time (this repository's `getLanguages` never calls back on a
    /// non-200 response).
    private func fallbackLocales(completion: @escaping ([String]) -> Void) {
        let current = StoryAPI.riderLocale
        let lock = NSLock()
        var answered = false

        func finish(_ ids: [String]) {
            lock.lock()
            let first = !answered
            answered = true
            lock.unlock()
            guard first else { return }

            let ordered = ids.filter { $0 == "en" } + ids.filter { $0 != "en" }
            completion(ordered.filter { $0 != current })
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + Self.languagesTimeout) {
            finish(Self.defaultFallbackLocales)
        }

        authRepository.getLanguages { result in
            var ids = Self.defaultFallbackLocales
            if case .success(let languages) = result {
                let listed = languages.compactMap(\.id).filter { !$0.isEmpty }
                if !listed.isEmpty { ids = listed }
            }
            finish(ids)
        }
    }

    /// One request per language, stopping as soon as nothing is missing. A
    /// language that fails to load is skipped; whatever could not be filled
    /// stays empty, exactly as before.
    private func fillMissingContent(in stories: [Story], trying locales: [String], completion: @escaping ([Story]) -> Void) {
        guard let locale = locales.first, stories.contains(where: \.isMissingImages) else {
            return completion(stories)
        }

        storyRepository.getStories(locale: locale) { result in
            var filled = stories

            if case .success(let others) = result {
                filled = stories.map { story in
                    guard story.isMissingImages, let other = others.first(where: { $0.id == story.id }) else { return story }
                    return story.fillingMissingImages(from: other)
                }
            }

            self.fillMissingContent(in: filled, trying: Array(locales.dropFirst()), completion: completion)
        }
    }
    
    func like(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.storyRepository.likeStory(id: id) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func setOptions(id: String, pageNumber: Int, options: [String]) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.storyRepository.setOptions(id: id, pageNumber: pageNumber, options: options) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
