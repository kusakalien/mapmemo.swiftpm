import SwiftUI
import StoreKit

/// 無料上限に達したときに表示する課金画面。
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                VStack(spacing: 8) {
                    Text("メモを無制限に")
                        .font(.title.bold())
                    Text("無料で登録できるメモは\(StoreManager.freeMemoLimit)件までです。\n購入するとメモを無制限に登録できます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    if let product = store.unlimitedProduct {
                        Button {
                            Task {
                                isPurchasing = true
                                await store.purchaseUnlimited()
                                isPurchasing = false
                            }
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                } else {
                                    Text("\(product.displayName) を購入")
                                    Text(product.displayPrice).bold()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                        }
                        .disabled(isPurchasing)
                    } else if store.loadFailed {
                        Text("商品情報を読み込めませんでした。\nネットワーク接続を確認してください。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("再読み込み") {
                            Task { await store.loadProducts() }
                        }
                    } else {
                        ProgressView("読み込み中…")
                    }

                    Button("購入を復元") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.footnote)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("アップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            // 購入が完了したら自動で閉じる
            .onChange(of: store.isUnlimitedUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }
}
