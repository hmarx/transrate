require 'helper'
require 'bio'
require 'tmpdir'

class TestAssembly < MiniTest::Test

  context "Assembly" do

    setup do
      a = File.join(File.dirname(__FILE__), 'data', 'sorghum_100.fa')
      @assembly = Transrate::Assembly.new(a)
    end

    should "run" do
      @assembly.run 1
      assert_equal true, @assembly.has_run
    end

    should "classify contigs" do
      @assembly.run 1
      read_metrics = Transrate::ReadMetrics.new(@assembly)
      left = File.join(File.dirname(__FILE__), 'data', 'sorghum_100.1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'sorghum_100.2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do
          read_metrics.run(left, right)
          @assembly.classify_contigs 0.5
          assert File.exist?("good.sorghum_100.fa"), "good output exists"
          assert File.exist?("bad.sorghum_100.fa"), "bad output"
          file_size = File.stat("good.sorghum_100.fa").size
          assert_in_delta 86_119, file_size, 5000, "good file size"
          file_size = File.stat("bad.sorghum_100.fa").size
          assert_in_delta 53_000, file_size, 5000, "bad file size"
        end
      end
    end

    should "capture error with multiple identical named contigs" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do
          ref = File.join(File.dirname(__FILE__), 'data', 'sorghum_100.fa')
          cmd = Transrate::Cmd.new("cat #{ref} #{ref} > tmp.fa")
          cmd.run
          capture_stderr do
            assert_raises Transrate::AssemblyError do
              assembly = Transrate::Assembly.new("tmp.fa")
            end
          end
        end
      end
    end

    should "capture error with bad characters in contig name" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do
          ref = File.join(File.dirname(__FILE__), 'data', 'sorghum_100.fa')
          cmd = Transrate::Cmd.new("cat #{ref} | sed 's/\./,/g' > tmp.fa")
          cmd.run
          capture_stderr do
            assert_raises Transrate::AssemblyError do
              assembly = Transrate::Assembly.new("tmp.fa")
            end
          end
        end
      end
    end

  end
end
