func listPhotos(inGallery name: String) async throws -> [String] {
  try await Task.sleep(until: .now + .seconds(2), clock: .continuous)
  return ["IMG001", "IMG99", "IMG0404"]
}

func downloadPhoto(named name: String) async {
  try? await Task.sleep(nanoseconds: 1_000_000_000)
  print("downloaded:" + name)
}

await withTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
  let photoNames = ["IMG001", "IMG99", "IMG0404"]

  for name in photoNames {
    // `addTask`添加子任务
    taskGroup.addTask { await downloadPhoto(named: name) }
  }
}
let parentTask = Task {
  async let test: () = downloadPhoto(named: "IMG001")
  await test
}
await parentTask.value

async let firstPhoto: Void = downloadPhoto(named: "IMG001")
async let secondPhoto: Void = downloadPhoto(named: "IMG002")
async let thirdPhoto: Void = downloadPhoto(named: "IMG003")
try! await [firstPhoto, secondPhoto, thirdPhoto]
// downloaded:IMG001
// downloaded:IMG0404
// downloaded:IMG99
