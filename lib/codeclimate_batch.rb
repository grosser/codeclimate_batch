require 'json'

module CodeclimateBatch
  class << self
    # Start TestReporter with appropriate settings.
    # Note that Code Climate only accepts reports from the default branch (usually master, but can be changed)
    # but records coverage on all PRs -> wasted time
    def start
      return if travis? && (outside_default_branch? || pull_request?)
      ENV['CODECLIMATE_TO_FILE'] = '1' # write results to file since we need to combine them before sending
      gem 'codeclimate-test-reporter', '>= 0.4.8' # get CODECLIMATE_TO_FILE support and avoid deprecations
      require 'codeclimate-test-reporter'
      CodeClimate::TestReporter.start
    end

    def unify(coverage_files)
      initial, *rest = coverage_files
      report = load(initial)
      rest.each do |file|
        merge_source_files(report.fetch("source_files"), load(file).fetch("source_files"))
      end
      recalculate_counters(report)
      report
    end

    # Return the default branch. Most of the time it's master, but can be overridden
    # by setting DEFAULT_BRANCH in the environment.
    def default_branch
      ENV['DEFAULT_BRANCH'] || 'master'
    end

    private

    # Check if we are running on Travis CI.
    def travis?
      ENV['TRAVIS']
    end

    # Check if our Travis build is running on the default branch.
    def outside_default_branch?
      default_branch != ENV['TRAVIS_BRANCH']
    end

    # Check if running a pull request.
    def pull_request?
      ENV['TRAVIS_PULL_REQUEST'].to_i != 0
    end

    def load(file)
      JSON.load(File.read(file))
    end

    def recalculate_counters(report)
      source_files = report.fetch("source_files").map { |s| s["line_counts"] }
      report["line_counts"].keys.each do |k|
        report["line_counts"][k] = source_files.map { |s| s[k] }.inject(:+)
      end
    end

    def merge_source_files(all, source_files)
      source_files.each do |new_file|
        old_file = all.detect { |source_file| source_file["name"] == new_file["name"] }

        if old_file
          # merge source files
          coverage = merge_coverage(
            JSON.load(new_file.fetch("coverage")),
            JSON.load(old_file.fetch("coverage"))
          )
          old_file["coverage"] = JSON.dump(coverage)

          total = coverage.size
          missed, covered = coverage.compact.partition { |l| l == 0 }.map(&:size)
          old_file["covered_percent"] = (covered == 0 ? 0.0 : covered * 100.0 / (covered + missed))
          old_file["line_counts"] = {"total" => total, "covered" => covered, "missed" => missed}
        else
          # just use the new value
          all << new_file
        end
      end
    end

    # [nil,1,0] + [nil,nil,2] -> [nil,1,2]
    def merge_coverage(a,b)
      b.map! do |b_count|
        a_count = a.shift
        (!b_count && !a_count) ? nil : b_count.to_i + a_count.to_i
      end
    end
  end
end
