package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"

main :: proc() {
	/* part 1 */
	input0, input1 := load_input("day01/input.txt")
	defer {
		delete(input0)
		delete(input1)
	}

	slice.sort(input0[:])
	slice.sort(input1[:])

	total_distance: int
	for i in 0 ..< len(input0) {
		total_distance += math.abs(input0[i] - input1[i])
	}

	fmt.println("Total distance:", total_distance)

	/* part2 */

	frequencies1 := make(map[int]int, len(input1))
	defer delete(frequencies1)
	for v in input1 {
		frequencies1[v] += 1
	}

	similarity: int
	for v in input0 {
		similarity += v * frequencies1[v]
	}

	fmt.println("Similarity: ", similarity)
}

load_input :: proc(filename: string) -> (left: [dynamic]int, right: [dynamic]int) {
	data, ok := os.read_entire_file_from_filename(filename)
	if !ok {
		return
	}
	defer delete(data)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		entries := strings.split(line, "   ")

		append(&left, read_number(entries[0]))
		append(&right, read_number(entries[1]))
	}

	return
}

read_number :: proc(value: string) -> (number: int) {
	factor := math.pow10_f64(f64(len(value) - 1))

	for n, i in value {
		number += int(n - '0') * int(factor / math.pow10_f64(f64(i)))
	}

	return
}
