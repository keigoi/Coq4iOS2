//
//  DetailViewController.swift
//  Coq4iOS
//
//  Created by 後藤宗一朗 on 2018/11/05.
//  Copyright © 2018年 後藤宗一朗. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        startCoq()
        readStdout({(msg:String?) -> Void in
            fputs(msg, stderr)
        });
//        let goalAreaController = childViewControllers[0] as! GoalAreaViewController
//        eval("Theorem modus_ponens: forall (A B: Prop), (A -> B) -> A -> B.", {(res:Bool, ans:String?) -> Void in
//            fputs(ans, stderr);
//            goalAreaController.textView.text = ans!
//            self.scriptArea.text = ans
//        });
//        eval("intro .", {(res:Bool, ans:String?) -> Void in
//            fputs(ans, stderr);
//            goalAreaController.textView.text = ans!
//            self.scriptArea.text = ans
//        });
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            configureView()
        }
    }



    @IBOutlet weak var goalArea: UIView!

    @IBOutlet weak var scriptArea: UITextView!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var runText: UITextField!
    
    var textFieldString = ""
    
    @IBAction func runAction(_ sender: Any) {
        // TextField から文字を取得
        textFieldString = runText.text!
        //NSLog(textFieldString)
        scriptArea.insertText(textFieldString + "\n")
        setViewController(str: textFieldString)
        // TextField の中身をクリア
        runText.text = ""
    }
    
    func setViewController(str: String){
        // 親から Container View への受け渡し
        let goalAreaController = childViewControllers[0] as! GoalAreaViewController
        eval(str, {(res:Bool, ans:String?) -> Void in
            fputs(ans, stderr);
            goalAreaController.textView.text = ans!
        });

    }

    
}

