//
//  UserViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/07.
//

import UIKit

/// ユーザー登録画面
class UserViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    /// テーブルビューを表示するためのIBOutlet接続
    @IBOutlet private weak var userTableView: UITableView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureTableView()
    }
    
    // MARK: - IBActions
    
    /// 追加ボタンをタップした
    @IBAction private func userAddButtonTapped(_ sender: Any) {
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureTableView() {
        userTableView.dataSource = self
        userTableView.delegate = self
        // カスタムセル
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        userTableView.register(nib, forCellReuseIdentifier: "Cell")
        userTableView.rowHeight = 78
    }
}
// MARK: - UITableViewDataSource

extension UserViewController: UITableViewDataSource {
    /// データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 // 仮のデータ数
    }
    
    /// 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)as! UserTableViewCell
        // ここにセルに渡す処理を書く
        return cell
    }
}

// MARK: - UITableViewDelegate

extension UserViewController: UITableViewDelegate {
    /// セルをタップされた時のメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルタップ時の処理を追加
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


