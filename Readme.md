Project Development Repository:

Overview:
This repository is a collaborative development environment for our project.
The repository follows a verification-first development workflow. The main branch contains only work that has been tested, verified, and approved according to the benchmarking criteria defined for that specific module.

Branch Structure:
The repository uses separate branches for individual development:

main
├── member-1
├── member-2
├── member-3
└── member-4

Each member should perform their development work on their own branch.
The main branch must not be used for direct development.

Main Branch Policy:
The main branch represents the verified and stable version of the project.
Only work that satisfies the required verification and benchmarking criteria may be merged into main.

  Rules:
    Do not directly push development work to main.
    All new work must be developed on a separate branch.
    Before requesting a merge into main, the developer must verify the work using the benchmarking setup provided for that module.
    The required benchmark/tests for each module are defined inside that module's folder.
    All required tests must pass before the Pull Request can be approved.
    The changes must be reviewed before being merged into main.
    If the benchmark fails, the changes must not be merged until the problem is resolved.
    Existing functionality must continue to pass after new changes are introduced.
