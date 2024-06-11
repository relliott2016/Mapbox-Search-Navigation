//
//  BaseViewController.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-05.
//

import UIKit

struct ExampleSection {
    let title: String
    let examples: [Example]
}

struct Example {
    let title: String
    let screenType: ExampleController.Type
}

protocol ExampleController: UIViewController {}

