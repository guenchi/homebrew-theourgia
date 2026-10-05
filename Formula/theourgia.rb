class Theourgia < Formula
  desc "Block store for agents and people: drafts and commits, code import, eval, MCP shell"
  homepage "https://github.com/guenchi/Theourgia"
  url "https://github.com/guenchi/Theourgia/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "e4b67b3ba470bc9be131998abb1b9f258547e3bb899dec3f50e899979556fa4e"
  license "Apache-2.0"

  depends_on "chezscheme"
  depends_on "libuv"

  resource "igropyr" do
    url "https://github.com/guenchi/Igropyr/archive/1ef294c261121e6f98c8e8f500c90ac2aae5edc9.tar.gz"
    sha256 "cd9f609ad7bc6d179c29919cdda20a1e0ca89ac3ea12095570b894b09e42ae42"
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
