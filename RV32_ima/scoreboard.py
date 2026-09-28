#!/usr/bin/env python3

import csv
import json
import sys
import os
from collections import Counter


# ============================================================
# LOAD SPIKE TRACE
# ============================================================

def load_spike(filename):

    with open(filename, "r") as f:
        return json.load(f)


# ============================================================
# LOAD RTL TRACE
# ============================================================

def load_rtl(filename):

    commits = []

    with open(filename, "r", newline="") as f:

        reader = csv.DictReader(f)

        for row in reader:

            commits.append({
                "index": int(row["index"]),
                "cycle": int(row["cycle"]),
                "pc": int(row["pc"], 16),
                "instr": int(row["instr"], 16),
                "mnemonic": row["mnemonic"].strip(),

                "rd": int(row["rd"]),

                "rd_we": bool(
                    int(row["rd_we"])
                ),

                "rd_data": int(
                    row["rd_data"],
                    16
                ),
            })

    return commits


# ============================================================
# SAFE FIELD ACCESS
# ============================================================

def get_field(entry, field, default="N/A"):

    return entry.get(field, default)


# ============================================================
# FORMAT VALUE
# ============================================================

def format_value(value):

    if value == "N/A":
        return "N/A"

    if isinstance(value, bool):
        return str(value)

    if isinstance(value, int):
        return f"0x{value:08X}"

    return str(value)


# ============================================================
# COMPARE ONE RETIRED INSTRUCTION
# ============================================================

def compare_instruction(spike, rtl):

    errors = []

    # --------------------------------------------------------
    # PC
    # --------------------------------------------------------

    if spike["pc"] != rtl["pc"]:

        errors.append(
            f"PC mismatch: "
            f"Spike=0x{spike['pc']:08X}, "
            f"RTL=0x{rtl['pc']:08X}"
        )

    # --------------------------------------------------------
    # Instruction encoding
    # --------------------------------------------------------

    if spike["instr"] != rtl["instr"]:

        errors.append(
            f"Instruction mismatch: "
            f"Spike=0x{spike['instr']:08X}, "
            f"RTL=0x{rtl['instr']:08X}"
        )

    # --------------------------------------------------------
    # Mnemonic
    # --------------------------------------------------------

    spike_mnemonic = get_field(
        spike,
        "mnemonic",
        "N/A"
    )

    rtl_mnemonic = get_field(
        rtl,
        "mnemonic",
        "N/A"
    )

    if spike_mnemonic != "N/A":

        if spike_mnemonic != rtl_mnemonic:

            errors.append(
                f"Mnemonic mismatch: "
                f"Spike={spike_mnemonic}, "
                f"RTL={rtl_mnemonic}"
            )

    # --------------------------------------------------------
    # Register write enable
    # --------------------------------------------------------

    if spike["rd_we"] != rtl["rd_we"]:

        errors.append(
            f"RD_WE mismatch: "
            f"Spike={spike['rd_we']}, "
            f"RTL={rtl['rd_we']}"
        )

    # --------------------------------------------------------
    # Destination register and data
    #
    # Only meaningful when the instruction writes a register.
    # --------------------------------------------------------

    if spike["rd_we"] and rtl["rd_we"]:

        # ----------------------------------------------------
        # Destination register
        # ----------------------------------------------------

        if spike["rd"] != rtl["rd"]:

            errors.append(
                f"RD mismatch: "
                f"Spike={spike['rd']}, "
                f"RTL={rtl['rd']}"
            )

        # ----------------------------------------------------
        # Destination data
        # ----------------------------------------------------

        if spike["rd_data"] != rtl["rd_data"]:

            errors.append(
                f"RD_DATA mismatch: "
                f"Spike=0x{spike['rd_data']:08X}, "
                f"RTL=0x{rtl['rd_data']:08X}"
            )

    return errors


# ============================================================
# GET INSTRUCTION TYPE
# ============================================================

