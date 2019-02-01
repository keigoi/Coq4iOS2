//
//  GoalAreaViewController.swift
//  Coq4iOS
//
//  Created by 後藤宗一朗 on 2019/01/29.
//  Copyright © 2019年 後藤宗一朗. All rights reserved.
//

import UIKit

class GoalAreaViewController: UIViewController {
    
    var state: UIGestureRecognizerState? = nil
    var mode = ""
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBOutlet weak var dropZone: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dragLabel: UILabel!
    @IBOutlet var pan: UIPanGestureRecognizer!
    
    
    func beganSwip(_ sender: UIPanGestureRecognizer){
        // タップ開始座標
        let tapLocation = sender.location(in: textView)
        // 行の場所
        let position = textView.closestPosition(to: tapLocation)
        let arrayLine = textView.text.components(separatedBy: "==")
        if position != nil {
            // 範囲選択
            let range = textView.tokenizer.rangeEnclosingPosition(position!, with: UITextGranularity.line, inDirection: 1)
            if range != nil
            {
                // 抽出
                let word = textView.text(in: range!)
                // 判定
                if ((arrayLine[0].range(of: word!)) != nil){
                    if ((word?.range(of: ":")) != nil) {
                        mode = "apply"
                        let array = word?.components(separatedBy: ":")
                        // label の開始位置の中心座標
                        dragLabel.center = sender.location(in: self.view)
                        dragLabel.text = (array?.first)
                        // ラベルを可視化
                        self.dragLabel.isHidden = false
                        
                    } else {
                        sender.isEnabled = false
                        sender.isEnabled = true
                    }
                }else {
                    mode = "intro"
                    // label の開始位置の中心座標
                    dragLabel.center = sender.location(in: self.view)
                    dragLabel.text = ("intro")
                    // ラベルを可視化
                    self.dragLabel.isHidden = false

                }
                
            }
        }
    }
    
    func changedSwip(_ sender: UIPanGestureRecognizer){
        //追従させる
        dragLabel.center = sender.location(in: self.view)
    }
    
    func endedSwip(_ sender: UIPanGestureRecognizer){
        let dropZoneRect = dropZone.frame
        // dropZone 内なら実行
        if dropZoneRect.contains(dragLabel.center) {
            if (mode == "apply"){
                // apply 実行
                eval("apply \(dragLabel.text!) .", {(res:Bool, ans:String?) -> Void in
                    fputs(ans, stderr);
                    self.textView.text = ans
                    // Container View から親への受け渡し
                    let detailViewController = self.parent as! DetailViewController
                    detailViewController.scriptArea.insertText("apply \(self.dragLabel.text!) ." + "\n")
                })
            }else if (mode == "intro"){
                // intro 実行
                eval("intro .", {(res:Bool, ans:String?) -> Void in
                    fputs(ans, stderr);
                    self.textView.text = ans
                    // Container View から親への受け渡し
                    let detailViewController = self.parent as! DetailViewController
                    detailViewController.scriptArea.insertText("intro ." + "\n")
                })
            }
        }
        self.dragLabel.isHidden = true
    }
    @IBAction func panGes(_ sender: UIPanGestureRecognizer) {
        state = sender.state
        if state == .began {
            beganSwip(sender)
        }
        // ドラッグ中
        if state == .changed {
            changedSwip(sender)
        }
        
        if state == .ended {
            endedSwip(sender)
        }
        
        
    }
    
    
    // 実行サンプルなので無視で良い
    //        readStdout({(msg:String?) -> Void in
    //            fputs(msg, stderr)
    //            self.textView.text = msg
    //        });
    //        eval("Theorem id: forall A, A -> A.", {(res:Bool, ans:String?) -> Void in
    //            fputs(ans, stderr);
    //            self.textView.text = ans
    //        });
    //        eval("Theorem modus_ponens: forall (A B: Prop), (A -> B) -> A -> B.", {(res:Bool, ans:String?) -> Void in
    //            fputs(ans, stderr);
    //            self.textView.text = ans
    //        });
    //        eval("Check fun(X:Set)(x:X) => x.", {(res:Bool, ans:String?) -> Void in
    //            fputs(ans, stderr);
    //            self.textView.text = ans
    //        });
}
