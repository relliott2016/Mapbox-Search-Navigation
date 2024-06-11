//
//  ContentView.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-03.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
       NavViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
