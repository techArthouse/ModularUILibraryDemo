//
//  RecipeDetailView.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/12/25.
//

import SwiftUI
import UIKit
import ModularUILibrary
import SafariServices

struct RecipeDetailView: View {
    @StateObject private var vm: RecipeRowViewModel
//    let onToggleFavorite: () -> Void
//    let onSubmitNote: (String) -> Void
//    @State private var image: Image?
    @State private var source: URLType? = nil
    @State private var isLoading: Bool = false
    @State private var isAddingNote = false
    @State private var newNoteText = ""
//    @State private var isDisabled: Bool
    
    init(recipeRowVM: RecipeRowViewModel) {
        print("recipedia 1-1")
        self._vm = StateObject(wrappedValue: recipeRowVM)
    }

    enum URLType: Identifiable {
        public var id: URL {
            switch self {
            case .video(let url), .webPage(let url):
                    return url
            }
        }
        
        case video(URL)
        case webPage(URL)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: — Title
                Text(vm.title)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.vertical)
                
                // MARK: — Image + Cuisine + favorite
//                VStack {
                ImageCard(image: vm.image, size: nil, title: vm.title, description: vm.description)
                        .overlay {
                            if !vm.isDisabledBinding.wrappedValue {
                                HStack(alignment: .top) {
                                    Spacer()
                                    VStack {
                                        ToggleIconButton(
                                            iconOn: .system("star.fill"),
                                            iconOff: .system("star"),
                                            isDisabled: vm.isDisabledBinding,
                                            isSelected: vm.isFavoriteBinding) {
                                                withAnimation {
                                                    vm.toggleFavorite()
                                                }
                                            }
                                            .asStandardIconButtonStyle(withColor: .yellow)
                                            .accessibilityLabel(Text("ToggleIconButton: \(vm.accessibilityId)"))
                                            .padding(.trailing)
                                            .padding(.top)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .task {
                            await vm.load()
                        }
//                }
                        .onDisabled(isDisabled: vm.isDisabledBinding)
                
                // MARK: — Buttons
                VStack(spacing: 12) {
                    CTAButtonStack(.vertical()) {
                        if let url = vm.videoURL {
                            CTAButton(title: "Watch Video", icon: .system("video.fill")) {
                                source = .video(url)
                            }.asPrimaryButton(padding: .stacked)
                        } else {
                            CTAButton(title: "Video Unavailable", isDisabled: .constant(true), icon: .system("video.fill")) {
                            }.asPrimaryButton(padding: .stacked)
                        }
                        if let sourceURL = vm.sourceURL {
                            CTAButton(title: "View Full Recipe", icon: .system("safari.fill")) {
                                source = .webPage(sourceURL)
                            }.asSecondaryButton(padding: .stacked)
                        } else {
                            
                            CTAButton(title: "Source Unavailable", isDisabled: .constant(true), icon: .system("safari.fill")) {
                            }.asSecondaryButton(padding: .stacked)
                        }
                    }
                }
                
                // MARK: — Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    VStack {
                        Text("Notes")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 5)
                    .background( isAddingNote ? .white : .yellow.opacity(0.4))
                    
                    ForEach(vm.notes) { note in
                        Text(note.text)
                            .padding(.leading, 10)
                            .cornerRadius(8)
                            .transition(.opacity)
                        Divider()
                            .frame(height: 1)
                            .background(.black.opacity(0.5))
                    }
                    
                    if isAddingNote {
                        TextField("Write your note...", text: $newNoteText)
                            .padding(10)
                            .background(Color.yellow.opacity(0.4))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.6)))
                            .transition(.move(edge: .bottom).combined(with: .opacity)).onSubmit {
                                if !newNoteText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    vm.addNote(newNoteText.trimmingCharacters(in: .whitespaces))
                                    withAnimation {
                                        isAddingNote = false
                                        newNoteText = ""
                                    }
                                }
                            }
                    }
                    else {
                        if vm.isRecipFavorited {
                            CTAButton(title: "Add Note") {
                                withAnimation {
                                    isAddingNote = true
                                }
                            }
                            .asBorderlessButton(padding: .manualPadding)
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            CTAButton(title: "Add Recipe to Favorites to Add Notes") {
                                withAnimation {
                                    vm.toggleFavorite()
                                }
                            }
                            .asBorderlessButton(padding: .manualPadding)
                            .padding(.horizontal, 10)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -1) // lifts up
                )
                .padding()
                .onDisabled(isDisabled: vm.isDisabledBinding)
            }
        }
        .navigationTitle(vm.title)
        .navigationBarTitleDisplayMode(.inline)
        // YouTube sheet
        .sheet(item: $source) { source in
            VStack {
                switch source {
                case .video(let url):
                    if let videoID = extractStringAfterV(from: url.absoluteString) {
                        // MARK: — Title
                        Text(vm.title)
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.top)
                        YouTubePlayerView(videoID: videoID, isLoading: $isLoading)
                        .scaledToFit()
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.25))
                                }
                            }
                        Spacer()
                    } else {
                        Text("Video unavailable")
                    }
                    
                case .webPage(let url):
                    SafariView(url: url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    

    // Simple SafariView wrapper
    struct SafariView: UIViewControllerRepresentable {
        typealias UIViewControllerType = SFSafariViewController
        let url: URL
        
        func makeUIViewController(context: Context) -> SFSafariViewController {
            SFSafariViewController(url: url)
        }
        
        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        }
        
        
    }

    // Regex helper as before
    func extractStringAfterV(from inputString: String) -> String? {
        let regex = /v=(.*)/
        if let match = inputString.firstMatch(of: regex) {
            return String(match.output.1)
        }
        return nil
    }
}

#if DEBUG
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        //    let memoryStore = MockRecipeMemoryDataSource()
        let recipe = Recipe.recipePreview(using: .good).first
        var recipeItem = RecipeItem(recipe!)
        
        let recipeStore = RecipeStore(memoryStore: MockRecipeMemoryDataSource(), fetchCache: MockFetchCache())
        recipeStore.loadRecipes(recipes: [recipe!])
        
        return RecipeDetailView(recipeRowVM: RecipeRowViewModel(recipeId: recipe!.id, recipeStore: recipeStore))
        //    RecipeDetailView(item: recipeItem, onToggleFavorite: {
        //        print(recipeItem.isFavorite)
        //        if !recipeItem.isFavorite {
        //        }
        //    }, onSubmitNote: { note in
        //        recipeItem.notes.append(RecipeNote(id: UUID(), text: note, date: Date()))
        //    })
//            .task {
//                
//                do {
//                    // Pick the correct folder name: "DevelopmentFetchImageCache" "FetchImageCache"
//#if DEBUG
//                    try FetchCache.shared.openCacheDirectoryWithPath(path: "DevelopmentFetchImageCache")
//#else
//                    try vm.startCache(path: "FetchImageCache")
//#endif
//                } catch {
//                    return
//                    // failed to start cache. what do i do here? is vm.items = [] appropriate?
//                }
//            }
            .environmentObject(ThemeManager())
        //        .onAppear {
        //            recipeItem.isFavorite = true
        //            recipeItem.notes.append( contentsOf: [RecipeNote(id: UUID(), text: "first note", date: Date()), RecipeNote(id: UUID(), text: "second note", date: Date())])
        //        }
    }
}
#endif
