//
//  NavViewControllerRepresentable.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-03.
//

import SwiftUI

struct NavViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return NavViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // update the viewcontroller if needed
    }
}

