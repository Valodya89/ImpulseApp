//
//  SegmentedCapsulePicker.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/3/25.
//

import SwiftUI

protocol SegmentedCapsuleOption: CaseIterable, Identifiable, Equatable {
    var title: String { get }
}

extension SegmentedCapsuleOption {
    var id: Self { self }
}

struct SegmentedCapsulePicker<Option: SegmentedCapsuleOption>: View {
    @Binding var selected: Option
    @State private var hoverIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var optionWidth: CGFloat = 0
    @State private var totalSize: CGSize = .zero
    @State private var isDragging: Bool = false

    let options: [Option]

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white)
                .overlay(
                    Capsule().stroke(Color.grayBackground, lineWidth: 2)
                )

            Capsule()
                .fill(Color.brandYellow)
                .padding(isDragging ? 2 : 0)
                .frame(width: optionWidth, height: totalSize.height)
                .offset(x: dragOffset)
                .gesture(
                    LongPressGesture(minimumDuration: 0.01)
                        .sequenced(before: DragGesture())
                        .onChanged { value in
                            switch value {
                            case .first(true):
                                isDragging = true
                            case .second(true, let drag):
                                let translationWidth = (drag?.translation.width ?? 0) + CGFloat(currentIndex) * optionWidth
                                hoverIndex = Int(round(min(max(0, translationWidth), optionWidth * CGFloat(options.count - 1)) / optionWidth))
                            default:
                                isDragging = false
                            }
                        }
                        .onEnded { value in
                            if case .second(true, let drag?) = value {
                                let predictedEndOffset = drag.translation.width + CGFloat(currentIndex) * optionWidth
                                let newIndex = Int(round(min(max(0, predictedEndOffset), optionWidth * CGFloat(options.count - 1)) / optionWidth))
                                selected = options[newIndex]
                                hoverIndex = newIndex
                            }
                            isDragging = false
                        }
                        .simultaneously(with: TapGesture().onEnded { _ in isDragging = false })
                )
                .animation(.spring(), value: dragOffset)
                .animation(.spring(), value: isDragging)

            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index].title)
                        .frame(width: optionWidth, height: totalSize.height)
                        .foregroundColor(Color.evText9)
                        .font(.system(size: 14, weight: .bold))
                        .contentShape(Capsule())
                        .onTapGesture {
                            selected = options[index]
                            hoverIndex = index
                        }
                        .allowsHitTesting(currentIndex != index)
                }
            }
            .onChange(of: hoverIndex) { i in
                dragOffset = CGFloat(i) * optionWidth
            }
            .onChange(of: selected) { _ in
                hoverIndex = currentIndex
            }
            .frame(width: totalSize.width, alignment: .leading)
        }
        .background(GeometryReader { proxy in Color.clear.onAppear { totalSize = proxy.size } })
        .onChange(of: totalSize) { _ in optionWidth = totalSize.width / CGFloat(options.count) }
        .onAppear { hoverIndex = currentIndex }
        .frame(height: 40)
    }

    private var currentIndex: Int {
        options.firstIndex(of: selected) ?? 0
    }
}
