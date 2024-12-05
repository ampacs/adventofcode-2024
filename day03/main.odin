package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"

Instructions :: union {
	ValueInstruction,
	MulInstruction,
}

Instruction :: struct {
	instruction: rawptr,
	evaluate:    proc(instruction: Instruction) -> int,
}

ValueInstruction :: struct {
	value:          int,
	evaluate:       proc(instruction: ValueInstruction) -> int,
	as_instruction: proc(instruction: ValueInstruction) -> Instruction,
}

new_value_instruction :: proc(value: int) -> ValueInstruction {
	return ValueInstruction{value, evaluate_value, value_instruction_to_instruction}
}

evaluate_value :: proc(instruction: ValueInstruction) -> int {
	return instruction.value
}

value_instruction_to_instruction :: proc(instruction: ValueInstruction) -> Instruction {
	i := allocate_to_heap(ValueInstruction, instruction)
	evaluate := proc(instruction: Instruction) -> int {
		v := cast(^ValueInstruction)(instruction.instruction)

		return v.value
	}

	return Instruction{i, evaluate}
}

MulInstruction :: struct {
	entries:        [2]Instruction,
	evaluate:       proc(mul: MulInstruction) -> int,
	as_instruction: proc(instruction: MulInstruction) -> Instruction,
}

new_mul_instruction :: proc(instructions: [2]Instruction) -> MulInstruction {
	return MulInstruction {
		entries = instructions,
		evaluate = evaluate_mul,
		as_instruction = mul_instruction_to_instruction,
	}
}

evaluate_mul :: proc(mul: MulInstruction) -> int {
	value: int = 1
	for entry in mul.entries {
		value *= entry->evaluate()
	}

	return value
}

mul_instruction_to_instruction :: proc(instruction: MulInstruction) -> Instruction {
	i := allocate_to_heap(MulInstruction, instruction)
	evaluate_instruction_mul :: proc(instruction: Instruction) -> int {
		m := cast(^MulInstruction)(instruction.instruction)

		return m->evaluate()
	}

	return Instruction{i, evaluate_instruction_mul}
}

main :: proc() {
	/* part 1 */

	memory := load_memory("day03/input.txt")
	defer delete(memory)

	is_instruction_control_allowed :: true

	instructions := get_instructions(memory)
	defer delete(instructions)

	fmt.println("Instructions found:", len(instructions))
	fmt.println("Result:", get_instructions_result(instructions))

	fmt.println()

	/* part 2 */

	controlled_instructions := get_instructions(memory, true)
	defer delete(controlled_instructions)

	fmt.println(
		"Instructions found (with enabled control instructions):",
		len(controlled_instructions),
	)
	fmt.println(
		"Result (with enabled control instructions):",
		get_instructions_result(controlled_instructions),
	)
}

get_instructions_result :: proc(instructions: []MulInstruction) -> int {
	result: int
	for instruction in instructions {
		result += instruction->evaluate()
	}

	return result
}

get_instructions :: proc(
	memory: []byte,
	is_instruction_control_allowed: bool = false,
) -> []MulInstruction {
	instruction_enabler :: []byte{'d', 'o', '(', ')'}
	instruction_disabler :: []byte{'d', 'o', 'n', '\'', 't', '(', ')'}

	instruction_entries_start :: []byte{'m', 'u', 'l', '('} // mul
	instruction_entries_sep: byte : ','
	instruction_entries_end: byte : ')'
	instruction_entries_count :: 2
	valid_instruction_entries :: []byte{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

	instructions := make([dynamic]MulInstruction, 0, 1000)

	current_entry := make([dynamic]byte, 0, 3)
	defer delete(current_entry)
	current_entry_index: int
	current_entries: [instruction_entries_count]int
	is_searching_entry: bool

	is_instruction_allowed := true

	for i := 0; i < len(memory); i += 1 {
		character := memory[i]
		switch character {
		case instruction_entries_start[0]:
			if !is_instruction_allowed {
				continue
			}

			offset := get_command_offset(memory, instruction_entries_start, i)
			if offset == -1 {
				continue
			}

			i += offset

			clear(&current_entry)
			current_entry_index = 0
			current_entries = [2]int{0, 0}
			is_searching_entry = true
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			if is_searching_entry {
				append(&current_entry, character)
			}
		case instruction_entries_sep:
			if !is_searching_entry || current_entry_index != 0 {
				is_searching_entry = false

				continue
			}

			ok: bool
			current_entries[0], ok = parse_number(current_entry[:])
			if !ok {
				is_searching_entry = false

				continue
			}

			clear(&current_entry)
			current_entry_index = 1
		case instruction_entries_end:
			if !is_searching_entry || current_entry_index != 1 {
				is_searching_entry = false

				continue
			}

			ok: bool
			current_entries[1], ok = parse_number(current_entry[:])
			if !ok {
				is_searching_entry = false

				continue
			}

			v1 := new_value_instruction(current_entries[0])
			v2 := new_value_instruction(current_entries[1])

			mul := new_mul_instruction([2]Instruction{v1->as_instruction(), v2->as_instruction()})
			append(&instructions, mul)

			is_searching_entry = false
		case instruction_enabler[0]:
			if !is_instruction_control_allowed {
				continue
			}

			offset := get_command_offset(memory, instruction_enabler, i)
			if offset == -1 {
				offset = get_command_offset(memory, instruction_disabler, i)
				if offset == -1 {
					continue
				} else {
					is_instruction_allowed = false
					is_searching_entry = false
				}
			} else {
				is_instruction_allowed = true
			}

			i += offset
		case:
			is_searching_entry = false
		}
	}

	return instructions[:]
}

get_command_offset :: proc(value, command: []byte, start: int) -> int {
	if start + len(command) > len(value) {
		return -1
	}

	i: int
	for c in command {
		if c != value[start + i] {
			return -1
		}

		i += 1
	}

	return i - 1
}

parse_number :: proc(value: []byte) -> (int, bool) {
	value, ok := strconv.parse_i64_of_base(string(value), 10)

	return int(value), ok
}

load_memory :: proc(filename: string) -> []byte {
	content, _ := os.read_entire_file_from_filename(filename)

	return content
}

allocate_to_heap :: proc($T: typeid, value: T) -> (v: ^T) {
	v = new(T)
	v^ = value
	return
}
