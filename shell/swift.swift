actor BankAccount {
  // 行为体状态
  let accountNumber: Int
  var balance: Double

  enum BankAccountError: Error {
    case insufficientBalance(Double)
    case authorizeFailed
  }
  // 除了无法继承，行为体同类一样
  init(accountNumber: Int, initialDeposit: Double) {
    self.accountNumber = accountNumber
    self.balance = initialDeposit
  }
  // 对于行为体内部方法来说，在串行机制的保障下，可以直接调用行为体状态
  func deposit(amount: Double) {
    assert(amount >= 0)
    balance = balance + amount
  }
  // 行为体内部定义异步方法也是可以的：
  func withdraw(amount: Double) async throws -> Double {
    guard balance >= amount else {
      throw BankAccountError.insufficientBalance(balance)
    }
    // 调用异步方法或属性
    guard await authorize() else {
      throw BankAccountError.authorizeFailed
    }
    balance -= amount
    return balance
  }
  private func authorize() async -> Bool {
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    return true
  }
}
extension BankAccount {
  // 在该方法内部只引用了 let accountNumber，故不存在 Data races
  // 也就可以用 nonisolated 修饰
  nonisolated func safeAccountNumberDisplayString() -> String {
    let digits = String(accountNumber)
    return String(repeating: "X", count: digits.count - 4) + String(digits.suffix(4))
  }
}
let ba = BankAccount(accountNumber: 10000, initialDeposit: 100)
// 对于行为体外部来说，行为体是黑盒（可能会有其他异步任务调用行为体状态），所有调用均需要等待执行（await）
await ba.deposit(amount: 100)
print(await ba.balance)
print(ba.accountNumber)
print(ba.safeAccountNumberDisplayString())

class AccountManager {
  let bankAccount = BankAccount.init(
    accountNumber: 123_456_789,
    initialDeposit: 1000
  )

  func withdraw() async {
    for _ in 0..<2 {
      Task {
        let amount = 600.0
        do {
          let balance = try await bankAccount.withdraw(amount: amount)
          print("Withdrawal succeeded, balance = \(balance)")
        } catch let error as BankAccount.BankAccountError {
          switch error {
          case .insufficientBalance(let balance):
            print("Insufficient balance, balance = \(balance), withdrawal amount = \(amount)!")
          case .authorizeFailed:
            print("Authorize failed!")
          }
        }
      }
    }
  }
}
var ac = AccountManager()

await ac.withdraw()

try? await Task.sleep(nanoseconds: 10_000_000_000)
