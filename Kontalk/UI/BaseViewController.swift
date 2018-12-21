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

class BaseViewController: UIViewController, UINavigationBarDelegate {
    
    override func viewDidLoad() {
        UIApplication.shared.statusBarView?.backgroundColor = .primaryColor
        
        let navigationBar = KontalkNavigationBar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        navigationBar.barTintColor = .primaryColor
        
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        
        self.view.addSubview(navigationBar)
        
        let navItem = UINavigationItem()
        navItem.title = "Kontalk"
        
        navigationBar.items = [navItem]
        
        
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        if #available(iOS 11, *) {
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
    }
}

extension UIApplication {
    
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
    
}
