//
//  StoryViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.12.23.
//

import Foundation
import Combine

class StoryViewModel: MimoBaseViewModel, ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: StoryWorkerProtocol
    
    @Published var selectedOptions: [String: [String]] = [:]
    @Published var likedStories: [String] = []
    
    var stories: CurrentValueSubject<[Story], Never> = .init([])
    @Published var showStory: Bool = false
    @Published var currentStory: String = "" {
        didSet {
            
        }
    }
    
    init(worker: StoryWorkerProtocol) {
        self.worker = worker
    }
    
    func getStories() {
        worker.getStories()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] stories in
                self?.stories.send(stories)
                self?.likedStories = stories.filter({ $0.like }).map({ $0.id })
                stories.forEach { story in
                    self?.selectedOptions[story.id] = story.pages.compactMap({ $0.selectedOptions }).reduce([], +)
                }
            }
            .store(in: &cancellables)
    }
    
    func like() {
        worker.like(id: currentStory)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] in
                guard let self else { return }
                
                if self.likedStories.contains(self.currentStory) {
                    self.likedStories.removeAll(where: { $0 == self.currentStory })
                } else {
                    self.likedStories.append(self.currentStory)
                }
            }
            .store(in: &cancellables)
    }
    
    func isLiked() -> Bool {
        return likedStories.contains(currentStory)
    }
    
    func didSelect(option: String, pageNumber: Int) {
        var options = selectedOptions[currentStory] ?? []
        
        if options.contains(where: { $0 == option }) {
            options.removeAll(where: { $0 == option })
        } else {
            options.append(option)
        }
        
        worker.setOptions(id: currentStory, pageNumber: pageNumber, options: options)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {_ in}) { [weak self] _ in
                guard let self else { return }
                
                self.selectedOptions[self.currentStory] = options
            }
            .store(in: &cancellables)
    }
    
    func isOptionSelected(option: String) -> Bool {
        let options = selectedOptions[currentStory] ?? []
        return options.contains(where: { $0 == option })
    }
}
