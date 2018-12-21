//
//  Kontalk iOS client
//  Copyright (C) 2018 Kontalk Devteam <devteam@kontalk.org>
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

@IBDesignable class KontalkUIButton: UIButton {
    
    @IBInspectable var textColor: UIColor = UIColor.white {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
    
    @IBInspectable var buttonBackgroundColor: UIColor = UIColor.primaryColor {
        didSet {
            backgroundColor = buttonBackgroundColor
        }
    }
    
    override init(frame: CGRect) {
       super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    
    override func prepareForInterfaceBuilder() {
        initUI()
    }
    
    func initUI() {
        backgroundColor = UIColor.primaryColor
        setTitleColor(UIColor.white, for: .normal)
        layer.cornerRadius = 24
    }


}
