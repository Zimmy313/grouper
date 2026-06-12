---
output: pdf_document
fontsize: 12pt
---

\thispagestyle{empty}
2026-06-12

Editor-in-Chief  
The R Journal  
\bigskip

Dear Editor,
\bigskip

Please consider our manuscript titled "Grouper: Optimal Assignment Workflows for Higher Education" for publication in *The R Journal*.

This manuscript presents `grouper`, an R package for higher-education allocation workflows based on mixed-integer optimization. The package supports three recurring planning tasks: assigning students to groups and topics while promoting diversity, assigning self-formed groups to topic slots based on stated preferences, and allocating multi-role workload under fairness, preference, and priority constraints. The paper emphasizes structured inputs, configurable objective functions, solver-backed model construction, and interpretable outputs that map back to teaching and administrative records.

We believe this submission is suitable for *The R Journal* because it centers on package design, implementation, and reproducible R workflows. The article is intended for R users in higher-education institutions, including instructors and administrators who need practical allocation tools but may not want to write mixed-integer models directly. It also shows how `grouper` builds on existing R optimization infrastructure, including `ompr`, `ompr.roi`, and ROI-backed solvers.

The submission includes the manuscript source, bibliography, generated PDF/TeX/R files, anonymized data for AY2420, AY2510, and AY2520, generated figures, a package list, reproducibility scripts, and the consolidated Shiny frontend source. The scripts regenerate the cross-semester results and figures, run the separate solver benchmark, and provide print-only checks for the manual objective and hyperparameter sensitivity.

\bigskip
\bigskip

Regards,  
Mingyuan Zhang (corresponding author)  
Kevin Lam  
Vik Gopal  
National University of Singapore  
mingyuan.z@nus.edu.sg
