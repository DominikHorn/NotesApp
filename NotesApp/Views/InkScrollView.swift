//
//  InkScrollView.swift
//  NotesApp
//
//  Created by Dominik Horn on 15.03.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class InkScrollView: UIScrollView {
    override func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        return true
    }
}
