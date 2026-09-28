IMA Core Verification:

To verify the IMA Core, run the RTL simulation using the provided `test_ima.hex` file.
The RTL simulation must generate:
```text
rtl_retire.csv
```
Then run `scoreboard.py` using the generated `rtl_retire.csv` and the provided `spike_trace.json`.
The IMA Core is considered **verified only if the scoreboard reports 100% match.

  Verification Requirements

  * Run RTL with `test_ima.hex`
  * Generate `rtl_retire.csv`
  * Run `scoreboard.py`
  * Compare against `spike_trace.json`
  * 100% match = IMA Core Verified**
  * Any result below 100% must be investigated and fixed before merging into `main`.