def get_instruction_type(mnemonic):

    if mnemonic == "N/A":
        return "UNKNOWN"

    mnemonic = mnemonic.lower()

    r_type = {
        "add", "sub",
        "sll", "slt", "sltu",
        "xor", "srl", "sra",
        "or", "and"
    }

    i_type = {
        "addi", "slti", "sltiu",
        "xori", "ori", "andi",
        "slli", "srli", "srai"
    }

    load_type = {
        "lb", "lh", "lw",
        "lbu", "lhu"
    }

    store_type = {
        "sb", "sh", "sw"
    }

    branch_type = {
        "beq", "bne",
        "blt", "bge",
        "bltu", "bgeu"
    }

    jump_type = {
        "jal", "jalr"
    }

    upper_type = {
        "lui", "auipc"
    }

    system_type = {
        "ecall", "ebreak"
    }

    if mnemonic in r_type:
        return "R-TYPE"

    if mnemonic in i_type:
        return "I-TYPE"

    if mnemonic in load_type:
        return "LOAD"

    if mnemonic in store_type:
        return "STORE"

    if mnemonic in branch_type:
        return "BRANCH"

    if mnemonic in jump_type:
        return "JUMP"

    if mnemonic in upper_type:
        return "UPPER"

    if mnemonic in system_type:
        return "SYSTEM"

    return "OTHER"


# ============================================================
# BUILD INSTRUCTION REPORT
# ============================================================

def build_instruction_report(spike, rtl):

    report = []

    total = max(
        len(spike),
        len(rtl)
    )

    for i in range(total):

        # ----------------------------------------------------
        # RTL missing instruction
        # ----------------------------------------------------

        if i >= len(rtl):

            s = spike[i]

            report.append({
                "index": i,
                "pc": s["pc"],
                "instr": s["instr"],
                "mnemonic": get_field(
                    s,
                    "mnemonic"
                ),

                "instruction_type": get_instruction_type(
                    get_field(
                        s,
                        "mnemonic"
                    )
                ),

                "spike_rd": s["rd"],
                "spike_rd_we": s["rd_we"],
                "spike_rd_data": s["rd_data"],

                "rtl_rd": "N/A",
                "rtl_rd_we": "N/A",
                "rtl_rd_data": "N/A",

                "status": "FAIL",

                "error": "RTL missing instruction"
            })

            continue

        # ----------------------------------------------------
        # Spike missing instruction
        # ----------------------------------------------------

        if i >= len(spike):

            r = rtl[i]

            report.append({
                "index": i,
                "pc": r["pc"],
                "instr": r["instr"],
                "mnemonic": r["mnemonic"],

                "instruction_type": get_instruction_type(
                    r["mnemonic"]
                ),

                "spike_rd": "N/A",
                "spike_rd_we": "N/A",
                "spike_rd_data": "N/A",

                "rtl_rd": r["rd"],
                "rtl_rd_we": r["rd_we"],
                "rtl_rd_data": r["rd_data"],

                "status": "FAIL",

                "error": "RTL has extra instruction"
            })

            continue

        # ----------------------------------------------------
        # Normal comparison
        # ----------------------------------------------------

        s = spike[i]
        r = rtl[i]

        errors = compare_instruction(
            s,
            r
        )

        if errors:

            status = "FAIL"
            error_text = " | ".join(errors)

        else:

            status = "PASS"
            error_text = ""

        report.append({
            "index": i,

            "pc": s["pc"],

            "instr": s["instr"],

            "mnemonic": get_field(
                s,
                "mnemonic",
                r["mnemonic"]
            ),

            "instruction_type": get_instruction_type(
                get_field(
                    s,
                    "mnemonic",
                    r["mnemonic"]
                )
            ),

            # Spike result
            "spike_rd": s["rd"],
            "spike_rd_we": s["rd_we"],
            "spike_rd_data": s["rd_data"],

            # RTL result
            "rtl_rd": r["rd"],
            "rtl_rd_we": r["rd_we"],
            "rtl_rd_data": r["rd_data"],

            "status": status,

            "error": error_text
        })

    return report


# ============================================================
# INSTRUCTION COVERAGE
# ============================================================

