//
//  StoryRepository.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation

struct StoryRepository {
    
    private let network = SessionNetwork()
    
    func getStories(completion: @escaping (Result<[Story], NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: StoryAPI.getStories)) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[Story]>.self, from: data)
                    
                    if response.statusCode == 200, let content = response.content {
                        completion(.success(content))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func likeStory(id: String, completion: @escaping (Result<Void, NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: StoryAPI.like(id: id))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[Story]>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
    
    func setOptions(id: String, pageNumber: Int, options: [String], completion: @escaping (Result<Void, NetworkError>) -> ()) {
        network.request(with: URLBuilder(from: StoryAPI.options(id: id, pageNumber: pageNumber, options: options))) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BaseResponseModel<[Story]>.self, from: data)
                    
                    if response.statusCode == 200 {
                        completion(.success(()))
                    } else {
                        completion(.failure(.responseError(response.message)))
                    }
                } catch {
                    completion(.failure(.responseError(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(.responseError(error.localizedDescription)))
            }
        }
    }
}
