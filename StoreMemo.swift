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
    /// 「店名がブランド名で始まる（前方一致）」場合にマッチとみなす（大文字小文字・前後の空白は無視）。
    /// 前方一致にすることで、ブランド名を途中に含むだけの別のお店を誤ってマッチさせない。
    ///
    /// 例:
    /// - ブランド名「ローソン」→「ローソン」「ローソン 渋谷駅前店」にマッチ
    /// - ブランド名「ローソン」→「アローソン」にはマッチしない
    func matches(storeName: String) -> Bool {
        let target = Self.normalize(storeName)
        let keyword = Self.normalize(self.storeName)
        guard !keyword.isEmpty, !target.isEmpty else { return false }
        return target.hasPrefix(keyword)
    }

    /// マッチング用に文字列を正規化する（前後の空白除去・小文字化）。
    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
