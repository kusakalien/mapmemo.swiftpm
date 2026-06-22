import Foundation
import SwiftData

/// お店の「ブランド」単位のメモを表す永続化モデル。
///
/// `storeName` には「ローソン」「セブン-イレブン」などのブランド名（キーワード）を入れる。
/// 地図上のお店の名前がこのキーワードを含んでいれば、同じメモが表示される。
/// これにより「ローソンにメモすると全国のローソンに反映される」という挙動を実現する。
///
/// 例: storeName = "ローソン", memo = "三井住友カードのタッチ決済で最大7%還元"
@Model
final class StoreMemo {
    /// ブランド名（マッチング用キーワード）
    var storeName: String
    /// メモ本文（例: どの決済方法が一番お得か）
    var memo: String
    /// 最終更新日時
    var updatedAt: Date

    init(storeName: String, memo: String, updatedAt: Date = .now) {
        self.storeName = storeName
        self.memo = memo
        self.updatedAt = updatedAt
    }

    /// 地図上のお店の名前 `storeName` がこのメモのブランド名に該当するか判定する。
    ///
    /// どちらかがもう一方を含んでいればマッチとみなす（大文字小文字は無視）。
    /// 例: メモのブランド名「ローソン」は、お店「ローソン 渋谷駅前店」にマッチする。
    func matches(storeName: String) -> Bool {
        let target = storeName.lowercased()
        let keyword = self.storeName.lowercased()
        guard !keyword.isEmpty, !target.isEmpty else { return false }
        return target.contains(keyword) || keyword.contains(target)
    }
}
