using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the Mark Completions page.
    // Three-step workflow: select class, select task, mark or unmark students.
    // State is maintained in ViewState between postbacks.
    //
    // Binding happens in two passes each postback, and this is deliberate, not duplication:
    // 1. Page_Load rebinds the repeaters using ViewState as it was BEFORE this postback's
    //    click is processed. This has to happen here because the ASP.NET page lifecycle
    //    raises the postback Command event (ClassCommand/TaskCommand/StudentCommand) AFTER
    //    Page_Load, and the framework can only route that event to a LinkButton inside a
    //    Repeater if the Repeater's child controls already exist in the tree at that point.
    // 2. Page_PreRender runs after the Command event has updated ViewState, and rebinds the
    //    same panels again using the NEW values. This is what the user actually sees, so it
    //    is what makes a class/task/mark click take effect on the same postback instead of
    //    needing a second click to "catch up".
    public partial class MarkCompletions : Page
    {
        // - Properties -

        /// <summary>
        /// Currently selected class ID, stored in ViewState so it survives postbacks.
        /// </summary>
        public int SelectedClassID
        {
            get { return ViewState["SelectedClassID"] != null ? Convert.ToInt32(ViewState["SelectedClassID"]) : 0; }
            set { ViewState["SelectedClassID"] = value; }
        }

        /// <summary>
        /// Currently selected task ID, stored in ViewState so it survives postbacks.
        /// </summary>
        public int SelectedTaskID
        {
            get { return ViewState["SelectedTaskID"] != null ? Convert.ToInt32(ViewState["SelectedTaskID"]) : 0; }
            set { ViewState["SelectedTaskID"] = value; }
        }

        /// <summary>
        /// Completion percentage for the progress bar.
        /// </summary>
        public double CompletionPct { get; set; }

        // - Page lifecycle -

        /// <summary>
        /// Enforces the teacher-only session guard and rebuilds the repeater control tree
        /// using ViewState as it stood before this postback's click, so the framework can
        /// route the click's Command event correctly.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        // Runs before the postback Command event (if any). On a postback, this only
        // rebuilds the repeater control tree using the state as it was before the click,
        // which is required so the framework can find the clicked LinkButton and raise its
        // Command event. Any decision that depends on the RESULT of that click (which panel
        // to show, which row is highlighted, refreshed completion counts) happens later in
        // Page_PreRender, not here, since the click hasn't been processed yet at this point.
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> sidebarClasses = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = sidebarClasses;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                // Support arriving pre-scoped to a class (for example from
                // TeacherClassPage's "Mark Completions" button, which passes
                // ?ClassID=), so the page can open directly at step 2 instead
                // of making the teacher pick the class again. This has to be
                // set here, in the !IsPostBack branch of Page_Load, and not
                // in Page_PreRender, so that it only ever applies once on a
                // fresh request, exactly like the rest of the ViewState-driven
                // step state. If the ClassID is missing, unparseable, or not
                // owned by this teacher, SelectedClassID is simply left at its
                // default of 0 and the normal step 1 class-picker behaviour
                // applies, no error is shown for an invalid or absent value.
                int queryClassID;
                if (int.TryParse(Request.QueryString["ClassID"], out queryClassID) && queryClassID > 0
                    && SchoolClass.IsOwnedByTeacher(queryClassID, teacherID))
                {
                    SelectedClassID = queryClassID;
                }

                LoadClassSelector(teacherID);
            }
            else
            {
                // Rebind using pre-click ViewState so postback event routing works.
                // Do not set panel Visible flags here based on these values, Page_PreRender
                // does that once using post-click state.
                LoadClassSelector(teacherID);
                if (SelectedClassID > 0) LoadTaskSelector(SelectedClassID);
                if (SelectedTaskID > 0) LoadStudentCompletions(SelectedTaskID);
            }
        }

        /// <summary>
        /// Refreshes the class, task and student panels using SelectedClassID/SelectedTaskID
        /// as they stand after any Command event has run, so the page always reflects the
        /// current postback's click rather than the previous one.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        // Runs after any Command event handler has finished, on every request (initial load
        // and postback alike). This is the single place that decides what the user actually
        // sees, using SelectedClassID/SelectedTaskID as they stand right now, which for a
        // postback includes whatever change the click just made. Doing this here instead of
        // Page_Load is the fix for the "takes two clicks" bug: it guarantees rendering always
        // reflects the same postback that changed the state, not the previous one.
        protected void Page_PreRender(object sender, EventArgs e)
        {
            int teacherID = Convert.ToInt32(Session["UserID"]);

            LoadClassSelector(teacherID);
            btnChangeClass.Visible = SelectedClassID > 0;

            if (SelectedClassID > 0)
            {
                LoadTaskSelector(SelectedClassID);
            }

            // pnlSuccess is kept in the DOM for the whole of step 3 (reserving its layout
            // space) rather than being toggled visible only once a mark actually succeeds.
            // If it only appeared on the first successful mark, that would insert a new
            // element and change the page's total height right under
            // MaintainScrollPositionOnPostBack, which restores a fixed pixel offset rather
            // than "the same visible content", producing a small scroll jump on that first
            // click only. Reserving the space up front (its paint is toggled separately with
            // the alert-hidden CSS class in ClassCommand/TaskCommand/StudentCommand) means the
            // page height never changes between the first and later marks.
            if (SelectedTaskID > 0)
            {
                LoadStudentCompletions(SelectedTaskID);
                pnlSuccess.Visible = true;
            }
            else
            {
                pnlSuccess.Visible = false;
            }
        }

        // - Methods -

        /// <summary>
        /// Loads the class selector grid with student and task counts.
        /// Also drives the "selected" highlight on the clicked class card and the
        /// lblSelectedClass caption, both of which read SelectedClassID at DataBind time,
        /// so this must be called again after SelectedClassID changes for them to update.
        /// </summary>
        /// <param name="teacherID">The logged-in teacher whose classes should be listed.</param>
        private void LoadClassSelector(int teacherID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT c.ClassID, c.ClassName, " +
                    "(SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = c.ClassID) AS StudentCount, " +
                    "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = c.ClassID) AS TaskCount " +
                    "FROM Classes c WHERE c.TeacherID = @TeacherID ORDER BY c.ClassName";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            rptClasses.DataSource = dt;
            rptClasses.DataBind();

            lblSelectedClass.Text = "";
            if (SelectedClassID > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    if (Convert.ToInt32(row["ClassID"]) == SelectedClassID)
                    {
                        lblSelectedClass.Text = "Selected: " + row["ClassName"].ToString();
                        break;
                    }
                }
            }
        }

        /// <summary>
        /// Loads the task table for the selected class.
        /// Also drives the "selected" row/button state and lblSelectedTask caption, both of
        /// which read SelectedTaskID at DataBind time, so this must be called again after
        /// SelectedTaskID changes for them to update.
        /// </summary>
        /// <param name="classID">The class whose tasks should be listed.</param>
        private void LoadTaskSelector(int classID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();
            int totalStudents = 0;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                using (SqlCommand cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = @ClassID", conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    totalStudents = Convert.ToInt32(cmd.ExecuteScalar());
                }

                string sql =
                    "SELECT ht.TaskID, ht.Title, ht.Subject, ht.DueDate, ht.PriorityLevel, " +
                    "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS CompletionCount, " +
                    "@TotalStudents AS TotalStudents " +
                    "FROM HomeworkTasks ht " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID " +
                    "WHERE ht.ClassID = @ClassID " +
                    "GROUP BY ht.TaskID, ht.Title, ht.Subject, ht.DueDate, ht.PriorityLevel " +
                    "ORDER BY ht.DueDate ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@TotalStudents", totalStudents);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            rptTasks.DataSource = dt;
            rptTasks.DataBind();
            pnlTaskSelector.Visible = true;
            pnlNoTasks.Visible = dt.Rows.Count == 0;

            lblSelectedTask.Text = "";
            if (SelectedTaskID > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    if (Convert.ToInt32(row["TaskID"]) == SelectedTaskID)
                    {
                        lblSelectedTask.Text = "Selected: " + row["Title"].ToString();
                        break;
                    }
                }
            }
        }

        /// <summary>
        /// Loads the student completion list for the selected task.
        /// Queries CompletionRecords fresh on every call, so calling this again in
        /// Page_PreRender after a Mark/Unmark click is what makes the status badge and
        /// completion bar reflect the change on the same postback instead of the next one.
        /// </summary>
        /// <param name="taskID">The task whose per-student completion status should be shown.</param>
        private void LoadStudentCompletions(int taskID)
        {
            int classID = SelectedClassID;
            List<PaceUser> students = SchoolClass.GetEnrolledStudents(classID);

            if (students.Count == 0)
            {
                pnlStudents.Visible = true;
                pnlNoStudents.Visible = true;
                rptStudents.DataSource = null;
                rptStudents.DataBind();
                CompletionPct = 0;
                lblCompletionSummary.Text = "";
                return;
            }

            DataTable dt = new DataTable();
            dt.Columns.Add("StudentID", typeof(int));
            dt.Columns.Add("FullName", typeof(string));
            dt.Columns.Add("MarkedComplete", typeof(bool));

            int completedCount = 0;
            foreach (PaceUser student in students)
            {
                bool done = CompletionRecord.IsComplete(taskID, student.UserID);
                if (done) completedCount++;
                dt.Rows.Add(student.UserID, student.FullName, done);
            }

            CompletionPct = students.Count > 0
                ? Math.Round((double)completedCount / students.Count * 100, 1) : 0;

            lblCompletionSummary.Text = completedCount + " of " + students.Count + " complete";

            rptStudents.DataSource = dt;
            rptStudents.DataBind();
            pnlStudents.Visible = true;
            pnlNoStudents.Visible = false;
        }

        /// <summary>
        /// Handles a class card click. Only updates state here, does not touch panel
        /// visibility or rebind data, Page_PreRender does that once with the new
        /// SelectedClassID so step 2 appears on this same postback.
        /// </summary>
        /// <param name="sender">The Repeater raising the command.</param>
        /// <param name="e">Command arguments, carrying the clicked class's ID.</param>
        protected void ClassCommand(object sender, CommandEventArgs e)
        {
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";
            SelectedClassID = Convert.ToInt32(e.CommandArgument);
            SelectedTaskID = 0;
            pnlStudents.Visible = false;
        }

        /// <summary>
        /// Handles a task row click. Only updates state here, Page_PreRender rebinds the
        /// student list against the new SelectedTaskID so step 3 appears on this same
        /// postback.
        /// </summary>
        /// <param name="sender">The Repeater raising the command.</param>
        /// <param name="e">Command arguments, carrying the clicked task's ID.</param>
        protected void TaskCommand(object sender, CommandEventArgs e)
        {
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";
            SelectedTaskID = Convert.ToInt32(e.CommandArgument);
        }

        /// <summary>
        /// Handles a Mark/Unmark click. Only writes to CompletionRecords here,
        /// Page_PreRender re-runs LoadStudentCompletions afterward, which re-queries the
        /// database so the status badge and completion bar reflect this change on this same
        /// postback instead of requiring a second click.
        /// </summary>
        /// <param name="sender">The Repeater raising the command.</param>
        /// <param name="e">Command arguments, carrying the clicked student's ID and Mark/Unmark command name.</param>
        protected void StudentCommand(object sender, CommandEventArgs e)
        {
            int studentID = Convert.ToInt32(e.CommandArgument);
            int taskID = SelectedTaskID;
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";

            if (e.CommandName == "Mark")
            {
                bool ok = CompletionRecord.MarkComplete(taskID, studentID);
                if (ok) { lblSuccess.Text = "Student marked as complete."; pnlSuccess.CssClass = "alert-success-wrap"; }
            }
            else if (e.CommandName == "Unmark")
            {
                bool ok = CompletionRecord.UnmarkComplete(taskID, studentID);
                if (ok) { lblSuccess.Text = "Completion mark removed."; pnlSuccess.CssClass = "alert-success-wrap"; }
            }
        }

        /// <summary>
        /// Handles the "Change Class" click, which is only visible once a class has been
        /// selected (Page_PreRender). Resets ViewState back to "nothing selected" and clears
        /// the step 2/3 panels explicitly, since Page_PreRender only refreshes those panels
        /// when SelectedClassID/SelectedTaskID are greater than zero, so with both back at 0
        /// their prior Visible=true from ViewState would otherwise persist and stay stuck
        /// showing stale content on the same postback that reset the selection.
        /// </summary>
        /// <param name="sender">The Change Class control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnChangeClass_Click(object sender, EventArgs e)
        {
            SelectedClassID = 0;
            SelectedTaskID = 0;
            pnlTaskSelector.Visible = false;
            pnlStudents.Visible = false;
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";
        }

        /// <summary>
        /// Returns the CSS class for each step.
        /// Step 1: active until class chosen, then selected (not a done checkmark).
        /// Step 2: inactive until class chosen, active until task chosen, then selected.
        /// Step 3: inactive until task chosen, then active (currently marking).
        /// A step is never shown as "done" with a checkmark - only as selected (highlighted)
        /// or active (needs action now), keeping the state clear and non-misleading.
        /// Called directly from the markup with <%= %>, which evaluates during Render,
        /// after Page_PreRender, so it always reads the current SelectedClassID/
        /// SelectedTaskID and was not affected by the page lifecycle bug fixed above.
        /// </summary>
        /// <param name="stepNumber">The step number to get the CSS class for (1, 2, or 3).</param>
        /// <returns>The CSS class ("active", "selected", or "step") for the given step.</returns>
        public string GetStepClass(int stepNumber)
        {
            if (stepNumber == 1)
            {
                // Always show step 1 as selected once a class has been picked,
                // never as done, to make it easy to switch classes
                return SelectedClassID > 0 ? "selected" : "active";
            }
            if (stepNumber == 2)
            {
                if (SelectedClassID == 0) return "step"; // inactive, waiting for step 1
                return SelectedTaskID > 0 ? "selected" : "active";
            }
            if (stepNumber == 3)
            {
                // Step 3 stays active while marking is in progress
                return SelectedTaskID > 0 ? "active" : "step";
            }
            return "step";
        }

        /// <summary>
        /// Logs the teacher out and returns to the login page.
        /// </summary>
        /// <param name="sender">The logout control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        /// <summary>
        /// Builds a one or two letter initials string from the logged-in user's full name,
        /// for display in the sidebar avatar.
        /// </summary>
        /// <returns>The user's initials in upper case, or "?" if no name is available.</returns>
        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        /// <summary>
        /// Builds a one or two letter initials string for a student's avatar in the
        /// completion list.
        /// </summary>
        /// <param name="nameObj">The FullName value from the data source.</param>
        /// <returns>The student's initials in upper case, or "?" if no name is available.</returns>
        protected string GetStudentInitials(object nameObj)
        {
            string name = nameObj != null ? nameObj.ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        /// <summary>
        /// Returns an HTML badge for a task's priority level.
        /// </summary>
        /// <param name="priorityObj">The PriorityLevel value from the data source (1, 2, or 3).</param>
        /// <returns>An HTML span with the appropriate badge class and label.</returns>
        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        /// <summary>
        /// Returns an HTML badge showing a student's completion status for the selected task.
        /// </summary>
        /// <param name="markedCompleteObj">The MarkedComplete value from the data source.</param>
        /// <returns>An HTML span styled as complete (green check) or pending (muted).</returns>
        protected string GetStatusBadge(object markedCompleteObj)
        {
            return Convert.ToBoolean(markedCompleteObj)
                ? "<span class=\"badge\" style=\"color:var(--green);background:var(--green-bg);border-color:var(--green-border);\"><i class='ti ti-check'></i> Complete</span>"
                : "<span class=\"badge\" style=\"color:var(--text-muted);background:var(--bg);border-color:var(--border);\">Pending</span>";
        }
    }
}
