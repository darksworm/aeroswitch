class Aeroswitch < Formula
  desc "Fast and lightweight window switcher for AeroSpace users"
  homepage "https://github.com/yourusername/aeroswitch"
  url "https://github.com/yourusername/aeroswitch/archive/v1.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE" # Will be updated when you create the GitHub release
  license "GPL-3.0"
  head "https://github.com/yourusername/aeroswitch.git", branch: "main"

  depends_on xcode: ["13.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/aeroswitch"
  end

  def caveats
    <<~EOS
      AeroSwitch requires AeroSpace window manager to be installed.
      Get AeroSpace from: https://github.com/nikitabobko/AeroSpace

      To start AeroSwitch as a background service:
        aeroswitch --background

      To activate the window switcher:
        aeroswitch --activate
    EOS
  end

  test do
    assert_match "AeroSwitch v1.0.0", shell_output("#{bin}/aeroswitch --version")
  end
end