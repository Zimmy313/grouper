library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(ggplot2)
library(readxl)
library(grouper)
library(ompr)
library(ompr.roi)

source("utils.R")

workload_step_title <- function(step, title, subtitle = NULL) {
  div(
    class = "card-title-row",
    span(class = "step-badge", step),
    div(
      h3(title),
      if (!is.null(subtitle)) p(class = "hint", subtitle)
    )
  )
}

single_semester_switch <- function(id) {
  div(
    class = "mode-card",
    div(class = "mode-kicker", "Input Mode"),
    div(
      class = "form-check form-switch workload-switch",
      tags$input(
        class = "form-check-input",
        type = "checkbox",
        role = "switch",
        id = id
      ),
      tags$label(
        class = "form-check-label",
        `for` = id,
        "Single-semester mode"
      )
    ),
    div(
      class = "mode-help",
      "When enabled, previous workload is synthetic: past TA = 0 and past GR = C."
    )
  )
}

settings_grid <- function(..., columns = 4) {
  div(class = paste0("settings-grid settings-grid-", columns), ...)
}

ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    base_font = font_google("Source Sans 3"),
    heading_font = font_google("IBM Plex Sans")
  ),
  tags$head(
    tags$style(HTML(
      ":root {
         --brand-deep: #0f4c81;
         --brand-mid: #2b6cb0;
         --brand-light: #7fb3d5;
         --ink-900: #123a63;
         --ink-700: #355d80;
         --surface: #ffffff;
         --border: #d9e2ec;
         --accent: #e66100;
         --accent-dark: #c95300;
       }
       body {
         background: linear-gradient(180deg, #f4f8fc 0%, #edf4fa 55%, #f7fbff 100%);
       }
       .hero-banner {
         background: linear-gradient(115deg, #0f4c81 0%, #2b6cb0 52%, #7fb3d5 100%);
         color: #ffffff;
         border-radius: 16px;
         padding: 24px 28px;
         margin: 18px 0 16px;
         box-shadow: 0 12px 24px rgba(18, 67, 115, 0.18);
       }
       .hero-banner h1 {
         font-size: 30px;
         margin: 0 0 6px 0;
         letter-spacing: 0.2px;
       }
       .hero-banner p {
         font-size: 16px;
         margin: 0;
         opacity: 0.95;
       }
       .role-strip {
         display: flex;
         flex-wrap: wrap;
         gap: 8px;
         margin-top: 14px;
       }
       .role-pill {
         border: 1px solid rgba(255, 255, 255, 0.35);
         background: rgba(255, 255, 255, 0.15);
         border-radius: 999px;
         color: #ffffff;
         font-size: 13px;
         font-weight: 600;
         padding: 5px 10px;
       }
       .panel-card {
         background: #ffffff;
         border: 1px solid #d9e2ec;
         border-radius: 16px;
         padding: 18px;
         margin-bottom: 16px;
         box-shadow: 0 10px 26px rgba(15, 76, 129, 0.07);
       }
       .panel-card h3 {
         margin: 0;
         color: #123a63;
       }
       .card-title-row {
         display: flex;
         gap: 12px;
         align-items: flex-start;
         margin-bottom: 14px;
       }
       .step-badge {
         align-items: center;
         background: rgba(15, 76, 129, 0.1);
         border: 1px solid rgba(15, 76, 129, 0.2);
         border-radius: 999px;
         color: #0f4c81;
         display: inline-flex;
         flex: 0 0 auto;
         font-weight: 700;
         height: 30px;
         justify-content: center;
         width: 30px;
       }
       .hint {
         color: #355d80;
         font-size: 14px;
       }
       .status-ok {
         color: #0b7d44;
         font-weight: 600;
       }
       .status-warn {
         color: #a04a00;
         font-weight: 600;
       }
       .btn-accent {
         background-color: #e66100;
         border-color: #c95300;
         color: #ffffff;
       }
       .btn-accent:hover {
         background-color: #c95300;
         border-color: #b54a00;
         color: #ffffff;
       }
       .mode-card,
       .file-card,
       .settings-card {
         background: #f8fbfe;
         border: 1px solid #d9e2ec;
         border-radius: 14px;
         padding: 14px;
       }
       .mode-card,
       .file-card {
         min-height: 100%;
       }
       .file-template-row {
         display: flex;
         margin-bottom: 16px;
       }
       .file-template-row .btn {
         white-space: normal;
       }
       .file-upload-grid {
         align-items: start;
         display: grid;
         gap: 14px;
         grid-template-columns: repeat(2, minmax(0, 1fr));
       }
       .file-upload-cell {
         min-width: 0;
       }
       .file-upload-cell .shiny-input-container {
         margin-bottom: 0;
         max-width: none;
         width: 100%;
       }
       .file-upload-cell label {
         min-height: 28px;
       }
       .file-upload-cell .input-group {
         width: 100%;
       }
       .mode-kicker,
       .setting-kicker {
         color: #355d80;
         font-size: 12px;
         font-weight: 700;
         letter-spacing: 0.06em;
         margin-bottom: 8px;
         text-transform: uppercase;
       }
       .workload-switch {
         margin-bottom: 8px;
       }
       .workload-switch .form-check-input {
         height: 1.35rem;
         width: 2.6rem;
       }
       .workload-switch .form-check-input:checked {
         background-color: #e66100;
         border-color: #e66100;
       }
       .workload-switch .form-check-label {
         color: #123a63;
         font-weight: 700;
         margin-left: 6px;
       }
       .mode-help {
         color: #355d80;
         font-size: 13px;
         line-height: 1.35;
       }
       .action-row {
         align-items: center;
         display: flex;
         flex-wrap: wrap;
         gap: 10px;
         margin-top: 10px;
       }
       .status-message {
         margin-top: 12px;
       }
       .status-message .status-ok,
       .status-message .status-warn,
       .run-message .status-ok,
       .run-message .status-warn {
         border-radius: 12px;
         display: block;
         padding: 10px 12px;
       }
       .status-message .status-ok,
       .run-message .status-ok {
         background: rgba(11, 125, 68, 0.1);
         border: 1px solid rgba(11, 125, 68, 0.22);
       }
       .status-message .status-warn,
       .run-message .status-warn {
         background: rgba(160, 74, 0, 0.1);
         border: 1px solid rgba(160, 74, 0, 0.22);
       }
       .settings-tabs {
         margin-top: 8px;
       }
       .settings-tabs summary {
         color: #123a63;
         cursor: pointer;
         font-weight: 700;
       }
       .settings-tabs .tab-content {
         background: #ffffff;
         border: 1px solid #d9e2ec;
         border-top: 0;
         border-radius: 0 0 14px 14px;
         padding: 14px;
       }
       .settings-grid {
         align-items: start;
         display: grid;
         gap: 12px;
         margin-bottom: 12px;
       }
       .settings-grid-2 {
         grid-template-columns: repeat(2, minmax(0, 1fr));
       }
       .settings-grid-4 {
         grid-template-columns: repeat(4, minmax(0, 1fr));
       }
       .settings-grid .shiny-input-container {
         margin-bottom: 0;
         max-width: none;
         width: 100%;
       }
       .settings-grid .form-group {
         margin-bottom: 0;
       }
       .metric-grid {
         display: grid;
         gap: 12px;
         grid-template-columns: repeat(4, minmax(0, 1fr));
       }
       .metric-card {
         background: #ffffff;
         border: 1px solid #d9e2ec;
         border-radius: 14px;
         display: flex;
         flex-direction: column;
         justify-content: space-between;
         min-height: 92px;
         min-width: 0;
         padding: 14px;
         box-shadow: 0 8px 18px rgba(15, 76, 129, 0.05);
       }
       .metric-card-accent {
         border-color: rgba(230, 97, 0, 0.35);
       }
       .metric-label {
         color: #355d80;
         display: block;
         font-size: 12px;
         font-weight: 700;
         letter-spacing: 0.04em;
         text-transform: uppercase;
       }
       .metric-value {
         color: #123a63;
         display: block;
         font-size: 22px;
         font-weight: 700;
         margin-top: 4px;
         overflow-wrap: anywhere;
       }
       @media (max-width: 991px) {
         .file-upload-grid,
         .settings-grid-4,
         .metric-grid {
           grid-template-columns: repeat(2, minmax(0, 1fr));
         }
       }
       @media (max-width: 575px) {
         .file-upload-grid,
         .settings-grid-2,
         .settings-grid-4,
         .metric-grid {
           grid-template-columns: 1fr;
         }
       }
      "
    ))
  ),

  # ---- Step 1: Upload & Validate ----
  div(
    class = "hero-banner",
    h1("Multi-role Workload Allocation"),
    p("Balance teaching support, grading work, and lighter residual duties across workload history, preferences, and cohort protections."),
    div(
      class = "role-strip",
      span(class = "role-pill", "TA: tutorials, labs, teaching support"),
      span(class = "role-pill", "GR: marking and assessment"),
      span(class = "role-pill", "E: invigilation, consultation, admin")
    )
  ),

  # ---- Step 2: Parameter Selection & Run ----
  div(
    class = "panel-card",
    workload_step_title(
      "1",
      "Upload And Load",
      "Use the current semester template. Upload previous assign_job output unless single-semester mode is selected."
    ),
    fluidRow(
      column(
        width = 4,
        single_semester_switch("single_semester")
      ),
      column(
        width = 8,
        div(
          class = "file-card",
          div(class = "setting-kicker", "Files"),
          div(
            class = "file-template-row",
            downloadButton("download_template", "Download current_semester.xlsx")
          ),
          div(
            class = "file-upload-grid",
            div(
              class = "file-upload-cell",
              fileInput(
                "current_file",
                "Current semester file (XLSX)",
                accept = c(".xlsx")
              )
            ),
            div(
              class = "file-upload-cell",
              conditionalPanel(
                condition = "!input.single_semester",
                fileInput(
                  "past_file",
                  "Previous semester model output (XLSX)",
                  accept = c(".xlsx")
                )
              )
            )
          ),
          div(
            class = "action-row",
            actionButton("validate_inputs", "Load Inputs", class = "btn btn-primary")
          )
        )
      )
    ),
    htmlOutput("validation_message", class = "status-message"),
    conditionalPanel(
      condition = "output.has_validated == 'true'",
      hr(),
      tabsetPanel(
        tabPanel("Students preview", DTOutput("students_preview")),
        tabPanel("Demand preview", DTOutput("demand_preview")),
        tabPanel("Previous output preview", DTOutput("past_preview"))
      )
    )
  ),

  div(
    class = "panel-card",
    workload_step_title(
      "2",
      "Configure And Run",
      "Start with the core settings. Open advanced settings when you need role-specific tradeoffs."
    ),
    div(
      class = "settings-card",
      div(class = "setting-kicker", "Core Settings"),
      fluidRow(
        column(
          width = 4,
          selectInput(
            "solver",
            "Solver",
            choices = c("gurobi", "glpk", "highs"),
            selected = "gurobi"
          )
        ),
        column(
          width = 4,
          numericInput("capacity", "C (semester cap)", value = 4, min = 1, step = 1)
        ),
        column(
          width = 4,
          numericInput("e_max", "e_max", value = 1, min = 0, step = 1)
        )
      )
    ),

    tags$details(
      class = "settings-tabs",
      tags$summary("Advanced Parameters"),
      tabsetPanel(
        tabPanel(
          "Fairness & Preferences",
          settings_grid(
            numericInput("alpha_ta", "alpha_ta", value = 2, min = 0, step = 0.1),
            numericInput("alpha_gr", "alpha_gr", value = NA, min = 0, step = 0.1),
            numericInput("beta_ta", "beta_ta", value = 1, min = 0, step = 0.1),
            numericInput("beta_gr", "beta_gr", value = NA, min = 0, step = 0.1)
          )
        ),
        tabPanel(
          "Protection",
          settings_grid(
            numericInput("rho_ta", "rho_ta", value = 10, min = 0, step = 0.1),
            numericInput("rho_gr", "rho_gr", value = NA, min = 0, step = 0.1),
            selectInput("protected_year_ta", "protected_year_ta", choices = 1:4, selected = 1),
            selectInput("protected_year_gr", "protected_year_gr", choices = 1:4, selected = 1)
          ),
          settings_grid(
            numericInput("ta_protected_max", "ta_protected_max", value = 1, min = 0, step = 1),
            numericInput("gr_protected_max", "gr_protected_max", value = 1, min = 0, step = 1),
            columns = 2
          )
        ),
        tabPanel(
          "Bounds",
          settings_grid(
            numericInput("ta_min", "ta_min", value = NA, min = 0, step = 1),
            numericInput("ta_max", "ta_max", value = NA, min = 0, step = 1),
            numericInput("gr_min", "gr_min", value = NA, min = 0, step = 1),
            numericInput("gr_max", "gr_max", value = NA, min = 0, step = 1)
          ),
          settings_grid(
            numericInput("e_min", "e_min", value = NA, min = 0, step = 1),
            numericInput("phi", "phi", value = 1, min = 0, step = 0.1),
            columns = 2
          )
        ),
        tabPanel(
          "E Seniority",
          settings_grid(
            numericInput("s_year1", "s_year1", value = -1, step = 0.1),
            numericInput("s_year2", "s_year2", value = 0, step = 0.1),
            numericInput("s_year3", "s_year3", value = 1, step = 0.1),
            numericInput("s_year4", "s_year4", value = 2, step = 0.1)
          ),
          settings_grid(
            numericInput("time_limit", "Time limit (sec, Gurobi)", value = 0, min = 0, step = 1),
            numericInput("iteration_limit", "Iteration limit (Gurobi)", value = 0, min = 0, step = 1),
            columns = 2
          )
        )
      )
    ),

    div(
      class = "action-row",
      actionButton("run_model", "Run Optimisation", class = "btn btn-accent"),
      htmlOutput("run_message", class = "run-message")
    )
  ),

  # ---- Step 3: Post-run Summary ----
  conditionalPanel(
    condition = "output.has_run == 'true'",
    div(
      class = "panel-card",
      workload_step_title(
        "3",
        "Results Overview",
        "Review the optimisation status and role spread before downloading outputs."
      ),
      uiOutput("metric_cards")
    ),
    fluidRow(
      column(
        width = 4,
        div(
          class = "panel-card",
          h3("Step 3: Run Summary"),
          DTOutput("run_summary")
        )
      ),
      column(
        width = 8,
        div(
          class = "panel-card",
          h3("Step 3: Workload Distribution"),
          plotOutput("workload_plot", height = "460px")
        )
      )
    )
  ),

  # ---- Step 4: Downloadable Outputs ----
  conditionalPanel(
    condition = "output.has_run == 'true'",
    div(
      class = "panel-card",
      h3("Step 4: Outputs"),
      p(class = "hint", "Primary output uses assign_job format for direct reuse in future semesters."),
      fluidRow(
        column(width = 3, downloadButton("download_assignment", "Download Assignment XLSX"))
      ),
      br(),
      tabsetPanel(
        tabPanel("Assignment table", DTOutput("assignment_table")),
        tabPanel("Preference attainment", DTOutput("preference_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  # ---- Reactive State ----
  validated_data <- reactiveVal(NULL)
  run_data <- reactiveVal(NULL)

  validation_message <- reactiveVal("<span class='status-warn'>Upload the current semester file and click Load Inputs.</span>")
  run_message <- reactiveVal("<span class='status-warn'>No run has been executed yet.</span>")

  # ---- Utility: convert optional numeric input to NULL when blank ----
  to_nullable_number <- function(x) {
    if (is.null(x) || is.na(x)) {
      return(NULL)
    }
    as.numeric(x)
  }

  # ---- Reset run state when uploads change ----
  observeEvent(list(input$current_file, input$past_file, input$single_semester), {
    validated_data(NULL)
    run_data(NULL)
    validation_message("<span class='status-warn'>Inputs changed. Click Load Inputs again.</span>")
    run_message("<span class='status-warn'>No run has been executed yet.</span>")
  }, ignoreInit = TRUE)

  output$validation_message <- renderUI({
    HTML(validation_message())
  })

  output$run_message <- renderUI({
    HTML(run_message())
  })

  output$has_run <- renderText({
    if (is.null(run_data())) {
      "false"
    } else {
      "true"
    }
  })
  outputOptions(output, "has_run", suspendWhenHidden = FALSE)

  output$has_validated <- renderText({
    if (is.null(validated_data())) {
      "false"
    } else {
      "true"
    }
  })
  outputOptions(output, "has_validated", suspendWhenHidden = FALSE)

  # ---- Template download ----
  output$download_template <- downloadHandler(
    filename = function() {
      "current_semester_template.xlsx"
    },
    content = function(file) {
      template_path <- file.path(getwd(), "current_semester_template.xlsx")
      if (!file.exists(template_path)) {
        stop("Template file is missing in app directory: current_semester_template.xlsx")
      }
      file.copy(template_path, file, overwrite = TRUE)
    },
    contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  )

  # ---- Load step ----
  observeEvent(input$validate_inputs, {
    run_data(NULL)
    run_message("<span class='status-warn'>No run has been executed yet.</span>")

    single_semester <- isTRUE(input$single_semester)
    needs_past <- !single_semester

    if (is.null(input$current_file$datapath) ||
        (needs_past && is.null(input$past_file$datapath))) {
      validated_data(NULL)
      validation_message("<span class='status-warn'>Please upload the required file(s) before validation.</span>")
      return()
    }

    out <- tryCatch({
      current <- validate_current_semester_file(input$current_file$datapath)
      prev <- if (needs_past) {
        read_uploaded_table(input$past_file$datapath)
      } else {
        NULL
      }

      list(
        students = current$students,
        demand = current$demand,
        past_output = prev,
        single_semester = single_semester
      )
    }, error = function(e) {
      validation_message(
        paste0("<span class='status-warn'>Input load failed: ", htmltools::htmlEscape(conditionMessage(e)), "</span>")
      )
      NULL
    })

    if (is.null(out)) {
      validated_data(NULL)
      return()
    }

    validated_data(out)
    validation_message(
      paste0(
        "<span class='status-ok'>Inputs loaded: ",
        nrow(out$students), " students, ",
        nrow(out$demand), " courses, ",
        if (out$single_semester) {
          "single-semester mode.</span>"
        } else {
          paste0(nrow(out$past_output), " rows in previous output.</span>")
        }
      )
    )
  })

  # ---- Run step ----
  observeEvent(input$run_model, {
    req(validated_data())

    run_result <- tryCatch({
      s_scores <- c(input$s_year1, input$s_year2, input$s_year3, input$s_year4)
      settings <- list(
        ta_protected_max = to_nullable_number(input$ta_protected_max),
        gr_protected_max = to_nullable_number(input$gr_protected_max),
        e_max = to_nullable_number(input$e_max),
        ta_min = to_nullable_number(input$ta_min),
        ta_max = to_nullable_number(input$ta_max),
        gr_min = to_nullable_number(input$gr_min),
        gr_max = to_nullable_number(input$gr_max),
        e_min = to_nullable_number(input$e_min),
        alpha_ta = to_nullable_number(input$alpha_ta),
        alpha_gr = to_nullable_number(input$alpha_gr),
        beta_ta = to_nullable_number(input$beta_ta),
        beta_gr = to_nullable_number(input$beta_gr),
        phi = to_nullable_number(input$phi),
        rho_ta = to_nullable_number(input$rho_ta),
        rho_gr = to_nullable_number(input$rho_gr),
        protected_year_ta = as.integer(input$protected_year_ta),
        protected_year_gr = as.integer(input$protected_year_gr)
      )

      prep <- prepare_multirole_run_inputs(
        students = validated_data()$students,
        demand = validated_data()$demand,
        previous_output = validated_data()$past_output,
        C = input$capacity,
        single_semester = validated_data()$single_semester,
        s = s_scores
      )

      model <- grouper::prepare_multirole_model(
        df_list = prep$df_list,
        ta_protected_max = settings$ta_protected_max,
        gr_protected_max = settings$gr_protected_max,
        e_max = settings$e_max,
        ta_min = settings$ta_min,
        ta_max = settings$ta_max,
        gr_min = settings$gr_min,
        gr_max = settings$gr_max,
        e_min = settings$e_min,
        alpha_ta = settings$alpha_ta,
        alpha_gr = settings$alpha_gr,
        beta_ta = settings$beta_ta,
        beta_gr = settings$beta_gr,
        phi = settings$phi,
        rho_ta = settings$rho_ta,
        rho_gr = settings$rho_gr,
        protected_year_ta = settings$protected_year_ta,
        protected_year_gr = settings$protected_year_gr
      )

      roi_control <- make_roi_control(
        solver = input$solver,
        time_limit = input$time_limit,
        iteration_limit = input$iteration_limit
      )
      result <- ompr::solve_model(model, roi_control)

      assignment_tbl <- grouper::assign_job(
        model_result = result,
        student_df = prep$students,
        course_codes = prep$course_codes,
        name_col = "Name"
      )

      # Reuse assign_job output for student-level TA/GR/E summary.
      alloc_summary <- summarise_assignment_from_job_output(assignment_tbl, prep$students)
      pref_attainment <- compute_preference_attainment(
        model_result = result,
        p_ta_mat = prep$p_ta_mat,
        p_gr_mat = prep$p_gr_mat,
        total_ta_demand = sum(prep$demand$TA),
        total_gr_demand = sum(prep$demand$GR)
      )
      student_diag <- compute_student_diagnostics(
        alloc_summary = alloc_summary,
        t1 = prep$df_list$t1,
        g1 = prep$df_list$g1
      )

      list(
        summary_tbl = compute_run_summary(result, settings = settings),
        assignment_tbl = assignment_tbl,
        preference_tbl = pref_attainment,
        student_diag = student_diag,
        workload_plot = plot_workload_distribution(
          student_diag,
          C = prep$df_list$C,
          single_semester = prep$single_semester
        ),
        solver_status = as.character(result$status)
      )
    }, error = function(e) {
      run_message(
        paste0("<span class='status-warn'>Run failed: ", htmltools::htmlEscape(conditionMessage(e)), "</span>")
      )
      NULL
    })

    if (is.null(run_result)) {
      run_data(NULL)
      return()
    }

    run_data(run_result)

    solver_note <- ""
    if (input$solver != "gurobi" && ((input$time_limit > 0) || (input$iteration_limit > 0))) {
      solver_note <- " Time/iteration limits are applied only for Gurobi in this app."
    }

    run_message(
      paste0(
        "<span class='status-ok'>Run completed. Solver status: ",
        htmltools::htmlEscape(run_result$solver_status),
        ".", solver_note, "</span>"
      )
    )
  })

  output$students_preview <- renderDT({
    req(validated_data())
    datatable(validated_data()$students, options = list(scrollX = TRUE, pageLength = 6))
  })

  output$demand_preview <- renderDT({
    req(validated_data())
    datatable(validated_data()$demand, options = list(scrollX = TRUE, pageLength = 6))
  })

  output$past_preview <- renderDT({
    req(validated_data())
    if (is.null(validated_data()$past_output)) {
      return(datatable(
        data.frame(note = "Single-semester mode uses synthetic past workload."),
        rownames = FALSE,
        options = list(dom = "t")
      ))
    }
    datatable(validated_data()$past_output, options = list(scrollX = TRUE, pageLength = 6))
  })

  output$run_summary <- renderDT({
    req(run_data())
    datatable(
      run_data()$summary_tbl,
      rownames = FALSE,
      options = list(dom = "t", ordering = FALSE)
    )
  })

  output$metric_cards <- renderUI({
    req(run_data())
    run_metric_cards(run_data()$summary_tbl)
  })

  output$workload_plot <- renderPlot({
    req(run_data())
    run_data()$workload_plot
  })

  output$assignment_table <- renderDT({
    req(run_data())
    datatable(run_data()$assignment_tbl, options = list(scrollX = TRUE, pageLength = 12))
  })

  output$preference_table <- renderDT({
    req(run_data())
    datatable(run_data()$preference_tbl, options = list(dom = "t", ordering = FALSE))
  })

  output$download_assignment <- downloadHandler(
    filename = function() {
      paste0("multirole_assignment_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx")
    },
    content = function(file) {
      req(run_data())
      writexl::write_xlsx(list(allocation = run_data()$assignment_tbl), path = file)
    }
  )
}

shinyApp(ui = ui, server = server)
