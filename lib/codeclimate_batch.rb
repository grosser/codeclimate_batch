require 'json'

module CodeclimateBatch
  class << self
    def unify(coverage_files)
      initial, *rest = coverage_files
      report = load(initial)
      rest.each do |file|
        merge_source_files(report.fetch("source_files"), load(file).fetch("source_files"))
      end
      recalculate_counters(report)
      report
    end

    private

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
