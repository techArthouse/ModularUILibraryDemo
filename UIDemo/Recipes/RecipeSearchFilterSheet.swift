//
//  RecipeSearchFilterSheet.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/23/25.
//

import SwiftUI

struct RecipeSearchFilterSheet: View {
    var model: SearchViewModel
    var selectedCuisine: String?
    var onSelect: (String) -> Void
    var onReset: () -> Void

    @State private var query: String = ""
    
    var filteredCategories: [String] {
        if query.isEmpty { return model.categories }
        return model.categories.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search cuisine", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Category List
            ScrollViewReader { proxy in
                List {
                    ForEach(filteredCategories, id: \.self) { category in
                        Button {
                            withAnimation {
                                onSelect(category)
                            }
                        } label: {
                            HStack {
                                Text(category)
                                Spacer()
                                if category == selectedCuisine {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .id(category)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    if let selected = selectedCuisine {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo(selected, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Button("Reset") {
                onReset()
            }
            .foregroundColor(.red)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: [.bottom])
    }
}
