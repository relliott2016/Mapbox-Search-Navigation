//
//  SearchViewControllerRepresentable.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-05.
//

import SwiftUI

struct SearchViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return SearchViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // update the viewcontroller if needed
    }
}

