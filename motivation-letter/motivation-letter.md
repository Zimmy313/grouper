---
output: pdf_document
fontsize: 12pt
---

\thispagestyle{empty}
2026-07-13

Editor-in-Chief  
The R Journal  
\bigskip

Dear Editor,
\bigskip

Please consider our manuscript titled "Grouper: Optimal Assignment Workflows for Higher Education" for publication in *The R Journal*.

This manuscript presents `grouper`, a CRAN package for allocation workflows based on mixed-integer optimization. The package currently supports three recurring higher-education planning tasks: assigning students to groups and topics while promoting diversity, assigning self-formed groups to topic slots based on stated preferences, and allocating multi-role workloads under fairness, preference, and priority constraints. The paper emphasizes structured inputs, configurable objective functions, solver-backed model construction, and interpretable outputs that map directly back to teaching and administrative records.

Although the package is motivated by higher-education applications, its underlying workflow is relevant to a broader range of grouping and assignment problems. Users outside higher education may adapt the package to settings such as team formation, personnel allocation, or task assignment. The package is designed as an extensible framework. We welcome additional allocation models and application-specific formulations, and intend to continue expanding the package as new use cases and contributions emerge.

We believe this submission is suitable for *The R Journal* because it centers on package design, implementation, extensibility, and reproducible R workflows. The article is intended both for users who need practical allocation tools without writing mixed-integer optimization models from scratch and for developers who may wish to extend the framework with new objectives, constraints, and domain-specific models. It also demonstrates how `grouper` builds on existing R optimization infrastructure, including `ompr`, `ompr.roi`, and ROI-backed solvers.

The submission includes the manuscript source, bibliography, generated PDF, TeX and R files, anonymized data for AY2420, AY2510, and AY2520, generated figures, a package list, reproducibility scripts, and the source code for the consolidated Shiny front end. The scripts reproduce the cross-semester results and figures, run the separate solver benchmark, and provide print-only checks for the manually calculated objective values and hyperparameter sensitivity analysis.

\bigskip
\bigskip

Regards,  
Mingyuan Zhang (corresponding author)  
Kevin Lam  
Vik Gopal  
National University of Singapore  
e0970135@u.nus.edu