import Foundation
import StoreKit
import Observation

/// アプリ内課金（StoreKit 2）を管理するクラス。
///
/// 無料では最大 `freeMemoLimit` 件までメモを登録でき、
/// 非消耗型課金「メモ無制限」を購入すると制限が解除される。
@MainActor
@Observable
final class StoreManager {
    /// 無料で登録できるメモの上限
    static let freeMemoLimit = 5
    /// 「メモ無制限」課金のプロダクト ID（App Store Connect で同じ ID を登録する）
    static let unlimitedProductID = "com.kusakalien.mapmemo.unlimited"

    /// 読み込んだ課金商品
    private(set) var unlimitedProduct: Product?
    /// 無制限が解除されているか
    private(set) var isUnlimitedUnlocked = false
    /// 商品読み込みに失敗した理由（成功時は nil）
    private(set) var loadErrorMessage: String?

    /// 商品読み込みに失敗したか
    var loadFailed: Bool { loadErrorMessage != nil }

    @ObservationIgnored
    private var updatesTask: Task<Void, Never>?

    init() {
        // 購入・返金などのトランザクション更新を監視する
        updatesTask = Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 課金商品を読み込む
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.unlimitedProductID])
            unlimitedProduct = products.first
            if unlimitedProduct == nil {
                // 通信は成功したが、該当 ID の商品が返ってこなかったケース
                loadErrorMessage = """
                課金商品が見つかりませんでした。
                App Store Connect での商品（\(Self.unlimitedProductID)）の登録、\
                および「有料Appの契約」の締結が必要です。Xcode で検証する場合は \
                StoreKit Configuration ファイルを使用してください。
                """
            } else {
                loadErrorMessage = nil
            }
        } catch {
            unlimitedProduct = nil
            loadErrorMessage = "ストアに接続できませんでした: \(error.localizedDescription)"
        }
    }

    /// 「メモ無制限」を購入する
    func purchaseUnlimited() async {
        guard let product = unlimitedProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // 購入失敗時は何もしない（UI 側で状態を反映）
        }
    }

    /// 過去の購入を復元する
    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// 現在の購入状態を反映する
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.unlimitedProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlimitedUnlocked = unlocked
    }

    /// 現在のメモ件数で、新しいメモを追加できるか判定する
    func canAddMemo(currentCount: Int) -> Bool {
        isUnlimitedUnlocked || currentCount < Self.freeMemoLimit
    }
}
