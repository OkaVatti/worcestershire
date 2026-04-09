require "./spec_helper"

module Worcestershire
  describe Transforms do
    describe "case_variants" do
      it "generates all variants for short words" do
        variants = Transforms.case_variants("ab")
        variants.sort.should eq(["ab", "aB", "Ab", "AB"].sort)
      end

      it "returns three variants for words longer than 10 chars" do
        variants = Transforms.case_variants("abcdefghijk")
        variants.sort.should eq(["abcdefghijk", "ABCDEFGHIJK", "Abcdefghijk"].sort)
      end
    end

    describe "homograph_variants" do
      it "substitutes known characters" do
        variants = Transforms.homograph_variants("a")
        variants.should contain("a")
        variants.should contain("@")
        variants.should contain("4")
      end

      it "accepts a custom dict" do
        custom = {'x' => ["9", "y"]}
        variants = Transforms.homograph_variants("x", custom)
        variants.should contain("9")
        variants.should contain("y")
      end
    end

    describe "reverse_variant" do
      it "reverses the word" do
        Transforms.reverse_variant("abc").should eq("cba")
      end
    end

    describe "leet_variants" do
      it "substitutes known characters positionally" do
        variants = Transforms.leet_variants("leet")
        variants.should contain("leet")
        variants.should contain("133t")
      end
    end

    describe "affix_variants" do
      it "prepends and appends each affix" do
        variants = Transforms.affix_variants("pass", ["!"])
        variants.should contain("!pass")
        variants.should contain("pass!")
      end
    end

    describe "keyboard_variants" do
      it "substitutes adjacent keys" do
        variants = Transforms.keyboard_variants("a")
        # 'a' is adjacent to q, w, s, z
        variants.should contain("q")
        variants.should contain("s")
      end

      it "preserves case of the replaced character" do
        variants = Transforms.keyboard_variants("A")
        variants.should contain("Q")
        variants.should contain("S")
      end
    end

    describe "date_variants" do
      it "appends and prepends date strings" do
        variants = Transforms.date_variants("pass", ["2024"])
        variants.should contain("pass2024")
        variants.should contain("2024pass")
      end
    end

    describe "apply" do
      it "dispatches combination type 2" do
        Transforms.apply(2, "ab").sort.should eq(["ab", "aB", "Ab", "AB"].sort)
      end

      it "dispatches combination type 4" do
        Transforms.apply(4, "abc").should eq(["cba"])
      end

      it "returns [word] for unknown type" do
        Transforms.apply(99, "x").should eq(["x"])
      end
    end
  end
end
