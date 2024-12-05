package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

main :: proc() {
	/* part 1 */

	reports := load_reports("day02/input.txt")
	defer delete(reports)

	safe_count: int
	for report, i in reports {
		if is_report_safe(report) {
			safe_count += 1
		}
	}

	fmt.println("\nNumber of reports:", len(reports))
	fmt.println("Number of safe reports:", safe_count)

	/* part 2 */

	safe_count = 0
	reports_loop: for report in reports {
		// check if report is safe
		i, j := get_report_unsafe_levels_range(report)
		// if `i` is -1, so is `j`
		if i == -1 {
			safe_count += 1

			continue
		}

		/* engage problem dampener */

		// check if report becomes safe if the levels
		// in the identified range are removed
		dampened_report := make([dynamic]int, len(report) - 1, len(report) - 1)
		defer delete(dampened_report)

		for k in i ..= j {
			copy(dampened_report[:k], report[:k])
			copy(dampened_report[k:], report[k + 1:])
			// or
			// 	copy(dampened_report[:], report[:])
			// 	ordered_remove(&dampened_report, k)

			if l, _ := get_report_unsafe_levels_range(dampened_report[:]); l == -1 {
				safe_count += 1

				continue reports_loop
			}
		}

		/* /
		fmt.println(report)

		transitions := strings.builder_make_none()
		strings.write_string(&transitions, " ")

		for k in 1 ..< len(report) {
			transition := report[k] - report[k - 1]

			strings.write_string(&transitions, transition < 0 ? "" : " ")
			strings.write_string(&transitions, report[k - 1] < 10 ? " " : "  ")

			strings.write_int(&transitions, transition)
		}

		fmt.println(strings.to_string(transitions))
		/ */
	}

	fmt.println("Number of safe reports with problem dampener:", safe_count)
}

get_report_unsafe_levels_range :: proc(report: []int) -> (int, int) {
	is_decreasing_trend := report[0] > report[1]

	for i in 1 ..< len(report) {
		previous_level := report[i - 1]
		current_level := report[i]

		if !is_level_transition_safe(previous_level, current_level, is_decreasing_trend) {
			// the problematic levels will the between the current one
			// and (up to) the previous 2 levels;
			// the issue will be in the transition between
			// the previous and current levels, or between
			// the one before the previous and the previous
			return i < 2 ? i - 1 : i - 2, i
		}
	}

	return -1, -1
}

is_report_safe :: proc(report: []int) -> bool {
	is_decreasing_trend := report[0] > report[1]

	for i := 1; i < len(report); i += 1 {
		previous_level := report[i - 1]
		current_level := report[i]

		if !is_level_transition_safe(previous_level, current_level, is_decreasing_trend) {
			return false
		}
	}

	return true
}

is_level_transition_safe :: proc(
	current_level: int,
	next_level: int,
	is_decreasing_trend: bool,
) -> bool {
	difference := next_level - current_level

	variation := math.abs(difference)
	is_same_trend := math.sign_bit_f64(f64(difference)) == is_decreasing_trend

	return variation >= 1 && variation <= 3 && is_same_trend
}

load_reports :: proc(filename: string) -> (reports: [dynamic][]int) {
	content, ok := os.read_entire_file_from_filename(filename)
	if !ok {
		return
	}
	defer delete(content)

	it := string(content)
	for line in strings.split_lines_iterator(&it) {
		append(&reports, parse_report(line))
	}

	return
}

parse_report :: proc(line: string) -> (report: []int) {
	values := strings.split(line, " ")
	report = make([]int, len(values))

	for value, i in values {
		v, _ := strconv.parse_i64_of_base(value, 10)

		report[i] = int(v)
	}

	return
}