def calculate_instruction_coverage(report):

    total = Counter()
    passed = Counter()
    failed = Counter()

    for r in report:

        instruction_type = r[
            "instruction_type"
        ]

        total[instruction_type] += 1

        if r["status"] == "PASS":

            passed[instruction_type] += 1

        else:

            failed[instruction_type] += 1

    return total, passed, failed


# ============================================================
# WRITE CSV REPORT
# ============================================================

def write_csv_report(
    filename,
    report
):

    fields = [
        "index",
        "pc",
        "instr",
        "mnemonic",
        "instruction_type",

        "spike_rd",
        "spike_rd_we",
        "spike_rd_data",

        "rtl_rd",
        "rtl_rd_we",
        "rtl_rd_data",

        "status",
        "error"
    ]

    with open(
        filename,
        "w",
        newline=""
    ) as f:

        writer = csv.DictWriter(
            f,
            fieldnames=fields
        )

        writer.writeheader()

        for row in report:

            writer.writerow(row)


# ============================================================
# WRITE HUMAN-READABLE REPORT
# ============================================================

def write_text_report(
    filename,
    spike,
    rtl,
    report,
    total_types,
    passed_types,
    failed_types
):

    with open(
        filename,
        "w"
    ) as f:

        f.write("=" * 110 + "\n")
        f.write(
            "                 RISC-V RV32I SPIKE vs RTL "
            "ARCHITECTURAL VERIFICATION REPORT\n"
        )
        f.write("=" * 110 + "\n\n")

        # ====================================================
        # 1. VERIFICATION SUMMARY
        # ====================================================

        f.write(
            "1. ARCHITECTURAL VERIFICATION SUMMARY\n"
        )

        f.write("-" * 110 + "\n")

        total = len(report)

        passed = sum(
            1
            for r in report
            if r["status"] == "PASS"
        )

        failed = sum(
            1
            for r in report
            if r["status"] == "FAIL"
        )

        if total > 0:

            score = (
                passed /
                total
            ) * 100.0

        else:

            score = 0.0

        f.write(
            f"Spike instructions       : "
            f"{len(spike)}\n"
        )

        f.write(
            f"RTL instructions         : "
            f"{len(rtl)}\n"
        )

        f.write(
            f"Instructions compared    : "
            f"{total}\n"
        )

        f.write(
            f"Passed                   : "
            f"{passed}\n"
        )

        f.write(
            f"Failed                   : "
            f"{failed}\n"
        )

        f.write(
            f"Verification score       : "
            f"{score:.2f}%\n"
        )

        if (
            failed == 0
            and
            len(spike) == len(rtl)
        ):

            f.write(
                "Overall status           : PASS\n"
            )

        else:

            f.write(
                "Overall status           : FAIL\n"
            )

        f.write("\n")

        # ====================================================
        # 2. INSTRUCTION TYPE VERIFICATION
        # ====================================================

        f.write(
            "2. INSTRUCTION TYPE VERIFICATION\n"
        )

        f.write("-" * 110 + "\n")

        f.write(
            f"{'Instruction Type':<20}"
            f"{'Total':>10}"
            f"{'Passed':>10}"
            f"{'Failed':>10}"
            f"{'Pass %':>12}\n"
        )

        f.write("-" * 110 + "\n")

        for instruction_type in sorted(
            total_types
        ):

            total_count = total_types[
                instruction_type
            ]

            passed_count = passed_types[
                instruction_type
            ]

            failed_count = failed_types[
                instruction_type
            ]

            percentage = (
                passed_count /
                total_count *
                100.0
                if total_count > 0
                else 0.0
            )

            f.write(
                f"{instruction_type:<20}"
                f"{total_count:>10}"
                f"{passed_count:>10}"
                f"{failed_count:>10}"
                f"{percentage:>11.2f}%\n"
            )

        f.write("\n")

        # ====================================================
        # 3. INSTRUCTION-BY-INSTRUCTION RESULTS
        # ====================================================

        f.write(
            "3. INSTRUCTION-BY-INSTRUCTION RESULTS\n"
        )

        f.write("-" * 110 + "\n")

        f.write(
            f"{'#':<6}"
            f"{'PC':<12}"
            f"{'Instruction':<14}"
            f"{'Mnemonic':<12}"
            f"{'Spike RD':<12}"
            f"{'Spike Data':<14}"
            f"{'RTL RD':<10}"
            f"{'RTL Data':<14}"
            f"{'Status':<8}\n"
        )

        f.write("-" * 110 + "\n")

        for r in report:

            f.write(
                f"{r['index']:<6}"
                f"0x{r['pc']:08X}  "
                f"0x{r['instr']:08X}    "
                f"{str(r['mnemonic']):<12}"
                f"{str(r['spike_rd']):<12}"
                f"{format_value(r['spike_rd_data']):<14}"
                f"{str(r['rtl_rd']):<10}"
                f"{format_value(r['rtl_rd_data']):<14}"
                f"{r['status']:<8}\n"
            )

            if r["error"]:

                f.write(
                    f"       ERROR: "
                    f"{r['error']}\n"
                )

        f.write("\n")

        # ====================================================
        # 4. FAILURE ANALYSIS
        # ====================================================

        f.write(
            "4. FAILURE ANALYSIS\n"
        )

        f.write("-" * 110 + "\n")

        failures = [
            r
            for r in report
            if r["status"] == "FAIL"
        ]

        if not failures:

            f.write(
                "No architectural mismatches detected.\n"
            )

        else:

            for r in failures:

                f.write(
                    f"\nInstruction #{r['index']}\n"
                )

                f.write(
                    f"  PC         : "
                    f"0x{r['pc']:08X}\n"
                )

                f.write(
                    f"  Instruction: "
                    f"0x{r['instr']:08X}\n"
                )

                f.write(
                    f"  Mnemonic   : "
                    f"{r['mnemonic']}\n"
                )

                f.write(
                    f"  Spike RD   : "
                    f"{r['spike_rd']}\n"
                )

                f.write(
                    f"  Spike WE   : "
                    f"{r['spike_rd_we']}\n"
                )

                f.write(
                    f"  Spike Data : "
                    f"{format_value(r['spike_rd_data'])}\n"
                )

                f.write(
                    f"  RTL RD     : "
                    f"{r['rtl_rd']}\n"
                )

                f.write(
                    f"  RTL WE     : "
                    f"{r['rtl_rd_we']}\n"
                )

                f.write(
                    f"  RTL Data   : "
                    f"{format_value(r['rtl_rd_data'])}\n"
                )

                f.write(
                    f"  Error      : "
                    f"{r['error']}\n"
                )

        f.write("\n")

        # ====================================================
        # 5. FINAL RESULT
        # ====================================================

        f.write(
            "5. FINAL ARCHITECTURAL VERIFICATION RESULT\n"
        )

        f.write("-" * 110 + "\n")

        if (
            failed == 0
            and
            len(spike) == len(rtl)
        ):

            f.write(
                "RESULT: PASS\n"
            )

            f.write(
                "The RTL architectural state matches "
                "the Spike reference for all compared "
                "retired instructions.\n"
            )

        else:

            f.write(
                "RESULT: FAIL\n"
            )

            f.write(
                "Architectural mismatches were detected "
                "between the RTL core and Spike reference.\n"
            )

        f.write("\n")

        f.write("=" * 110 + "\n")
        f.write(
            "                         END OF REPORT\n"
        )
        f.write("=" * 110 + "\n")


