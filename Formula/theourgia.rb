class Theourgia < Formula
  desc "Block store for agents and people: drafts and commits, code import, eval, MCP shell"
  homepage "https://github.com/guenchi/Theourgia"
  url "https://github.com/guenchi/Theourgia/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "01f7eaf8bebcb83df38ea7674425747755708b552a7cfa575911d28caf737006"
  license "Apache-2.0"

  depends_on "chezscheme"
  depends_on "libuv"

  resource "igropyr" do
    url "https://github.com/guenchi/Igropyr/archive/56ca0db9c8bb1c32bafa1e1472852a6186ada31b.tar.gz"
    sha256 "5bfec8115942d0b66ae63923d2d908895b0c3ada1075ab4e72a0c49f3996828b"
  end

  def install
    # build.ss wants a library root that contains theourgia/ and igropyr/;
    # it compiles both into objects and copies the programs beside them.
    root = buildpath/"root"
    (root/"theourgia").install Dir["*"]
    resource("igropyr").stage { (root/"igropyr").install Dir["*"] }
    chez = Formula["chezscheme"].opt_bin/"chez"
    system chez, "--script", root/"theourgia/build.ss", root, libexec

    # Homebrew's Chez binary is chez; the core starts its daemon and its
    # children with THEOURGIA_SCHEME when it is set.
    env = <<~SH
      export CHEZSCHEMELIBDIRS="#{libexec}"
      export CHEZSCHEMELIBEXTS=".so"
      export THEOURGIA_SCHEME="#{chez}"
    SH
    {
      "theourgia"     => "theourgia/theourgia.sc",
      "theourgia-mcp" => "theourgia/mcp/server.sc",
      "theourgiad"    => "theourgia/theourgiad.sc",
    }.each do |name, program|
      (bin/name).write <<~SH
        #!/bin/sh
        #{env}exec "#{chez}" --script "#{libexec}/#{program}" "$@"
      SH
    end
  end

  test do
    store = testpath/"store"
    assert_match "(ok (store", shell_output("#{bin}/theourgia init --store #{store}")
    system bin/"theourgia", "insert", "--store", store, "--title", "brew test", "--text", "hello"
    assert_match "brew test", shell_output("#{bin}/theourgia outline --store #{store} --depth 1")
  end
end
