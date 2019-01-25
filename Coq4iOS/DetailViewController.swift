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
            self.textView.text = msg
        });
        eval("Theorem id: forall A, A -> A.", {(res:Bool, ans:String?) -> Void in
            fputs(ans, stderr);
            self.textView.text = ans
        });
        eval("Theorem modus_ponens: forall (A B: Prop), (A -> B) -> A -> B.", {(res:Bool, ans:String?) -> Void in
            fputs(ans, stderr);
            self.textView.text = ans
        });
        eval("intros.", {(res:Bool, ans:String?) -> Void in
            fputs(ans, stderr);
            self.textView.text = ans
        })
//        eval("Check fun(X:Set)(x:X) => x.", {(res:Bool, ans:String?) -> Void in
//            fputs(ans, stderr);
//            self.textView.text = ans
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

    
    @IBOutlet weak var dropZone: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var pan: UIPanGestureRecognizer!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var into: UIButton!
    
    @IBAction func introButton(_ sender: Any) {
        eval("intros.", {(res:Bool, ans:String?) -> Void in
            fputs(ans, stderr);
            self.textView.text = ans
        })
    }
    
    
    @IBAction func panGes(_ sender: UIPanGestureRecognizer) {
        var startPoint:CGPoint!
        var endPoint:CGPoint!
        let state = sender.state
        if state == .began {
            // タップ開始座標
            let tapLocation = sender.location(in: textView)
            //print("tapPoint=\(tapLocation)")
            // 行の場所
            let position = textView.closestPosition(to: tapLocation)
            //print("tapPosition=\(position)")
            if position != nil {
                // 範囲選択
                let range = textView.tokenizer.rangeEnclosingPosition(position!, with: UITextGranularity.line, inDirection: 1)
                if range != nil
                {
                    // 抽出
                    let word = textView.text(in: range!)
                    //print("tapped line : \(word)")
                    // 判定
                    if ((word?.range(of: ":")) != nil) {
                        let array = word?.components(separatedBy: ":")
                        //print("tapped word : \(array?.first)")
                        // label の開始位置の中心座標
                        startPoint = sender.location(in: self.view)
                        label2.center = startPoint
                        //print("startPoint=\(startPoint)")
                        label2.text = (array?.first)
                        // ラベルを可視化
                        self.label2.isHidden = false
                        
                    } else {
                        sender.isEnabled = false
                        sender.isEnabled = true
                        // self.label.isHidden = true
                    }
                }
            }
            
        }
        // ドラッグ中
        if state == .changed {
            // 移動距離
            let translation = sender.translation(in: self.view)
            //print("translation=\(translation)")
            //ドラッグした部品の座標に移動量を加算する。
            label2.center = sender.location(in: self.view)
        }
        
        if state == .ended {
            endPoint = sender.view!.center
            //print("lastPoint=\(endPoint)")
            let dropZoneRect = dropZone.frame
            if dropZoneRect.contains(label2.center) {
                //NSLog("drag -> OK")//("drag -> OK")
                eval("apply \(label2.text!) .", {(res:Bool, ans:String?) -> Void in
                    fputs(ans, stderr);
                    self.textView.text = ans
                })
            }else {
                print("drag -> NO")
            }
            self.label2.isHidden = true
        }
        
        
    }
    
    
}

