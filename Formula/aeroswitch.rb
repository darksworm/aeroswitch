class Aeroswitch < Formula
  desc "Fast and lightweight window switcher for AeroSpace users"
  homepage "https://github.com/darksworm/aeroswitch"
  url "https://github.com/darksworm/aeroswitch/releases/download/v1.0.0/aeroswitch-1.0.0-macos.tar.gz"
  sha256 "YOUR_SHA256_HERE" # Will be updated when you create the GitHub release
  license "GPL-3.0"
  head "https://github.com/darksworm/aeroswitch.git", branch: "main"

  depends_on :macos

  def install
    bin.install "aeroswitch"
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