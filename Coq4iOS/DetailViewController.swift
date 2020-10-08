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
        // fputs(readStdout(), stderr);
        readStdout({(msg:String?) -> Void in
            fputs(msg, stderr)
//            eval("Theorem id:forall a,a -> a.", {(res:Bool, msg:String?) -> Void in
//                fputs(msg, stderr);
//            })
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
    
    
    @IBAction func runAction(_ sender: Any) {
        evalPhrase()
    }
    
    @IBAction func backAction(_ sender: Any) {
        back();
        self.refreshTextarea()
    }
    
    func evalPhrase(){
        let whole = scriptArea.text!
        let rest = String(whole[String.Index.init(encodedOffset: lastPos())...])
        
        nextPhraseRange(rest, {(range_:NSRange) -> Void in
            if (range_.location < 0) {
                return;
            }
            
            let range = NSRange(location:0, length:range_.length + range_.location)
            guard let realRange = Range(range, in:rest) else {
                return
            }
            let str = String(rest[realRange])
            
            eval(str, {(success:Bool, ans:String?) -> Void in
                fputs(ans, stderr);
                let goalAreaController = self.childViewControllers[0] as! GoalAreaViewController
                goalAreaController.textView.text = ans!
                if (success) {
                    self.refreshTextarea()
                }
            });
        })
    }
    
    func refreshTextarea() {
        let str = NSMutableAttributedString(string: self.scriptArea.text)
        
        // coloring the evaluated range
        let evaluatedRange = NSRange(location:0, length: lastPos())
        str.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.blue, range: evaluatedRange)
                
        let font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        str.addAttribute(NSAttributedStringKey.font, value: font, range: NSRange(location:0, length:str.length))
        self.scriptArea.attributedText = str
        
    }
    

    
}