# ============================================================
# PRINT CONSOLE SUMMARY
# ============================================================

def print_console_summary(
    spike,
    rtl,
    report
):

    print()
    print("=" * 100)
    print(
        "                    SPIKE vs RTL SCOREBOARD"
    )
    print("=" * 100)
    print()

    failures = [
        r
        for r in report
        if r["status"] == "FAIL"
    ]

    # --------------------------------------------------------
    # Print failures
    # --------------------------------------------------------

    for r in failures:

        print(
            f"[FAIL] Instruction #{r['index']}"
        )

        print(
            f"  PC       : "
            f"0x{r['pc']:08X}"
        )

        print(
            f"  INSTR    : "
            f"0x{r['instr']:08X}"
        )

        print(
            f"  Mnemonic : "
            f"{r['mnemonic']}"
        )

        print(
            f"  Spike    : "
            f"RD={r['spike_rd']} "
            f"WE={r['spike_rd_we']} "
            f"DATA={format_value(r['spike_rd_data'])}"
        )

        print(
            f"  RTL      : "
            f"RD={r['rtl_rd']} "
            f"WE={r['rtl_rd_we']} "
            f"DATA={format_value(r['rtl_rd_data'])}"
        )

        print(
            f"  ERROR    : "
            f"{r['error']}"
        )

        print()

    # --------------------------------------------------------
    # Final matrix
    # --------------------------------------------------------

    passed = sum(
        1
        for r in report
        if r["status"] == "PASS"
    )

    failed = sum(
        1
        for r in report
        if r["status"] == "FAIL"
    )

    total = len(report)

    score = (
        passed / total * 100.0
        if total > 0
        else 0.0
    )

    print("=" * 100)
    print(
        "                   FINAL VERIFICATION MATRIX"
    )
    print("=" * 100)

    print(
        f"Spike instructions       : {len(spike)}"
    )

    print(
        f"RTL instructions         : {len(rtl)}"
    )

    print(
        f"Instructions compared    : {total}"
    )

    print(
        f"Passed                   : {passed}"
    )

    print(
        f"Failed                   : {failed}"
    )

    print(
        f"Verification score       : {score:.2f}%"
    )

    if (
        failed == 0
        and
        len(spike) == len(rtl)
    ):

        print(
            "Overall status           : PASS"
        )

    else:

        print(
            "Overall status           : FAIL"
        )

    print("=" * 100)
    print()


