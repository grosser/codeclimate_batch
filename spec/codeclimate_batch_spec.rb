require "spec_helper"
require "codeclimate-test-reporter"

describe CodeclimateBatch do
  def with_env(env)
    env.each { |k,v| ENV[k] = v }
    yield
  ensure
    env.each { |k,_v| ENV[k] = nil }
  end

  it "has a VERSION" do
    CodeclimateBatch::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "CLI" do
    def sh(command, options={})
      result = `#{command} #{"2>&1" unless options[:keep_output]}`
      raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
      result
    end

    def batch(command, options={})
      sh("#{Bundler.root}/bin/codeclimate-batch #{command}", options)
    end

    it "shows --version" do
      batch("--version").should include(CodeclimateBatch::VERSION)
    end

    it "shows --help" do
      batch("--help").should include("codeclimate")
    end

    it "does nothing when there are no files" do
      batch("--groups 4").should == "Code climate: No files found to report\n"
    end

    it "merges and reports" do
      with_env("TRAVIS_REPO_SLUG" => "xxx/yyy", "TRAVIS_BUILD_NUMBER" => rand(900000).to_s) do
        base = "#{Dir.tmpdir}/codeclimate-test-coverage-"

        # pretend we just ran code climate reporter
        ["report_a.json", "report_b.json"].each do |r|
          sh "cp #{Bundler.root}/spec/files/#{r} #{base}#{r}"
        end
        Dir["#{base}*"].size.should == 2

        # send reports
        result = batch("--groups 4")
        result.should include "waiting for 3/4 reports on xxx-yyy-"
        result.sub(/\d+\.\d+s/,'TIME').should include "Code climate: TIME to send 2 reports"

        # all cleaned up ?
        Dir["#{base}*"].size.should == 0
      end
    end
  end

  describe ".start" do
    let(:default) {{"TRAVIS" => "1", "TRAVIS_BRANCH" => "master", "CODECLIMATE_TO_FILE" => nil, "TRAVIS_PULL_REQUEST" => nil}}

    it "calls start when on travis master" do
      with_env(default) do
        CodeClimate::TestReporter.should_receive(:start)
        CodeclimateBatch.start
        ENV["CODECLIMATE_TO_FILE"].should == "1"
      end
    end

    it "starts without travis since we don't know how to handle other cis" do
      default.delete("TRAVIS")
      with_env(default) do
        CodeClimate::TestReporter.should_receive(:start)
        CodeclimateBatch.start
      end
    end

    it "does not start on different branch" do
      default["TRAVIS_BRANCH"] = "mooo"
      with_env(default) do
        CodeClimate::TestReporter.should_not_receive(:start)
        CodeclimateBatch.start
      end
    end

    it "starts on different branch if set as default branch" do
      default.merge! "TRAVIS_BRANCH" => "moooo", "DEFAULT_BRANCH" => "moooo"
      with_env(default) do
        CodeClimate::TestReporter.should_receive(:start)
        CodeclimateBatch.start
      end
    end

    it "does not starts on different branch if it doesn't match default branch" do
      default.merge! "TRAVIS_BRANCH" => "moooo", "DEFAULT_BRANCH" => "monster"
      with_env(default) do
        CodeClimate::TestReporter.should_not_receive(:start)
        CodeclimateBatch.start
      end
    end

    it "starts on PR" do
      default["TRAVIS_PULL_REQUEST"] = "123"
      with_env(default) do
        CodeClimate::TestReporter.should_receive(:start)
        CodeclimateBatch.start
      end
    end
  end

  describe ".unify" do
    it "merges reports 1 report" do
      report = CodeclimateBatch.unify(["spec/files/report_a.json"])
      report["line_counts"].should == {"total" => 18, "covered" => 7, "missed" => 3}
    end

    it "merges multiple reports" do
      report = CodeclimateBatch.unify(["spec/files/report_a.json", "spec/files/report_b.json"])
      report["line_counts"].should == {"total" => 18, "covered" => 9, "missed" => 1}
    end
  end

  describe ".merge_source_files" do
    it "merges" do
      all = [{"name" => "a.rb", "coverage" => '[null,1,null]'}, {"name" => "b.rb", "coverage" => '[1,1,null]'}]
      CodeclimateBatch.send(:merge_source_files,
        all,
        [{"name" => "b.rb", "coverage" => '[null,2,1]'}]
      )
      all.should == [
        {"name"=>"a.rb", "coverage"=>"[null,1,null]"},
        {"name"=>"b.rb", "coverage"=>"[1,3,1]", "covered_percent"=>100.0, "line_counts"=>{"total"=>3, "covered"=>3, "missed"=>0}}
      ]
    end

    it "merges uncovered" do
      all = [{"name" => "a.rb", "coverage" => '[]'}]
      CodeclimateBatch.send(:merge_source_files,
        all,
        all
      )
      all.should == [{"name"=>"a.rb", "coverage"=>"[]", "covered_percent"=>0.0, "line_counts"=>{"total"=>0, "covered"=>0, "missed"=>0}}]
    end
  end
end
