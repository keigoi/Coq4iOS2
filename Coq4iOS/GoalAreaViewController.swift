//
//  GoalAreaViewController.swift
//  Coq4iOS
//
//  Created by 後藤宗一朗 on 2019/01/29.
//  Copyright © 2019年 後藤宗一朗. All rights reserved.
//

import UIKit

class GoalAreaViewController: UIViewController {
    var runText: String?
    var evalAns: String?
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBOutlet weak var dropZone: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dragLabel: UILabel!
    @IBOutlet weak var intro: UIButton!
    @IBOutlet var pan: UIPanGestureRecognizer!
    
    
    
    @IBAction func introButton(_ sender: Any) {
        // 本来は親で値を受け渡した段階で textView を更新したいがうまく動作しないため、ボタンで更新するようにしている
        // 現在 intro 操作は親クラスで処理している。
//        eval("intros.", {(res:Bool, ans:String?) -> Void in
//            fputs(ans, stderr);
//            self.textView.text = ans
//        })
        self.textView.text = self.evalAns //ans
    }
    
    
    @IBAction func panGes(_ sender: UIPanGestureRecognizer) {
        let state = sender.state
        if state == .began {
            // タップ開始座標
            let tapLocation = sender.location(in: textView)
            // 行の場所
            let position = textView.closestPosition(to: tapLocation)
            if position != nil {
                // 範囲選択
                let range = textView.tokenizer.rangeEnclosingPosition(position!, with: UITextGranularity.line, inDirection: 1)
                if range != nil
                {
                    // 抽出
                    let word = textView.text(in: range!)
                    // 判定
                    if ((word?.range(of: ":")) != nil) {
                        let array = word?.components(separatedBy: ":")
                        // label の開始位置の中心座標
                        let startPoint = sender.location(in: self.view)
                        dragLabel.center = startPoint
                        dragLabel.text = (array?.first)
                        // ラベルを可視化
                        self.dragLabel.isHidden = false
                        
                    } else {
                        sender.isEnabled = false
                        sender.isEnabled = true
                    }
                }
            }
            
        }
        // ドラッグ中
        if state == .changed {
            //追従させる
            dragLabel.center = sender.location(in: self.view)
        }
        
        if state == .ended {
            let dropZoneRect = dropZone.frame
            // dropZone 内なら実行
            if dropZoneRect.contains(dragLabel.center) {
                // apply 実行
                eval("apply \(dragLabel.text!) .", {(res:Bool, ans:String?) -> Void in
                    fputs(ans, stderr);
                    self.textView.text = ans
                    // Container View から親への受け渡し
                    let detailViewController = self.parent as! DetailViewController
                    detailViewController.scriptArea.insertText("apply \(self.dragLabel.text!) ." + "\n")
                })
            }
            self.dragLabel.isHidden = true
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
