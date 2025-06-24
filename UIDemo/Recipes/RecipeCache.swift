//
//  RecipeCache.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 6/23/25.
//

protocol RecipeCacheProtocol {
    func openCacheDirectoryWithPath(path: String) throws(FetchCacheError)
    func refresh() async
}