# ============================================================
# MAIN
# ============================================================

def main():

    if len(sys.argv) != 3:

        print(
            "Usage:\n"
            "  python3 scoreboard.py "
            "spike_trace.json rtl_retire.csv"
        )

        sys.exit(1)

    spike_file = sys.argv[1]
    rtl_file = sys.argv[2]

    # --------------------------------------------------------
    # Load traces
    # --------------------------------------------------------

    try:

        spike = load_spike(
            spike_file
        )

        rtl = load_rtl(
            rtl_file
        )

    except FileNotFoundError as e:

        print(
            f"ERROR: File not found: {e}"
        )

        sys.exit(1)

    except (
        ValueError,
        KeyError
    ) as e:

        print(
            f"ERROR: Invalid trace format: {e}"
        )

        sys.exit(1)

    # --------------------------------------------------------
    # Build architectural comparison
    # --------------------------------------------------------

    report = build_instruction_report(
        spike,
        rtl
    )

    # --------------------------------------------------------
    # Instruction coverage
    # --------------------------------------------------------

    total_types, passed_types, failed_types = \
        calculate_instruction_coverage(
            report
        )

    # --------------------------------------------------------
    # Output filenames
    # --------------------------------------------------------

    base_name = os.path.splitext(
        os.path.basename(rtl_file)
    )[0]

    csv_report = (
        base_name +
        "_verification_report.csv"
    )

    txt_report = (
        base_name +
        "_verification_report.txt"
    )

    # --------------------------------------------------------
    # Generate reports
    # --------------------------------------------------------

    write_csv_report(
        csv_report,
        report
    )

    write_text_report(
        txt_report,
        spike,
        rtl,
        report,
        total_types,
        passed_types,
        failed_types
    )

    # --------------------------------------------------------
    # Console summary
    # --------------------------------------------------------

    print_console_summary(
        spike,
        rtl,
        report
    )

    print(
        f"Detailed CSV report : "
        f"{csv_report}"
    )

    print(
        f"Detailed text report: "
        f"{txt_report}"
    )

    print()


# ============================================================
# PROGRAM ENTRY
# ============================================================

if __name__ == "__main__":

    main()